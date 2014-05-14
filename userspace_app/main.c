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

static void debug(int fd) {
	__u32 dbg[SHA256_ACCEL_NUM_DBG_REGS];
	int ret, i;

	ret = ioctl(fd, SHA256_ACCEL_GET_DEBUG, dbg);
	if (ret)
		perror("ioctl DEBUG");
	else
		for (i = 0; i < SHA256_ACCEL_NUM_DBG_REGS; ++i)
			printf("%3u %08x\n", i, dbg[i]);
}

static void debug_step(int fd) {
	int ret;
	debug(fd);

	ret = ioctl(fd, SHA256_ACCEL_STEP);
	if (ret)
		perror("ioctl STEP");
}

static void generate_mask(int number_leading_zeroes, unsigned char mask[32]) {
	int i, nlz = number_leading_zeroes;
	unsigned char b;
	for (i = 31; i >= 0; --i) {
		for (b = 0x80; b > 0 && nlz > 0; b >>= 1, --nlz)
			mask[i] |= b;
	}
}

#define RED "\e[1;31m"
#define GREEN "\e[1;32m"
#define BLUE "\e[1;34m"
#define END "\e[0m"

int main(int argc, char *argv[]) {
	fd_set set;
	struct timeval timeout;
	int ret, fd = open(SHA256_ACCEL_DEVICE, O_RDWR);
	struct sha256_accel_msg_s msg;
	__u32 nonce_current, status = 0u;
	unsigned char mask[32] = {0};

	if (argc != 2) {
		fprintf(stderr, RED "usage: runtest <nlz>" END "\n");
		return 1;
	}

	generate_mask(atoi(argv[1]), mask);

	if (fd == -1) {
		perror(RED "failed to open sha256 accelerator device " SHA256_ACCEL_DEVICE END);
		exit(EXIT_FAILURE);
	}

	//ioctl(fd, SHA256_ACCEL_SET_CONTROL, 0x100);

	printf("\n" GREEN "[+] resetting" END "\n");
	ioctl(fd, SHA256_ACCEL_RESET);
	debug_step(fd);

	printf("\n" GREEN "[+] waiting for reset" END "\n");
	do {
		ret = ioctl(fd, SHA256_ACCEL_GET_STATUS, &status);
		if (ret)
			perror(RED "ioctl GET_STATUS" END);
	} while (status != 0x1);

	printf(GREEN "[+] setting parameters" END "\n");

	//ioctl(fd, SHA256_ACCEL_SET_STATE_IN, "\x95\x24\xc5\x93 \x05\xc5\x67\x13 \x16\xe6\x69\xba \x2d\x28\x10\xa0 \x07\xe8\x6e\x37 \x2f\x56\xa9\xda \xcd\x5b\xce\x69 \x7a\x78\xda\x2d");
	//ioctl(fd, SHA256_ACCEL_SET_PREFIX, "\xf1\xfc\x12\x2b\xc7\xf5\xd7\x4d\xf2\xb9\x44\x1a");
	ioctl(fd, SHA256_ACCEL_SET_STATE_IN, "\x93\xc5\x24\x95\x13\x67\xc5\x05\xba\x69\xe6\x16\xa0\x10\x28\x2d\x37\x6e\xe8\x07\xda\xa9\x56\x2f\x69\xce\x5b\xcd\x2d\xda\x78\x7a");
	ioctl(fd, SHA256_ACCEL_SET_PREFIX, "\x00\x00\x00\x00\x00\x00\x00\x00\xff\xff\xff\xff");
	ioctl(fd, SHA256_ACCEL_SET_DIFFICULTY_MASK, mask);

	printf(GREEN "[+] start" END "\n");
	ioctl(fd, SHA256_ACCEL_START);
	debug_step(fd);

	while(1) {
		FD_ZERO(&set);
		FD_SET(fd, &set);
		timeout.tv_sec = 0;
		timeout.tv_usec = 50000;

		ret = select(fd + 1, &set, NULL, NULL, &timeout);

		if (ret == 0) {
			debug_step(fd);
			ret = ioctl(fd, SHA256_ACCEL_GET_NONCE_CURRENT, &nonce_current);
			if (ret)
				perror(RED "ioctl GET_NONCE_CURRENT" END);

			ret = ioctl(fd, SHA256_ACCEL_GET_STATUS, &status);
			if (ret)
				perror(RED "ioctl GET_STATUS" END);

			printf(BLUE "[.] status: %08x, nonce current: %08x" END "\n", status, nonce_current);
			if (status != 0x2)
				break;
		} else if (ret == -1) {
			perror(RED "select" END);
		} else {
			ret = read(fd, (char *) &msg, sizeof(msg));
			if (ret == sizeof(msg))
				printf(BLUE "[.] status: %08x, nonce candidate: %08x" END "\n", msg.status, msg.nonce_candidate);
			else
				fprintf(stderr, RED "[-] short read" END "\n");
			break;
		}
	}
	debug_step(fd);
	debug_step(fd);
	debug_step(fd);
	close(fd);

	return EXIT_SUCCESS;
}
