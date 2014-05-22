/* vim:et:sts=2:sw=2:ts=2:tw=78
 */
#define _GNU_SOURCE
#include "miner.h"
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>

#include <sha256_accel.h>
#define CLOCK_FREQ 110u
#define TEMPFILE "/sys/devices/amba.0/f8007100.ps7-xadc/temp"

struct edc_info {
  int fd;
  int tempfd;
  pthread_mutex_t fd_lock;
};

static void edc_drv_detect(bool hotplug) {
  struct stat chr_stat;
  char buf[128], *strerr;
  int errsv;

  struct cgpu_info *info;
  struct edc_info* edcinfo;

  info = calloc(1, sizeof(*info));
  edcinfo = (struct edc_info*) (
      info->device_data = calloc(1, sizeof(struct edc_info))
      );

  if (unlikely(NULL == info))
    quithere(1, "Failed to calloc edccgpu");

  if (unlikely(-1 == stat(SHA256_ACCEL_DEVICE, &chr_stat))) {
    errsv = errno;
    strerr = strerror_r(errsv, strerr, sizeof(buf));

    applog(LOG_ERR, "failed to stat %s: (%d) %s", SHA256_ACCEL_DEVICE, errsv, strerr);
    goto cleanup;
  }

  if (unlikely( !S_ISCHR(chr_stat.st_mode) )) {
    applog(LOG_ERR, "not a character device: " SHA256_ACCEL_DEVICE);
    goto cleanup;
  }

  info->drv = &edc_drv;
  info->deven = DEV_ENABLED;
  info->threads = 1;
  info->device_path = SHA256_ACCEL_DEVICE;

  mutex_init(&edcinfo->fd_lock);
  edcinfo->fd = -1;

  edcinfo->tempfd = open(TEMPFILE, O_RDONLY);

  if (unlikely(!add_cgpu(info)))
    goto cleanup;

  return;

cleanup:
  free(info);
}

#define LOG_ERRNO(fmt, args...) { \
  errsv = errno; \
  strerr = strerror_r(errsv, strerr, sizeof(buf)); \
  applog(LOG_ERR, fmt ": (%d) %s", args errsv, strerr); \
}

static void print_hex(const char* data) {
  /* forgive me Lord, for I have sinned */
  applog(LOG_WARNING,
"edc: %02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
data[0x00], data[0x01], data[0x02], data[0x03], data[0x04], data[0x05],
data[0x06], data[0x07], data[0x08], data[0x09], data[0x0a], data[0x0b],
data[0x0c], data[0x0d], data[0x0e], data[0x0f], data[0x10], data[0x11],
data[0x12], data[0x13], data[0x14], data[0x15], data[0x16], data[0x17],
data[0x18], data[0x19], data[0x1a], data[0x1b], data[0x1c], data[0x1d],
data[0x1e], data[0x1f]);
}

int64_t edc_scanhash(struct thr_info* thr, struct work* work,
    int64_t max_nonce) {
  uint32_t status = 0u, nonce_current;
  char buf[128], *strerr;
  int errsv, i, ret, fd;
  unsigned char b;
  int64_t hashes = -1;
  fd_set set;
  struct timeval timeout;
  struct sha256_accel_msg_s msg;
  struct edc_info* edcinfo = (struct edc_info*) thr->cgpu->device_data;

  /*
   * 
   * NOTE: occasionally check thr->work_restart in blocking loops! we are supposed to
   * abort if it is set.
   * 
   */


  memset(work->device_target, '\0', 32);
  for (i = 31; i >= 0; --i)
    for (b = 1; b > 0; b <<= 1)
      if (work->target[i] & b)
        goto found;

found:
  for ( ; i < 32; ++i) { 
    for ( ; b > 0; b >>= 1)
      work->device_target[i] |= b;
    b = 0x80;
  }

  print_hex(work->device_target);

  mutex_lock(&edcinfo->fd_lock);
  fd = open(thr->cgpu->device_path, O_RDWR);
  edcinfo->fd = fd;
  if (unlikely(-1 == fd)) {
    mutex_unlock(&edcinfo->fd_lock);
    LOG_ERRNO("edc: failed to open %s", thr->cgpu->device_path, );
    return -1;
  }
  mutex_unlock(&edcinfo->fd_lock);

  /* set clock speed */
  if (unlikely(-1 == ioctl(fd, SHA256_ACCEL_SET_CLOCK_SPEED, CLOCK_FREQ))) {
    LOG_ERRNO("edc: failed to send frequency=%u", CLOCK_FREQ, );
    goto close;
  }

  /* reset device */
  if (unlikely(-1 == ioctl(fd, SHA256_ACCEL_RESET))) {
    LOG_ERRNO("edc: failed to send reset command");
    goto close;
  }

  /* waiting for device to get ready */
  do {
    if (unlikely(-1 == ioctl(fd, SHA256_ACCEL_GET_STATUS, &status))) {
      LOG_ERRNO("edc: failed to retrieve hw status");
      goto close;
    }
    // TODO maybe add a timeout here?
  } while(status != 0x1u && !thr->work_restart);

  if (unlikely(status != 0x1u)) {
    applog(LOG_ERR, "edc: got restarted while working for reset!!");
    goto close;
  }

  if (unlikely(-1 == ioctl(fd, SHA256_ACCEL_SET_STATE_IN, work->midstate))) {
    LOG_ERRNO("edc: failed to set midstate");
    goto close;
  }

  if (unlikely(-1 == ioctl(fd, SHA256_ACCEL_SET_PREFIX, work->data + 64))) {
    LOG_ERRNO("edc: failed to set prefix");
    goto close;
  }


  if (unlikely(-1 == ioctl(fd, SHA256_ACCEL_SET_DIFFICULTY_MASK, work->device_target))) {
    LOG_ERRNO("edc: failed to set difficulty mask");
    goto close;
  }

  if (unlikely(-1 == ioctl(fd, SHA256_ACCEL_START))) {
    LOG_ERRNO("edc: failed to send start command");
    goto close;
  }


  while (1) {
    FD_ZERO(&set);
    FD_SET(fd, &set);
    timeout.tv_sec = 0;
    timeout.tv_usec = 200000;

    ret = select(fd + 1, &set, NULL, NULL, &timeout);

    if (likely(ret == 0)) {
      /* timeout */
      if (unlikely(thr->work_restart)) {
        applog(LOG_ERR, "edc: dropping work\n");
        break;
      }

      if (unlikely(-1 == ioctl(fd, SHA256_ACCEL_GET_STATUS, &status))) {
        LOG_ERRNO("edc: failed to retrieve hw status");
        break;
      }

      if (unlikely((status & 0x2) == 0)) {
        applog(LOG_ERR, "edc: hardware stopped for some reason!");
        break;
      }

      /* we are still alive! please don't kill us! we'll do everything! :-( */
      cgtime(&thr->last);
      if (edcinfo->tempfd != -1) {
        ret = read(edcinfo->tempfd, buf, sizeof(msg));
        if (ret > 0) {
          sscanf(buf, "%lf", &thr->cgpu->temp);
        }
      }

    } else if (unlikely(ret == -1)) {
      LOG_ERRNO("edc: failed to select");
      break;
    } else {
      ret = read(fd, (char*) &msg, sizeof(msg));
      if (sizeof(msg) != ret) {
        applog(LOG_ERR, "edc: short read");
        break;
      }

      if (msg.status == 0x10) {
        applog(LOG_ERR, "GOT A RESULT w00t");
        submit_nonce(thr, work, msg.nonce_candidate);
      } else
        applog(LOG_ERR, "no result in this nonce domain :-(");
      break;
    }
  }

  if (unlikely(-1 == ioctl(fd, SHA256_ACCEL_GET_NONCE_CURRENT, &nonce_current))) {
    LOG_ERRNO("edc: failed to get current nonce");
    goto close;
  }

  hashes = (int64_t) nonce_current;

close:
  mutex_lock(&edcinfo->fd_lock);
  close(fd);
  edcinfo->fd = -1;
  mutex_unlock(&edcinfo->fd_lock);
  applog(LOG_ERR, "edc: hashed %lld hashes", hashes);
  return hashes;
}

static void edc_get_statline_before(char* outbuf, size_t bufsiz,
    struct cgpu_info* cgpu) {
  struct edc_info* edcinfo = (struct edc_info*) cgpu->device_data;
  uint32_t status, nonce;
  char buf[128], *strerr;
  int errsv;

  mutex_lock(&edcinfo->fd_lock);
  if (edcinfo->fd == -1) {
    tailsprintf(outbuf, bufsiz, "edc: closed");
    goto close;
  }

  if (unlikely(-1 == ioctl(edcinfo->fd, SHA256_ACCEL_GET_STATUS, &status))) {
    LOG_ERRNO("edc: failed to retrieve hw status");
    goto close;
  }

  if (unlikely(-1 == ioctl(edcinfo->fd, SHA256_ACCEL_GET_NONCE_CURRENT, &nonce))) {
    LOG_ERRNO("edc: failed to get current nonce");
    goto close;
  }

  tailsprintf(outbuf, bufsiz,
              "edc: temperature=% 3.0f status=%08x curnonce=%08x", cgpu->temp,
              status, nonce);

close:
  mutex_unlock(&edcinfo->fd_lock);
}


struct device_drv edc_drv = {
  .drv_id = DRIVER_edc,
  .dname = "edcKernel",
  .name = "edc",
  .drv_detect = edc_drv_detect,
  .scanhash = edc_scanhash,
  .get_statline_before = edc_get_statline_before,
};
