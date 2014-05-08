#ifndef _SHA256_H
#define _SHA256_H

#include <stdint.h>

typedef struct {
	uint64_t total;
	uint32_t state[8];
	uint8_t buffer[64];
} sha256_context;

void sha256_init(sha256_context *ctx);
void sha256_update(sha256_context *ctx, uint8_t *input, size_t length);
void sha256_finish(sha256_context *ctx, uint8_t digest[32]);

#endif
