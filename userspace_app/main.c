#include <stdlib.h>
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <sys/select.h>

#include <sha256_accel.h>

struct btc_s {
	__u32 Version;
	__u8 hashPrevBlock[8];
	__u8 hashMerkleRoot[8];
	__u32 Time;
	__u32 Bits;
	__u32 Nonce;
}__attribute__((packed));

int main(int argc, char *argv[]) {
	fd_set set;
	struct timeval timeout;
	int ret, fd = open(SHA256_ACCEL_DEVICE, O_RDWR);
	struct sha256_accel_msg_s msg;
	__u32 nonce_current, status = 0u;

	if (fd == -1) {
		perror("failed to open sha256 accelerator device " SHA256_ACCEL_DEVICE);
		exit(EXIT_FAILURE);
	}

	ioctl(fd, SHA256_ACCEL_RESET);

	do {
		ret = ioctl(fd, SHA256_ACCEL_GET_STATUS, &status);
		if (ret)
			perror("ioctl GET_STATUS");
		printf("status: %08x\n", status);
	} while (status != 0x1);

	ioctl(fd, SHA256_ACCEL_SET_STATE_IN, "\x95\x24\xc5\x93\x05\xc5\x67\x13\x16\xe6\x69\xba\x2d\x28\x10\xa0\x07\xe8\x6e\x37\x2f\x56\xa9\xda\xcd\x5b\xce\x69\x7a\x78\xda\x2d");
	ioctl(fd, SHA256_ACCEL_SET_PREFIX, "\xf1\xfc\x12\x2b\xc7\xf5\xd7\x4d\xf2\xb9\x44\x1a");
	ioctl(fd, SHA256_ACCEL_SET_NUM_LEADING_ZEROS, (__u8) 24);

	ioctl(fd, SHA256_ACCEL_START);

	while(1) {
		FD_ZERO(&set);
		FD_SET(fd, &set);
		timeout.tv_sec = 1;
		timeout.tv_usec = 0;

		ret = select(1, &set, NULL, NULL, &timeout);

		if (ret == 0) {
			ret = ioctl(fd, SHA256_ACCEL_GET_NONCE_CURRENT, &nonce_current);
			if (ret)
				perror("ioctl GET_NONCE_CURRENT");

			ret = ioctl(fd, SHA256_ACCEL_GET_STATUS, &status);
			if (ret)
				perror("ioctl GET_STATUS");

			printf("status: %08x, nonce current: %08x\n", status, nonce_current);
		} else if (ret == -1) {
			perror("select");
		} else {
			ret = read(fd, (char *) &msg, sizeof(msg));
			if (ret == sizeof(msg))
				printf("status: %08x, nonce candidate: %08x\n", msg.status, msg.nonce_candidate);
			else
				fprintf(stderr, "short read\n");
			break;
		}
	}
	close(fd);

	return EXIT_SUCCESS;
}
