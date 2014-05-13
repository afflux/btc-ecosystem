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

#define SHA256_ACCEL_ADDR_BASE 0x43c00000
#define SHA256_ACCEL_ADDR_LEN 68
#define SHA256_ACCEL_IRQ 61

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Martin Keßler");
MODULE_DESCRIPTION("make the sha256 accelerator usable in user space programs");
MODULE_SUPPORTED_DEVICE(DEVICE_NAME);

struct sha256_accel_msg_list_s {
	struct list_head list;
	struct sha256_accel_msg_s payload;
};

static int sha256_accel_major;
static struct class* sha256_accel_class = NULL;
static struct device* sha256_accel_device = NULL;

static DEFINE_MUTEX(sha256_accel_device_mutex);
static DECLARE_WAIT_QUEUE_HEAD(sha256_accel_queue);
static LIST_HEAD(sha256_accel_msg_list);
static DEFINE_MUTEX(sha256_accel_msg_mutex);
static struct sha256_accel_msg_list_s *sha256_accel_msg = NULL;
static __u32 *sha256_accel_mem;

static bool sha256_accel_msg_dequeue(void) {
	struct list_head *ptr;

	if (sha256_accel_msg)
		kfree(sha256_accel_msg);

	if (mutex_lock_interruptible(&sha256_accel_msg_mutex)) {
		/* we failed to acquire the lock, but still have to clear the message pointers */
		sha256_accel_msg = NULL;
		return false;
	} else if (list_empty(&sha256_accel_msg_list)) {
		/* there are no messages left in the list, so we just clear the message pointers */
		mutex_unlock(&sha256_accel_msg_mutex);
		sha256_accel_msg = NULL;
		return false;
	} else {
		/* there are messages available, so we fetch the next one from the list */
		ptr = sha256_accel_msg_list.next;
		/* remove it from the list */
		list_del(ptr);
		/* give back the lock (we are now not working on the list anymore) */
		mutex_unlock(&sha256_accel_msg_mutex);
		/* retrieve the underlying structure */
		sha256_accel_msg = list_entry(ptr, struct sha256_accel_msg_list_s, list);
		return true;
	}
}

static size_t sha256_accel_msg_avail(void) {
	if (sha256_accel_msg)
		/* if there is data in the current message, return that */
		return sizeof(*sha256_accel_msg);
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
	copied = copy_to_user(buffer, sha256_accel_msg, copy);
	ret = (copied == 0) ? copy : copied;

	/* we have copied data, so this message is done and we can try to dequeue the next one. */
	sha256_accel_msg_dequeue();

	return ret;
}

static ssize_t sha256_accel_write(struct file *file_ptr, const char __user *buffer, size_t length, loff_t *offset) {
	DBG(KERN_ALERT, "Writing to the device is not supported.\n");
	return -EINVAL;
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
	static const unsigned n = 20;
	void *addr;
	const void *caddr;
	unsigned char buf[4*n];
	__u32 val;

	if (_IOC_TYPE(command) != SHA256_ACCEL_MAGIC)
		return -ENOTTY;

	switch(command) {
	case SHA256_ACCEL_RESET:
		iowrite32(0x1, &sha256_accel_mem[15]);
		break;

	case SHA256_ACCEL_START:
		iowrite32(0x2, &sha256_accel_mem[15]);
		break;

	case SHA256_ACCEL_SET_STATE_IN:
		caddr = (const void __user *) param;

		if (!access_ok(VERIFY_READ, caddr, 32))
			return -EFAULT;

		copy_from_user(buf, caddr, 32);
		memcpy_toio(&sha256_accel_mem[0], buf, 32);
		break;

	case SHA256_ACCEL_SET_PREFIX:
		caddr = (const void __user *) param;

		if (!access_ok(VERIFY_READ, caddr, 12))
			return -EFAULT;

		copy_from_user(buf, caddr, 12);
		memcpy_toio(&sha256_accel_mem[8], buf, 12);
		break;

	case SHA256_ACCEL_SET_NUM_LEADING_ZEROS:
		iowrite8((const __u8) param, &sha256_accel_mem[11]);
		break;

	case SHA256_ACCEL_SET_CONTROL:
		iowrite32((const __u32) param, &sha256_accel_mem[15]);
		break;

	case SHA256_ACCEL_GET_NONCE_CURRENT:
		addr = (void __user *) param;
		val = ioread32(&sha256_accel_mem[13]);

		if (IS_ERR_VALUE(put_user(val, (__u32 *) addr)))
			 return -EFAULT;

		break;

	case SHA256_ACCEL_GET_STATUS:
		addr = (void __user *) param;
		val = ioread32(&sha256_accel_mem[14]);

		if (IS_ERR_VALUE(put_user(val, (__u32 *) addr)))
			 return -EFAULT;

		break;

	case SHA256_ACCEL_DEBUG:
		addr = (void __user *) param;

		iowrite32(0x0, &sha256_accel_mem[16]);

		if (!access_ok(VERIFY_WRITE, addr, 4*n))
			return -EFAULT;

		memcpy_toio(buf, &sha256_accel_mem[0], 4*n);
		copy_to_user(addr, buf, 4*n);

		iowrite32(0x1, &sha256_accel_mem[16]);

		break;

	default:
		return -ENOTTY; /* POSIX standard */
	}

	return 0;
}

static int sha256_accel_open(struct inode *inode, struct file *file_ptr) {
	/* try to acquire the lock on the device. If we fail to do so, someone else has the device open. */
	if (!mutex_trylock(&sha256_accel_device_mutex))
		return -EBUSY;

	return 0;
}

static int sha256_accel_release(struct inode *inode, struct file *file_ptr) {
	/* give back the lock */
	mutex_unlock(&sha256_accel_device_mutex);
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
	struct sha256_accel_msg_list_s *msg;

	DBG(KERN_INFO, "I just got interrupted.\n");

	msg = (struct sha256_accel_msg_list_s *) kmalloc(sizeof(*msg), GFP_KERNEL);
	msg->payload.status = ioread32(&sha256_accel_mem[14]);
	msg->payload.nonce_candidate = ioread32(&sha256_accel_mem[12]);

	iowrite32(0x1, &sha256_accel_mem[16]);

	DBG(KERN_INFO, "status=%08x nc=%08x\n", msg->payload.status, msg->payload.nonce_candidate);

	mutex_lock(&sha256_accel_msg_mutex);
	list_add_tail(&msg->list, &sha256_accel_msg_list);
	mutex_unlock(&sha256_accel_msg_mutex);

	wake_up(&sha256_accel_queue);
	DBG(KERN_INFO, "cya l8er.\n");

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
	struct sha256_accel_msg_list_s *msg_ptr;

	/* if any messages are left, free them */
	if (sha256_accel_msg)
		kfree(sha256_accel_msg);

	// turn off the accelerator (so it doesn't generate interrupts anymore
	iowrite32(0x1, &sha256_accel_mem[15]);

	mutex_lock(&sha256_accel_msg_mutex);
	while (!list_empty(&sha256_accel_msg_list)) {
		/* there are messages available, so we fetch the next one from the list */
		ptr = sha256_accel_msg_list.next;
		/* remove it from the list */
		list_del(ptr);

		/* retrieve the underlying structure */
		msg_ptr = list_entry(ptr, struct sha256_accel_msg_list_s, list);

		/* the linked-list object is not needed anymore */
		kfree(msg_ptr);
	}

	iounmap(sha256_accel_mem);
	release_mem_region(SHA256_ACCEL_ADDR_BASE, SHA256_ACCEL_ADDR_LEN);

	free_irq(SHA256_ACCEL_IRQ, NULL);
	mutex_unlock(&sha256_accel_msg_mutex);


	device_destroy(sha256_accel_class, MKDEV(sha256_accel_major, 0));
	class_unregister(sha256_accel_class);
	class_destroy(sha256_accel_class);
	unregister_chrdev(sha256_accel_major, DEVICE_NAME);
}

module_init(sha256_accel_init);
module_exit(sha256_accel_exit);
