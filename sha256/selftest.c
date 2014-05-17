#include <stdio.h>
#include <stdint.h>
#include <string.h>

#include "sha256.h"

/*
 * those are the standard FIPS-180-2 test vectors
 */
static const char *test_vector[] = {
	"abc",
	"abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"
};
static const char *test_solutions[] = {
	"\xba\x78\x16\xbf\x8f\x01\xcf\xea\x41\x41\x40\xde\x5d\xae\x22\x23\xb0\x03\x61\xa3\x96\x17\x7a\x9c\xb4\x10\xff\x61\xf2\x00\x15\xad",
	"\x24\x8d\x6a\x61\xd2\x06\x38\xb8\xe5\xc0\x26\x93\x0c\x3e\x60\x39\xa3\x3c\xe4\x59\x64\xff\x21\x67\xf6\xec\xed\xd4\x19\xdb\x06\xc1",
	"\xcd\xc7\x6e\x5c\x99\x14\xfb\x92\x81\xa1\xc7\xe2\x84\xd7\x3e\x67\xf1\x80\x9a\x48\xa4\x97\x20\x0e\x04\x6d\x39\xcc\xc7\x11\x2c\xd0"
};

/* selftest is automatically executed on startup */
void __attribute__ ((constructor)) testself() {
	sha256_context ctx;
	int i, j;
	uint8_t buf[1000], sha256sum[32];

	for (i = 0; i < 3; ++i) {
		sha256_init(&ctx);

		if (i < 2) {
			sha256_update(&ctx, (uint8_t *) test_vector[i], strlen(test_vector[i]));
		} else {
			memset(buf, 'a', 1000);
			for (j = 0; j < 1000; ++j)
				sha256_update(&ctx, (uint8_t *) buf, 1000);
		}

		sha256_finish(&ctx, sha256sum);

		if (memcmp(sha256sum, test_solutions[i], 32))
			printf("selftest %d failed\n", i + 1);
	}

	printf("selftest passed\n");
}