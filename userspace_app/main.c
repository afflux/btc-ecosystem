#include <stdlib.h>
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>

#include <sha256_accel.h>

int main(int argc, char *argv[]) {
	fd_set set;
	struct timeval timeout;
	char buf[10 + 1];
	int ret;

	int fd = open(SHA256_ACCEL_DEVICE, O_RDWR);
	if (fd == -1) {
		perror("failed to open sha256 accelerator device " SHA256_ACCEL_DEVICE);
		exit(EXIT_FAILURE);
	}

	ioctl(fd, SHA256_ACCEL_START);

	while (1) {
		FD_ZERO(&set);
		FD_SET(fd, &set);
		timeout.tv_sec = 1;
		timeout.tv_usec = 0;

		if (select(FD_SETSIZE, &set, NULL, NULL, &timeout) < 0) {
			perror("failed to wait for incoming data");
			exit(EXIT_FAILURE);
		}

		if (FD_ISSET(fd, &set)) {
			ret = read(fd, buf, sizeof(buf) - 1);
			buf[ret] = '\0';
			printf("(% 3d) |%s|\n", ret, buf);
			fflush(stdout);
		}
	}

	return EXIT_SUCCESS;
}
