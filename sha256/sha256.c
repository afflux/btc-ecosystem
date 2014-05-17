#include <string.h>
#include <stdint.h>
#include <endian.h>

#include "sha256.h"

static inline uint32_t shr(uint32_t x, int n) {
	return x >> n;
}

static inline uint32_t rotr(uint32_t x, int n) {
	return shr(x, n) | (x << (32 - n));
}

static uint32_t S0(uint32_t x) {
	return rotr(x, 7) ^ rotr(x, 18) ^ shr(x, 3);
}

static uint32_t S1(uint32_t x) {
	return rotr(x, 17) ^ rotr(x, 19) ^ shr(x, 10);
}

static uint32_t S2(uint32_t x) {
	return rotr(x, 2) ^ rotr(x, 13) ^ rotr(x, 22);
}

static uint32_t S3(uint32_t x) {
	return rotr(x, 6) ^ rotr(x, 11) ^ rotr(x, 25);
}

static uint32_t F0(uint32_t x, uint32_t y, uint32_t z) {
	return (x & y) | (z & (x | y));
}

static uint32_t F1(uint32_t x, uint32_t y, uint32_t z) {
	return z ^ (x & (y ^ z));
}

static uint32_t extract_uint32_t(const uint8_t *buffer, size_t position) {
	uint32_t value;
	memcpy(&value, &buffer[position], sizeof(value));
	return be32toh(value);
}

static void insert_uint32_t(uint8_t *buffer, size_t position, uint32_t value) {
	uint32_t be = htobe32(value);
	memcpy(&buffer[position], &be, sizeof(be));
}

static void insert_uint64_t(uint8_t *buffer, size_t position, uint64_t value) {
	uint64_t be = htobe64(value);
	memcpy(&buffer[position], &be, sizeof(be));
}

void sha256_init(sha256_context *ctx) {
	ctx->total = 0;

	ctx->state[0] = 0x6a09e667;
	ctx->state[1] = 0xbb67ae85;
	ctx->state[2] = 0x3c6ef372;
	ctx->state[3] = 0xa54ff53a;
	ctx->state[4] = 0x510e527f;
	ctx->state[5] = 0x9b05688c;
	ctx->state[6] = 0x1f83d9ab;
	ctx->state[7] = 0x5be0cd19;
}

static void sha256_process(sha256_context *ctx, const uint8_t data[64]) {
	int i;
	uint32_t temp1, temp2, W[64];
	uint32_t A, B, C, D, E, F, G, H;

	for (i = 0; i < 16; ++i)
		W[i] = extract_uint32_t(data, 4 * i);

#define R(t) (W[t] = S1(W[t -  2]) + W[t -  7] + S0(W[t - 15]) + W[t - 16])
#define P(a, b, c, d, e, f, g, h, x, K) { \
			temp1 = h + S3(e) + F1(e, f, g) + K + x; \
			temp2 = S2(a) + F0(a,b,c); \
			d += temp1; \
			h = temp1 + temp2; \
		}

	A = ctx->state[0];
	B = ctx->state[1];
	C = ctx->state[2];
	D = ctx->state[3];
	E = ctx->state[4];
	F = ctx->state[5];
	G = ctx->state[6];
	H = ctx->state[7];

	P(A, B, C, D, E, F, G, H, W[ 0], 0x428a2f98);
	P(H, A, B, C, D, E, F, G, W[ 1], 0x71374491);
	P(G, H, A, B, C, D, E, F, W[ 2], 0xb5c0fbcf);
	P(F, G, H, A, B, C, D, E, W[ 3], 0xe9b5dba5);
	P(E, F, G, H, A, B, C, D, W[ 4], 0x3956c25b);
	P(D, E, F, G, H, A, B, C, W[ 5], 0x59f111f1);
	P(C, D, E, F, G, H, A, B, W[ 6], 0x923f82a4);
	P(B, C, D, E, F, G, H, A, W[ 7], 0xab1c5ed5);
	P(A, B, C, D, E, F, G, H, W[ 8], 0xd807aa98);
	P(H, A, B, C, D, E, F, G, W[ 9], 0x12835b01);
	P(G, H, A, B, C, D, E, F, W[10], 0x243185be);
	P(F, G, H, A, B, C, D, E, W[11], 0x550c7dc3);
	P(E, F, G, H, A, B, C, D, W[12], 0x72be5d74);
	P(D, E, F, G, H, A, B, C, W[13], 0x80deb1fe);
	P(C, D, E, F, G, H, A, B, W[14], 0x9bdc06a7);
	P(B, C, D, E, F, G, H, A, W[15], 0xc19bf174);
	P(A, B, C, D, E, F, G, H, R(16), 0xe49b69c1);
	P(H, A, B, C, D, E, F, G, R(17), 0xefbe4786);
	P(G, H, A, B, C, D, E, F, R(18), 0x0fc19dc6);
	P(F, G, H, A, B, C, D, E, R(19), 0x240ca1cc);
	P(E, F, G, H, A, B, C, D, R(20), 0x2de92c6f);
	P(D, E, F, G, H, A, B, C, R(21), 0x4a7484aa);
	P(C, D, E, F, G, H, A, B, R(22), 0x5cb0a9dc);
	P(B, C, D, E, F, G, H, A, R(23), 0x76f988da);
	P(A, B, C, D, E, F, G, H, R(24), 0x983e5152);
	P(H, A, B, C, D, E, F, G, R(25), 0xa831c66d);
	P(G, H, A, B, C, D, E, F, R(26), 0xb00327c8);
	P(F, G, H, A, B, C, D, E, R(27), 0xbf597fc7);
	P(E, F, G, H, A, B, C, D, R(28), 0xc6e00bf3);
	P(D, E, F, G, H, A, B, C, R(29), 0xd5a79147);
	P(C, D, E, F, G, H, A, B, R(30), 0x06ca6351);
	P(B, C, D, E, F, G, H, A, R(31), 0x14292967);
	P(A, B, C, D, E, F, G, H, R(32), 0x27b70a85);
	P(H, A, B, C, D, E, F, G, R(33), 0x2e1b2138);
	P(G, H, A, B, C, D, E, F, R(34), 0x4d2c6dfc);
	P(F, G, H, A, B, C, D, E, R(35), 0x53380d13);
	P(E, F, G, H, A, B, C, D, R(36), 0x650a7354);
	P(D, E, F, G, H, A, B, C, R(37), 0x766a0abb);
	P(C, D, E, F, G, H, A, B, R(38), 0x81c2c92e);
	P(B, C, D, E, F, G, H, A, R(39), 0x92722c85);
	P(A, B, C, D, E, F, G, H, R(40), 0xa2bfe8a1);
	P(H, A, B, C, D, E, F, G, R(41), 0xa81a664b);
	P(G, H, A, B, C, D, E, F, R(42), 0xc24b8b70);
	P(F, G, H, A, B, C, D, E, R(43), 0xc76c51a3);
	P(E, F, G, H, A, B, C, D, R(44), 0xd192e819);
	P(D, E, F, G, H, A, B, C, R(45), 0xd6990624);
	P(C, D, E, F, G, H, A, B, R(46), 0xf40e3585);
	P(B, C, D, E, F, G, H, A, R(47), 0x106aa070);
	P(A, B, C, D, E, F, G, H, R(48), 0x19a4c116);
	P(H, A, B, C, D, E, F, G, R(49), 0x1e376c08);
	P(G, H, A, B, C, D, E, F, R(50), 0x2748774c);
	P(F, G, H, A, B, C, D, E, R(51), 0x34b0bcb5);
	P(E, F, G, H, A, B, C, D, R(52), 0x391c0cb3);
	P(D, E, F, G, H, A, B, C, R(53), 0x4ed8aa4a);
	P(C, D, E, F, G, H, A, B, R(54), 0x5b9cca4f);
	P(B, C, D, E, F, G, H, A, R(55), 0x682e6ff3);
	P(A, B, C, D, E, F, G, H, R(56), 0x748f82ee);
	P(H, A, B, C, D, E, F, G, R(57), 0x78a5636f);
	P(G, H, A, B, C, D, E, F, R(58), 0x84c87814);
	P(F, G, H, A, B, C, D, E, R(59), 0x8cc70208);
	P(E, F, G, H, A, B, C, D, R(60), 0x90befffa);
	P(D, E, F, G, H, A, B, C, R(61), 0xa4506ceb);
	P(C, D, E, F, G, H, A, B, R(62), 0xbef9a3f7);
	P(B, C, D, E, F, G, H, A, R(63), 0xc67178f2);

	ctx->state[0] += A;
	ctx->state[1] += B;
	ctx->state[2] += C;
	ctx->state[3] += D;
	ctx->state[4] += E;
	ctx->state[5] += F;
	ctx->state[6] += G;
	ctx->state[7] += H;
}

void sha256_update(sha256_context *ctx, const uint8_t *input, size_t length) {
	size_t left, fill;

	if (!length)
		return;

	left = ctx->total & 0x3F;
	fill = 64 - left;

	ctx->total += length;

	if (left && length >= fill) {
		memcpy(&ctx->buffer[left], input, fill);
		sha256_process(ctx, ctx->buffer);
		length -= fill;
		input += fill;
		left = 0;
	}

	while (length >= 64) {
		sha256_process(ctx, input);
		length -= 64;
		input += 64;
	}

	if (length)
		memcpy(&ctx->buffer[left], input, length);
}

void sha256_nofinish(sha256_context *ctx, uint8_t digest[32]) {
	int i;
	for (i = 0; i < 8; ++i)
		insert_uint32_t(digest, i * 4, ctx->state[i]);
}

void sha256_finish(sha256_context *ctx, uint8_t digest[32]) {
	size_t last, padn;

	last = ctx->total & 0x3F;
	padn = (last < 56) ? (56 - last) : (120 - last);

	uint8_t padding[padn + 8];

	padding[0] = 0x80;
	memset(padding + 1, 0, padn - 1);
	insert_uint64_t(padding + padn, 0, ctx->total * 8);

	sha256_update(ctx, padding, padn + 8);
	sha256_nofinish(ctx, digest);
}
