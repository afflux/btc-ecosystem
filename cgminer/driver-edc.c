/* vim:et:sts=2:sw=2:ts=2:tw=78
 */
#define _GNU_SOURCE
#include "miner.h"
#include <sys/stat.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>

#include <sha256_accel.h>

static void edc_drv_detect(bool hotplug) {
  struct stat chr_stat;
  char buf[128], *strerr;
  int errsv;

  struct cgpu_info *info;

  info = calloc(1, sizeof(*info));
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

  if (unlikely(!add_cgpu(info)))
    goto cleanup;

  return;

cleanup:
  free(info);
}

int64_t edc_scanhash(struct thr_info* thr, struct work* work,
    int64_t max_nonce) {
  
  /*
   *  TODO
   *  start work
   *  wait for result
   *  abort wait if thr->work_restart == TRUE
   *  when nonce candidate was found: submit_nonce(thr, work, nonce)
   */
  /*
   * TODO return -1 on failure, otherwise total number of hashes computed
   *  (even in case of error)
   */
}



struct device_drv edc_drv = {
  .drv_id = DRIVER_edc,
  .dname = "edcKernel",
  .name = "edc",
  .drv_detect = edc_drv_detect,
  .scanhash = edc_scanhash,
};
