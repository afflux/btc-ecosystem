#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>

#include "sha256.h"

static const unsigned char msg[] =
	"\x01\x00\x00\x00"
	"\x81\xcd\x02\xab\x7e\x56\x9e\x8b\xcd\x93\x17\xe2\xfe\x99\xf2\xde\x44\xd4\x9a\xb2\xb8\x85\x1b\xa4\xa3\x08\x00\x00\x00\x00\x00\x00"
	"\xe3\x20\xb6\xc2\xff\xfc\x8d\x75\x04\x23\xdb\x8b\x1e\xb9\x42\xae\x71\x0e\x95\x1e\xd7\x97\xf7\xaf\xfc\x88\x92\xb0";

uint8_t buf[4096];

int main(int argc, char *argv[]) {
	sha256_context ctx;
	int i;
	uint8_t sha256sum[32];
	sha256_init(&ctx);
	sha256_update(&ctx, (const uint8_t *) msg, 64);
	sha256_nofinish(&ctx, sha256sum);

	for (i = 0; i < 32; ++i)
		printf("%02x", sha256sum[i]);
	printf("\n");

	return 0;
}
