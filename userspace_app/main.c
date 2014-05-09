#include <stdlib.h>
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <openssl/sha.h>

#include <sha256_accel.h>

struct btc_s {
	__u32 Version;
	__u8 hashPrevBlock[8];
	__u8 hashMerkleRoot[8];
	__u32 Time;
	__u32 Bits;
	__u32 Nonce;
}__attribute__((packed));

static inline void sha256(const char *msg, const size_t len, unsigned char hash[SHA256_DIGEST_LENGTH]) {
	SHA256_CTX ctx;
	SHA256_Init(&ctx);
	SHA256_Update(&ctx, msg, len);
	SHA256_Final(hash, &ctx);
}

int main(int argc, char *argv[]) {
	int fd = open(SHA256_ACCEL_DEVICE, O_RDWR);
	if (fd == -1) {
		perror("failed to open sha256 accelerator device " SHA256_ACCEL_DEVICE);
		exit(EXIT_FAILURE);
	}

	__u8 num_leading_zeros = 4;
	const char prefix[] = "<Das ist das Haus vom Nikolaus.>";

	ioctl(fd, SHA256_ACCEL_SET_STATE_IN, "todo");
	ioctl(fd, SHA256_ACCEL_SET_PREFIX, prefix);
	ioctl(fd, SHA256_ACCEL_SET_NUM_LEADING_ZEROS, num_leading_zeros);

	ioctl(fd, SHA256_ACCEL_START);

	//ret = read(fd, buf, sizeof(buf) - 1);

	return EXIT_SUCCESS;
}
