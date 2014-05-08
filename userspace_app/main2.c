#include <stdlib.h>
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <asm/types.h>

#include <sha256_accel.h>

int main(int argc, char *argv[]) {
	__u32 test;

	int fd = open(SHA256_ACCEL_DEVICE, O_RDWR);
	if (fd == -1) {
		perror("failed to open sha256 accelerator device " SHA256_ACCEL_DEVICE);
		exit(EXIT_FAILURE);
	}

	test = 0x1000;

	ioctl(fd, SHA256_ACCEL_SET_TEST, &test);
	perror("ioctl 1");

	ioctl(fd, SHA256_ACCEL_GET_TEST, &test);
	perror("ioctl 2");

	printf("read test value %08x\n", test);

	ioctl(fd, SHA256_ACCEL_IRQ_START);
	perror("ioctl 3");

	ioctl(fd, SHA256_ACCEL_IRQ_GET, &test);
	perror("ioctl 4");

	printf("read test value %u\n", test);

	return EXIT_SUCCESS;
}
