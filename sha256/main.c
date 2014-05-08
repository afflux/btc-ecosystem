#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>

#include "sha256.h"

/*
 * those are the standard FIPS-180-2 test vectors
 */
static const char *msg[] = {
		"abc",
		"abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq",
};

static const char *val[] = {
		"ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
		"248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1",
		"cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0"
};

uint8_t buf[4096];

int main(int argc, char *argv[]) {
	FILE *f;
	sha256_context ctx;
	int i, j, n;
	char output[65];
	uint8_t sha256sum[32];

	if (argc < 2) {
		printf("SHA-256 Validation Tests:\n");

		for (i = 0; i < 3; ++i) {
			printf("Test %d ", i + 1);

			sha256_init(&ctx);

			if (i < 2) {
				sha256_update(&ctx, (uint8_t *) msg[i], strlen(msg[i]));
			} else {
				memset(buf, 'a', 1000);
				for (j = 0; j < 1000; ++j)
					sha256_update(&ctx, (uint8_t *) buf, 1000);
			}

			sha256_finish(&ctx, sha256sum);

			for (j = 0; j < 32; j++) {
				sprintf(output + j * 2, "%02x", sha256sum[j]);
			}

			if (memcmp(output, val[i], 64)) {
				printf("failed!\n");
				return 1;
			}

			printf("passed.\n");
		}
	} else {
		for (i = 1; i < argc; ++i) {
			f = fopen(argv[i], "rb");
			if (!f) {
				perror("fopen");
				return 1;
			}

			sha256_init(&ctx);

			while ((n = fread(buf, 1, sizeof(buf), f)) > 0)
				sha256_update(&ctx, buf, n);

			fclose(f);

			sha256_finish(&ctx, sha256sum);

			for (j = 0; j < 32; ++j)
				printf("%02x", sha256sum[j]);

			printf("  %s\n", argv[i]);
		}
	}
	return 0;
}
