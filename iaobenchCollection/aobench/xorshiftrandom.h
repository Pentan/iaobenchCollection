#ifndef XORSHIFT_RANDOM_H
#define XORSHIFT_RANDOM_H

// 32bit base 2^128-1 sequence
typedef struct XorShift128_ {
    unsigned int x, y, z, w;
} XorShift128;

void xorshift128Init(XorShift128 *r, unsigned int seed);
unsigned int xorshift128NextU32(XorShift128 *r);
float xorshift128NextFloat(XorShift128 *r);
double xorshift128NextDouble(XorShift128 *r);

// 64bit base 2^64-1 sequence
typedef struct XorShift64_ {
    unsigned long long u;
} XorShift64;

void xorshift64Init(XorShift64 *r, unsigned long long seed);
unsigned long long xorshift64NextU64(XorShift64 *r);
double xorshift64NextDouble(XorShift64 *r);

#endif
