#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/fs.h>
#include <linux/init.h>
#include <linux/device.h>
#include <linux/poll.h>
#include <linux/sched.h>
#include <linux/list.h>
#include <linux/slab.h>
#include <linux/interrupt.h>
#include <asm/uaccess.h>
#include <asm/io.h>

#include "include/sha256_accel.h"

#define DBG(type, message, ...) printk(type CLASS_NAME ": " message, ##__VA_ARGS__)

#define SHA256_MSG_INJECT

#define SHA256_ACCEL_ADDR_BASE 0x43c00000
#define SHA256_ACCEL_ADDR_LEN 16
#define SHA256_ACCEL_IRQ 61

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Martin Keßler");
MODULE_DESCRIPTION("make the sha256 accelerator usable in user space programs");
MODULE_SUPPORTED_DEVICE(DEVICE_NAME);

struct sha256_accel_msg_struct {
	struct list_head list;
	char *msg;
};

static int sha256_accel_major;
static struct class* sha256_accel_class = NULL;
static struct device* sha256_accel_device = NULL;

#ifndef SHA256_MSG_INJECT
static DEFINE_MUTEX(sha256_accel_device_mutex);
#endif
static DECLARE_WAIT_QUEUE_HEAD(sha256_accel_queue);
static LIST_HEAD(sha256_accel_msg_list);
static DEFINE_MUTEX(sha256_accel_msg_mutex);
static char *sha256_accel_msg = NULL, *sha256_accel_msg_ptr = NULL;
static __u32 *sha256_accel_mem;

static bool sha256_accel_msg_dequeue(void) {
	struct list_head *ptr;
	struct sha256_accel_msg_struct *msg_ptr;

	if (sha256_accel_msg)
		kfree(sha256_accel_msg);

	if (mutex_lock_interruptible(&sha256_accel_msg_mutex)) {
		/* we failed to acquire the lock, but still have to clear the message pointers */
		sha256_accel_msg_ptr = sha256_accel_msg = NULL;
		return false;
	} else if (list_empty(&sha256_accel_msg_list)) {
		/* there are no messages left in the list, so we just clear the message pointers */
		mutex_unlock(&sha256_accel_msg_mutex);
		sha256_accel_msg_ptr = sha256_accel_msg = NULL;
		return false;
	} else {
		/* there are messages available, so we fetch the next one from the list */
		ptr = sha256_accel_msg_list.next;
		/* remove it from the list */
		list_del(ptr);
		/* give back the lock (we are now not working on the list anymore) */
		mutex_unlock(&sha256_accel_msg_mutex);
		/* retrieve the underlying structure */
		msg_ptr = list_entry(ptr, struct sha256_accel_msg_struct, list);
		/* and set this as the new message */
		sha256_accel_msg_ptr = sha256_accel_msg = msg_ptr->msg;
		/* the linked-list object is not needed anymore */
		kfree(msg_ptr);
		return true;
	}
}

static size_t sha256_accel_msg_avail(void) {
	size_t len;

	if (sha256_accel_msg_ptr && (len = strlen(sha256_accel_msg_ptr)) > 0)
		/* if there is data left in the current message, return that */
		return len;
	else if (sha256_accel_msg_dequeue())
		/* otherwise try to dequeue the next message and do a tail-recursive call */
		return sha256_accel_msg_avail();
	else
		/* if that fails too, we have nothing left that could be processed */
		return 0;
}

static ssize_t sha256_accel_read(struct file *file_ptr, char __user *buffer, size_t length, loff_t *offset) {
	size_t avail, copy, copied;
	ssize_t ret;

	/* if there is no space where we could copy data, we can return immediately */
	if (length == 0)
		return 0;

	/* determine the amount of data that can be read and that would fit in the buffer provided by the user */
	while (true) {
		avail = sha256_accel_msg_avail();

		if (avail > 0)
			/* we have data available, so everything is fine */
			break;
		/* if we have no data to copy, the action depends on the policy of the file */
		else if (file_ptr->f_flags & O_NONBLOCK)
			/* we are asynchroneous, so we can return immediately */
			return -EAGAIN;
		/* we have to wait for incoming data and put ourselves to sleep */
		else if (wait_event_interruptible(sha256_accel_queue, sha256_accel_msg_avail() > 0))
			return -ERESTARTSYS;
	}

	/* if we have more data than the user can accept, we have to limit ourselves */
	copy = (avail >= length) ? length : avail;

	/* copy the data over to the user and derive the amount of data that was copied */
	copied = copy_to_user(buffer, sha256_accel_msg_ptr, copy);
	ret = (copied == 0) ? copy : copied;

	if (ret == avail)
		/* we have copied everything that was available, so this message is done and we can try to dequeue the next one. */
		sha256_accel_msg_dequeue();
	else
		/* advance the pointer on the internal data */
		sha256_accel_msg_ptr += ret;

	return ret;
}

static ssize_t sha256_accel_write(struct file *file_ptr, const char __user *buffer, size_t length, loff_t *offset) {
#ifdef SHA256_MSG_INJECT
	struct sha256_accel_msg_struct *msg_ptr;
	if (mutex_lock_interruptible(&sha256_accel_msg_mutex))
		return -ERESTARTSYS;

	msg_ptr = (struct sha256_accel_msg_struct *) kmalloc(sizeof(*msg_ptr), GFP_KERNEL);
	msg_ptr->msg = (char *) kmalloc(length + 1, GFP_KERNEL);
	memcpy(msg_ptr->msg, buffer, length);
	msg_ptr->msg[length] = '\0';
	list_add_tail(&msg_ptr->list, &sha256_accel_msg_list);

	mutex_unlock(&sha256_accel_msg_mutex);

	wake_up(&sha256_accel_queue);

	return length;
#else
	DBG(KERN_ALERT, "Writing to the device is not supported.\n");
	return -EINVAL;
#endif
}

static unsigned int sha256_accel_poll(struct file *file_ptr, struct poll_table_struct *poll_table) {
	/* register this process on the message queue that could give us new data */
	poll_wait(file_ptr, &sha256_accel_queue, poll_table);

	/* determine if we have anything left that could be passed to the user.
	 * if yes, modify the mask to signal that data is available */
	if (sha256_accel_msg_avail() > 0)
		return POLLIN | POLLRDNORM;
	else
		return 0;
}

static long sha256_accel_ioctl(struct file *file_ptr, unsigned int command, unsigned long param) {
	void *addr;
	__u32 test;

	if (_IOC_TYPE(command) != SHA256_ACCEL_MAGIC)
		return -ENOTTY;

	switch(command) {
	case SHA256_ACCEL_START:
		DBG(KERN_INFO, "Starting accelerated sha256 computation.\n");
		// TODO: implementation
		break;

	case SHA256_ACCEL_STOP:
		DBG(KERN_INFO, "Stopping accelerated sha256 computation.\n");
		// TODO: implementation
		break;

	case SHA256_ACCEL_SET_PREFIX:
		addr = (void __user *) param;

		// TODO: what is the length of the prefix? (100 is just dummy, it's not correct!)
		if (!access_ok(VERIFY_READ, addr, /* TODO replace --> */ 100 /* <-- TODO replace */ ))
			return -EFAULT;

		// TODO: get the prefix from the user and put it into the device

		//copy_from_user(buf, prefix, 100);
		break;

	case SHA256_ACCEL_SET_TEST:
		addr = (void __user *) param;
		if (IS_ERR_VALUE(get_user(test, (__u32 *) addr)))
			 return -EFAULT;

		iowrite32(test, &sha256_accel_mem[0]);

		break;

	case SHA256_ACCEL_GET_TEST:
		addr = (void __user *) param;

		test = ioread32(&sha256_accel_mem[1]);

		if (IS_ERR_VALUE(put_user(test, (__u32 *) addr)))
			 return -EFAULT;

		break;

	case SHA256_ACCEL_IRQ_START:
		iowrite32(0, &sha256_accel_mem[2]);

		break;

	case SHA256_ACCEL_IRQ_GET:
		addr = (void __user *) param;

		test = ioread32(&sha256_accel_mem[2]);

		if (IS_ERR_VALUE(put_user(test, (__u32 *) addr)))
			 return -EFAULT;

		break;

	default:
		return -ENOTTY; /* POSIX standard */
	}

	return 0;
}

static int sha256_accel_open(struct inode *inode, struct file *file_ptr) {
	static int counter = 0;

	struct sha256_accel_msg_struct *msg_ptr;
	struct list_head *cursor;
	int n = 0;

#ifndef SHA256_MSG_INJECT
	if (!mutex_trylock(&sha256_accel_device_mutex))
		return -EBUSY;
#endif

	// TODO: reset the device, do self-test, ...

	msg_ptr = (struct sha256_accel_msg_struct *) kmalloc(sizeof(*msg_ptr), GFP_KERNEL);
	msg_ptr->msg = (char *) kmalloc(50, GFP_KERNEL);
	snprintf(msg_ptr->msg, 50, "You have opened this file %d times.\n", counter++);
	list_add_tail(&msg_ptr->list, &sha256_accel_msg_list);

	list_for_each(cursor, &sha256_accel_msg_list)
		n++;

	msg_ptr = (struct sha256_accel_msg_struct *) kmalloc(sizeof(*msg_ptr), GFP_KERNEL);
	msg_ptr->msg = (char *) kmalloc(50, GFP_KERNEL);
	snprintf(msg_ptr->msg, 50, "Currently there are %d messages.\n", n);
	list_add_tail(&msg_ptr->list, &sha256_accel_msg_list);

	return 0;
}

static int sha256_accel_release(struct inode *inode, struct file *file_ptr) {
#ifndef SHA256_MSG_INJECT
	/* give back the locks */
	mutex_unlock(&sha256_accel_device_mutex);
#endif
	return 0;
}

static const struct file_operations sha256_accel_fops = {
	.owner = THIS_MODULE,
	.read = sha256_accel_read,
	.write = sha256_accel_write,
	.poll = sha256_accel_poll,
	.unlocked_ioctl = sha256_accel_ioctl,
	.open = sha256_accel_open,
	.release = sha256_accel_release
};

static irqreturn_t sha256_accel_irq(int irqid, void *dev_id) {
	DBG(KERN_INFO, "I just got interrupted.\n");

	iowrite32(0, &sha256_accel_mem[3]);

	return IRQ_HANDLED;
}

static int __init sha256_accel_init(void) {
	int retval;
	struct resource *mem;

	sha256_accel_major = register_chrdev(0, DEVICE_NAME, &sha256_accel_fops);
	if (sha256_accel_major < 0) {
		DBG(KERN_ALERT, "Failed with %d to register device '%s'.\n", sha256_accel_major, DEVICE_NAME);
		retval = sha256_accel_major;
		goto error_register;
	}

	DBG(KERN_INFO, "Created %s device with major number %d.\n", DEVICE_NAME, sha256_accel_major);

	sha256_accel_class = class_create(THIS_MODULE, CLASS_NAME);
	if (IS_ERR(sha256_accel_class)) {
		DBG(KERN_ALERT, "Failed to register class '%s'.\n", CLASS_NAME);
		retval = PTR_ERR(sha256_accel_class);
		goto error_class;
	}

	sha256_accel_device = device_create(sha256_accel_class, NULL, MKDEV(sha256_accel_major, 0), NULL, DEVICE_NAME);
	if (IS_ERR(sha256_accel_device)) {
		DBG(KERN_ALERT, "Failed to create device '%s'\n", DEVICE_NAME);
		retval = PTR_ERR(sha256_accel_device);
		goto error_device;
	}


	mem = request_mem_region(SHA256_ACCEL_ADDR_BASE, SHA256_ACCEL_ADDR_LEN, DEVICE_NAME);
	if (mem == NULL) {
		DBG(KERN_ALERT, "Failed to request memory region of length %d starting %p.\n", SHA256_ACCEL_ADDR_LEN, (void *) SHA256_ACCEL_ADDR_BASE);
		retval = -1;
		goto error_mem_region;
	}

	sha256_accel_mem = ioremap_nocache(SHA256_ACCEL_ADDR_BASE, SHA256_ACCEL_ADDR_LEN);

	retval = request_irq(SHA256_ACCEL_IRQ, sha256_accel_irq, 0, DEVICE_NAME, NULL);
	if (IS_ERR_VALUE(retval))
		goto error_irq;

	return 0;

	/* if anything goes wrong, free the allocated ressources in the reverse order */
error_irq:
error_mem_region:
error_device:
	class_unregister(sha256_accel_class);
	class_destroy(sha256_accel_class);
error_class:
	unregister_chrdev(sha256_accel_major, DEVICE_NAME);
error_register:
	return retval;
}

static void __exit sha256_accel_exit(void) {
	struct list_head *ptr;
	struct sha256_accel_msg_struct *msg_ptr;

	/* if any messages are left, free them */
	if (sha256_accel_msg)
		kfree(sha256_accel_msg);

	// TODO: turn off the accelerator (so it doesn't generate interrupts anymore)

	while (!list_empty(&sha256_accel_msg_list)) {
		/* there are messages available, so we fetch the next one from the list */
		ptr = sha256_accel_msg_list.next;
		/* remove it from the list */
		list_del(ptr);

		/* retrieve the underlying structure */
		msg_ptr = list_entry(ptr, struct sha256_accel_msg_struct, list);

		/* the linked-list object as well as the message are not needed anymore */
		kfree(msg_ptr->msg);
		kfree(msg_ptr);
	}

	iounmap(sha256_accel_mem);
	release_mem_region(SHA256_ACCEL_ADDR_BASE, SHA256_ACCEL_ADDR_LEN);

	free_irq(SHA256_ACCEL_IRQ, NULL);

	device_destroy(sha256_accel_class, MKDEV(sha256_accel_major, 0));
	class_unregister(sha256_accel_class);
	class_destroy(sha256_accel_class);
	unregister_chrdev(sha256_accel_major, DEVICE_NAME);
}

module_init(sha256_accel_init);
module_exit(sha256_accel_exit);
