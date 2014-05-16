#include <string.h>
#include <stdint.h>

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
	return (((uint32_t) buffer[position]) << 24) +
			(((uint32_t) buffer[position + 1]) << 16) +
			(((uint32_t) buffer[position + 2]) << 8) +
			((uint32_t) buffer[position + 3]);
}

static void insert_uint32_t(uint8_t *buffer, size_t position, uint32_t value) {
	buffer[position] = (uint8_t)(value >> 24);
	buffer[position + 1] = (uint8_t)(value >> 16);
	buffer[position + 2] = (uint8_t)(value >> 8);
	buffer[position + 3] = (uint8_t) value;
}

static void insert_uint64_t(uint8_t *buffer, size_t position, uint64_t value) {
	buffer[position + 0] = (uint8_t)(value >> 56);
	buffer[position + 1] = (uint8_t)(value >> 48);
	buffer[position + 2] = (uint8_t)(value >> 40);
	buffer[position + 3] = (uint8_t)(value >> 32);
	buffer[position + 4] = (uint8_t)(value >> 24);
	buffer[position + 5] = (uint8_t)(value >> 16);
	buffer[position + 6] = (uint8_t)(value >> 8);
	buffer[position + 7] = (uint8_t) value;
}

void sha256_init(sha256_context *ctx) {
	ctx->total = 0;

	ctx->state[0] = 0x6A09E667;
	ctx->state[1] = 0xBB67AE85;
	ctx->state[2] = 0x3C6EF372;
	ctx->state[3] = 0xA54FF53A;
	ctx->state[4] = 0x510E527F;
	ctx->state[5] = 0x9B05688C;
	ctx->state[6] = 0x1F83D9AB;
	ctx->state[7] = 0x5BE0CD19;
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

	P(A, B, C, D, E, F, G, H, W[ 0], 0x428A2F98);
	P(H, A, B, C, D, E, F, G, W[ 1], 0x71374491);
	P(G, H, A, B, C, D, E, F, W[ 2], 0xB5C0FBCF);
	P(F, G, H, A, B, C, D, E, W[ 3], 0xE9B5DBA5);
	P(E, F, G, H, A, B, C, D, W[ 4], 0x3956C25B);
	P(D, E, F, G, H, A, B, C, W[ 5], 0x59F111F1);
	P(C, D, E, F, G, H, A, B, W[ 6], 0x923F82A4);
	P(B, C, D, E, F, G, H, A, W[ 7], 0xAB1C5ED5);
	P(A, B, C, D, E, F, G, H, W[ 8], 0xD807AA98);
	P(H, A, B, C, D, E, F, G, W[ 9], 0x12835B01);
	P(G, H, A, B, C, D, E, F, W[10], 0x243185BE);
	P(F, G, H, A, B, C, D, E, W[11], 0x550C7DC3);
	P(E, F, G, H, A, B, C, D, W[12], 0x72BE5D74);
	P(D, E, F, G, H, A, B, C, W[13], 0x80DEB1FE);
	P(C, D, E, F, G, H, A, B, W[14], 0x9BDC06A7);
	P(B, C, D, E, F, G, H, A, W[15], 0xC19BF174);
	P(A, B, C, D, E, F, G, H, R(16), 0xE49B69C1);
	P(H, A, B, C, D, E, F, G, R(17), 0xEFBE4786);
	P(G, H, A, B, C, D, E, F, R(18), 0x0FC19DC6);
	P(F, G, H, A, B, C, D, E, R(19), 0x240CA1CC);
	P(E, F, G, H, A, B, C, D, R(20), 0x2DE92C6F);
	P(D, E, F, G, H, A, B, C, R(21), 0x4A7484AA);
	P(C, D, E, F, G, H, A, B, R(22), 0x5CB0A9DC);
	P(B, C, D, E, F, G, H, A, R(23), 0x76F988DA);
	P(A, B, C, D, E, F, G, H, R(24), 0x983E5152);
	P(H, A, B, C, D, E, F, G, R(25), 0xA831C66D);
	P(G, H, A, B, C, D, E, F, R(26), 0xB00327C8);
	P(F, G, H, A, B, C, D, E, R(27), 0xBF597FC7);
	P(E, F, G, H, A, B, C, D, R(28), 0xC6E00BF3);
	P(D, E, F, G, H, A, B, C, R(29), 0xD5A79147);
	P(C, D, E, F, G, H, A, B, R(30), 0x06CA6351);
	P(B, C, D, E, F, G, H, A, R(31), 0x14292967);
	P(A, B, C, D, E, F, G, H, R(32), 0x27B70A85);
	P(H, A, B, C, D, E, F, G, R(33), 0x2E1B2138);
	P(G, H, A, B, C, D, E, F, R(34), 0x4D2C6DFC);
	P(F, G, H, A, B, C, D, E, R(35), 0x53380D13);
	P(E, F, G, H, A, B, C, D, R(36), 0x650A7354);
	P(D, E, F, G, H, A, B, C, R(37), 0x766A0ABB);
	P(C, D, E, F, G, H, A, B, R(38), 0x81C2C92E);
	P(B, C, D, E, F, G, H, A, R(39), 0x92722C85);
	P(A, B, C, D, E, F, G, H, R(40), 0xA2BFE8A1);
	P(H, A, B, C, D, E, F, G, R(41), 0xA81A664B);
	P(G, H, A, B, C, D, E, F, R(42), 0xC24B8B70);
	P(F, G, H, A, B, C, D, E, R(43), 0xC76C51A3);
	P(E, F, G, H, A, B, C, D, R(44), 0xD192E819);
	P(D, E, F, G, H, A, B, C, R(45), 0xD6990624);
	P(C, D, E, F, G, H, A, B, R(46), 0xF40E3585);
	P(B, C, D, E, F, G, H, A, R(47), 0x106AA070);
	P(A, B, C, D, E, F, G, H, R(48), 0x19A4C116);
	P(H, A, B, C, D, E, F, G, R(49), 0x1E376C08);
	P(G, H, A, B, C, D, E, F, R(50), 0x2748774C);
	P(F, G, H, A, B, C, D, E, R(51), 0x34B0BCB5);
	P(E, F, G, H, A, B, C, D, R(52), 0x391C0CB3);
	P(D, E, F, G, H, A, B, C, R(53), 0x4ED8AA4A);
	P(C, D, E, F, G, H, A, B, R(54), 0x5B9CCA4F);
	P(B, C, D, E, F, G, H, A, R(55), 0x682E6FF3);
	P(A, B, C, D, E, F, G, H, R(56), 0x748F82EE);
	P(H, A, B, C, D, E, F, G, R(57), 0x78A5636F);
	P(G, H, A, B, C, D, E, F, R(58), 0x84C87814);
	P(F, G, H, A, B, C, D, E, R(59), 0x8CC70208);
	P(E, F, G, H, A, B, C, D, R(60), 0x90BEFFFA);
	P(D, E, F, G, H, A, B, C, R(61), 0xA4506CEB);
	P(C, D, E, F, G, H, A, B, R(62), 0xBEF9A3F7);
	P(B, C, D, E, F, G, H, A, R(63), 0xC67178F2);

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

	uint8_t padding[64 + 8] = { 0x80 };
	memset(padding + 1, 0, padn - 1);
	insert_uint64_t(padding + padn, 0, ctx->total * 8);

	sha256_update(ctx, padding, padn + 8);
	sha256_nofinish(ctx, digest);
}
