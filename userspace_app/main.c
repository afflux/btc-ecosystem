#include <stdlib.h>
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <sys/select.h>

#include <sha256_accel.h>

#define BOLD_RED "\e[1;31m"
#define BOLD_GREEN "\e[1;32m"
#define BOLD_YELLOW "\e[1;33m"
#define BOLD_BLUE "\e[1;34m"
#define END "\e[0m"

struct btc_s {
	__u32 Version;
	__u8 hashPrevBlock[32];
	__u8 hashMerkleRoot[32];
	__u32 Time;
	__u32 Bits;
	__u32 Nonce;
}__attribute__((packed));

static void generate_mask(int number_leading_zeroes, unsigned char mask[32]) {
	int i, nlz = number_leading_zeroes;
	unsigned char b;
	for (i = 31; i >= 0; --i) {
		for (b = 0x80; b > 0 && nlz > 0; b >>= 1, --nlz)
			mask[i] |= b;
	}
}

int main(int argc, char *argv[]) {
	fd_set set;
	struct timeval timeout;
	int ret, fd = open(SHA256_ACCEL_DEVICE, O_RDWR), i;
	struct sha256_accel_msg_s msg;
	__u32 nonce_current, status = 0u;
	unsigned char mask[32] = {0};

	if (argc != 2) {
		fprintf(stderr, BOLD_RED "usage: runtest <nlz>" END "\n");
		return 1;
	}

	generate_mask(atoi(argv[1]), mask);

	for (i = 0; i < 32; ++i)
		printf("%02x", mask[i]);
	printf("\n");

	if (fd == -1) {
		perror(BOLD_RED "failed to open sha256 accelerator device " SHA256_ACCEL_DEVICE END);
		exit(EXIT_FAILURE);
	}

	printf(BOLD_GREEN "[+] resetting" END "\n");
	ioctl(fd, SHA256_ACCEL_RESET);

	printf(BOLD_GREEN "[+] waiting for reset" END "\n");
	do {
		ret = ioctl(fd, SHA256_ACCEL_GET_STATUS, &status);
		if (ret)
			perror(BOLD_RED "ioctl GET_STATUS" END);
	} while (status != 0x1);

	printf(BOLD_GREEN "[+] setting parameters" END "\n");

	/********************************************************************************************************************************************************************************************
	 *                         reg_addr   ---0---0---0---0   ---1---1---1---1   ---2---2---2---2   ---3---3---3---3   ---4---4---4---4   ---5---5---5---5   ---6---6---6---6   ---7---7---7---7 *
	 *                       byte_index   ---0---1---2---3   ---0---1---2---3   ---0---1---2---3   ---0---1---2---3   ---0---1---2---3   ---0---1---2---3   ---0---1---2---3   ---0---1---2---3 *
	 *                                                                                                                                                                                          *
	 *    sha256_accel_axi_wdata ... to   ---7--15--23--31   ---7--15--23--31   ---7--15--23--31   ---7--15--23--31   ---7--15--23--31   ---7--15--23--31   ---7--15--23--31   ---7--15--23--31 *
	 *                           . from   ---0---8--16--24   ---0---8--16--24   ---0---8--16--24   ---0---8--16--24   ---0---8--16--24   ---0---8--16--24   ---0---8--16--24   ---0---8--16--24 *
	 *                                                                                                                                                                                          *
	 *     sha256_accel_state_in ... to   -255-247-239-231                                                                                                                                      *
	 *                           . from   -248-240-232-224                                                                                                                                      *
	 *                                                                                                                                                                                          *
	 *            sha256_accel_state_in   255-------------------------------------------------------------------------------------------------------------------------------------------------0 *
	 */
	ioctl(fd, SHA256_ACCEL_SET_STATE_IN, "\x95\x24\xc5\x93" "\x05\xc5\x67\x13" "\x16\xe6\x69\xba" "\x2d\x28\x10\xa0" "\x07\xe8\x6e\x37" "\x2f\x56\xa9\xda" "\xcd\x5b\xce\x69" "\x7a\x78\xda\x2d");
	ioctl(fd, SHA256_ACCEL_SET_PREFIX,   "\xf1\xfc\x12\x2b" "\xc7\xf5\xd7\x4d" "\xf2\xb9\x44\x1a");
	ioctl(fd, SHA256_ACCEL_SET_DIFFICULTY_MASK, mask);

	printf(BOLD_GREEN "[+] start" END "\n");
	ioctl(fd, SHA256_ACCEL_START);

	while(1) {
		FD_ZERO(&set);
		FD_SET(fd, &set);
		timeout.tv_sec = 0;
		timeout.tv_usec = 50000;

		ret = select(fd + 1, &set, NULL, NULL, &timeout);

		if (ret == 0) {
			ret = ioctl(fd, SHA256_ACCEL_GET_NONCE_CURRENT, &nonce_current);
			if (ret)
				perror(BOLD_RED "ioctl GET_NONCE_CURRENT" END);

			ret = ioctl(fd, SHA256_ACCEL_GET_STATUS, &status);
			if (ret)
				perror(BOLD_RED "ioctl GET_STATUS" END);

			printf(BOLD_BLUE "[.] status: %08x, nonce current: %08x" END "\n", status, nonce_current);
			if (status != 0x2)
				break;
		} else if (ret == -1) {
			perror(BOLD_RED "select" END);
		} else {
			ret = read(fd, (char *) &msg, sizeof(msg));
			if (ret == sizeof(msg))
				printf(BOLD_BLUE "[.] status: %08x, nonce candidate: %08x" END "\n", msg.status, msg.nonce_candidate);
			else
				fprintf(stderr, BOLD_RED "[-] short read" END "\n");
			break;
		}
	}
	close(fd);

	return EXIT_SUCCESS;
}
