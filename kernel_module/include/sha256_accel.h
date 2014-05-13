#ifndef _SHA256_ACCEL_H
#	define _SHA256_ACCEL_H

#	include <asm/ioctl.h>
#	include <asm/types.h>

#	define CLASS_NAME "sha256"
#	define DEVICE_NAME CLASS_NAME

#	define SHA256_ACCEL_DEVICE "/dev/" DEVICE_NAME

#	define SHA256_ACCEL_MAGIC 'S'

#	define SHA256_ACCEL_RESET _IO(SHA256_ACCEL_MAGIC, 0)
#	define SHA256_ACCEL_START _IO(SHA256_ACCEL_MAGIC, 1)

#	define SHA256_ACCEL_SET_STATE_IN _IOW(SHA256_ACCEL_MAGIC, 2, const unsigned char *)
#	define SHA256_ACCEL_SET_PREFIX _IOW(SHA256_ACCEL_MAGIC, 3, const unsigned char *)
#	define SHA256_ACCEL_SET_NUM_LEADING_ZEROS _IOW(SHA256_ACCEL_MAGIC, 4, const __u8)
#	define SHA256_ACCEL_SET_CONTROL _IOW(SHA256_ACCEL_MAGIC, 5, const __u32)

#	define SHA256_ACCEL_GET_NONCE_CURRENT _IOR(SHA256_ACCEL_MAGIC, 6, __u32 *)
#	define SHA256_ACCEL_GET_STATUS _IOR(SHA256_ACCEL_MAGIC, 7, __u32 *)
#	define SHA256_ACCEL_DEBUG _IOWR(SHA256_ACCEL_MAGIC, 8, __u32 **)

struct sha256_accel_msg_s {
	__u32 status;
	__u32 nonce_candidate;
};

#endif
