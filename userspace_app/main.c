#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <endian.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <sys/select.h>

#include <sha256_accel.h>
#include <sha256.h>

struct btc_s {
	uint32_t Version;
	uint8_t hashPrevBlock[32];
	uint8_t hashMerkleRoot[32];
	uint32_t Time;
	uint32_t Bits;
	uint32_t Nonce;
}__attribute__((packed));

static void generate_test_mask(int number_leading_zeroes, unsigned char mask[32]) {
	int i, nlz = number_leading_zeroes;
	unsigned char b;
	memset(mask, 0, 32);
	for (i = 31; i >= 0; --i) {
		for (b = 0x80; b > 0 && nlz > 0; b >>= 1, --nlz)
			mask[i] |= b;
	}
}

static void print_hex(const void *data, size_t n) {
	size_t i;
	for (i = 0; i < n; ++i)
		printf("%02x", ((const char *) data)[i]);
	printf("\n");
}

int main(int argc, char *argv[]) {
	fd_set set;
	sha256_context ctx;
	struct timeval timeout;
	int ret, fd;
	struct sha256_accel_msg_s msg;
	uint32_t nonce_current, status = 0u;
	unsigned char mask[32], state[32];

	if (argc != 2) {
		fprintf(stderr, "usage: runtest <nlz>\n");
		return -1;
	}

	fd = open(SHA256_ACCEL_DEVICE, O_RDONLY);
	if (fd == -1) {
		perror("failed to open sha256 accelerator device " SHA256_ACCEL_DEVICE);
		exit(EXIT_FAILURE);
	}

	ret = ioctl(fd, SHA256_ACCEL_SET_CLOCK_SPEED, 71);
	if (ret)
		perror("ioctl SHA256_ACCEL_SET_CLOCK_SPEED");

	ret = ioctl(fd, SHA256_ACCEL_GET_STATUS, &status);
	if (ret)
		perror("ioctl GET_STATUS");
	printf("[.] status: %08x\n", status);

	printf("[+] resetting\n");
	ioctl(fd, SHA256_ACCEL_RESET);

	printf("[+] waiting for reset\n");
	do {
		ret = ioctl(fd, SHA256_ACCEL_GET_STATUS, &status);
		if (ret)
			perror("ioctl GET_STATUS");
	} while (status != 0x1);

	struct btc_s sample = {
		.Version = htole32(1),
		.hashPrevBlock = "\x81\xcd\x02\xab\x7e\x56\x9e\x8b\xcd\x93\x17\xe2\xfe\x99\xf2\xde\x44\xd4\x9a\xb2\xb8\x85\x1b\xa4\xa3\x08\x00\x00\x00\x00\x00\x00",
		.hashMerkleRoot = "\xe3\x20\xb6\xc2\xff\xfc\x8d\x75\x04\x23\xdb\x8b\x1e\xb9\x42\xae\x71\x0e\x95\x1e\xd7\x97\xf7\xaf\xfc\x88\x92\xb0\xf1\xfc\x12\x2b",
		.Time = htole32(0x4dd7f5c7),
		.Bits = htole32(0x1a44b9f2),
		.Nonce = 0
	};
	print_hex(&sample, sizeof(sample));

	sha256_init(&ctx);
	sha256_update(&ctx, (uint8_t *) &sample, sizeof(sample) - sizeof(sample.Nonce));
	sha256_nofinish(&ctx, (uint8_t *) state);
	print_hex(&state, 32);

	generate_test_mask(atoi(argv[1]), mask);
	print_hex(mask, 32);

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
	 ********************************************************************************************************************************************************************************************/

	printf("[+] setting parameters\n");
	ioctl(fd, SHA256_ACCEL_SET_STATE_IN, state);
	ioctl(fd, SHA256_ACCEL_SET_PREFIX, &((uint8_t *) &sample)[64]);
	ioctl(fd, SHA256_ACCEL_SET_DIFFICULTY_MASK, mask);

	printf("[+] start\n");
	ioctl(fd, SHA256_ACCEL_START);

	while(1) {
		FD_ZERO(&set);
		FD_SET(fd, &set);
		timeout.tv_sec = 0;
		timeout.tv_usec = 100000;

		ret = select(fd + 1, &set, NULL, NULL, &timeout);

		if (ret == 0) {
			ret = ioctl(fd, SHA256_ACCEL_GET_NONCE_CURRENT, &nonce_current);
			if (ret) {
				perror("ioctl GET_NONCE_CURRENT");
				continue;
			}

			ret = ioctl(fd, SHA256_ACCEL_GET_STATUS, &status);
			if (ret) {
				perror("ioctl GET_STATUS");
				continue;
			}

			printf("[.] status: %08x, nonce current: %08x\n", status, nonce_current);
		} else if (ret == -1) {
			perror("select");
		} else {
			ret = read(fd, (char *) &msg, sizeof(msg));
			if (ret == sizeof(msg)) {
				printf("[.] status: %08x, nonce candidate: %08x\n", msg.status, msg.nonce_candidate);

				sample.Nonce = htobe32(msg.nonce_candidate);
				print_hex(&sample, sizeof(sample));
				sha256_update(&ctx, (uint8_t *) &sample.Nonce, sizeof(sample.Nonce));
				sha256_finish(&ctx, (uint8_t *) state);

				sha256_init(&ctx);
				sha256_update(&ctx, state, sizeof(state));
				sha256_finish(&ctx, state);
				print_hex(&state, 32);
			} else {
				fprintf(stderr, "[-] short read\n");
			}
			break;
		}
	}
	close(fd);

	return EXIT_SUCCESS;
}
