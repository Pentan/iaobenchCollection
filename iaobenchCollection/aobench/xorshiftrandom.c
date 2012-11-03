
#include "xorshiftrandom.h"

// 32bit 2^128-1 sequence
void xorshift128Init(XorShift128 *r, unsigned int seed) {
    r->x = 123456789;
    r->y = 362436069;
    r->z = 521288629;
    r->w = seed;
    
    int i;
    for(i = 0; i < 1000; i++) {
        xorshift128NextU32(r);
    }
}

unsigned int xorshift128NextU32(XorShift128 *r) {
    unsigned int t = r->x ^ (r->x << 11);
    r->x = r->y;
    r->y = r->z;
    r->z = r->w;
    r->w = (r->w ^ (r->w >> 19)) ^ (t ^ (t >> 8));
    return r->w;
}

float xorshift128NextFloat(XorShift128 *r) {
    union {
        unsigned int ul;
        float f;
    } a;
    a.ul = 0x3f800000 | (xorshift128NextU32(r) & 0x007fffff);
    return a.f - 1.0f;
}

double xorshift128NextDouble(XorShift128 *r) {
    return  xorshift128NextU32(r) / 4294967296.0; // 0xffffffff == 4294967295
}

// 64bit 2^64-1 sequence
void xorshift64Init(XorShift64 *r, unsigned long long seed) {
    r->u = seed;
    
    int i;
    for(i = 0; i < 1000; i++) {
        xorshift64NextU64(r);
    }
}

unsigned long long xorshift64NextU64(XorShift64 *r) {
    r->u ^= (r->u << 13);
    r->u ^= (r->u >> 7);
    r->u ^= (r->u << 17);
    return r->u;
}

double xorshift64NextDouble(XorShift64 *r) {
    union {
        unsigned long long ull;
        double d;
    } a;
    a.ull = 0x3ff0000000000000 | (xorshift64NextU64(r) & 0x000fffffffffffff);
    return a.d - 1.0f;
}

/*
// test main
#include <stdio.h>
#include <time.h>

int main(int argc, char **argv) {
    
    int i;
    int genNum = 100;
    // 32
    XorShift128 x128, *rnd128;
    rnd128 = &x128;
    xorshift128Init(rnd128, (unsigned int)time(NULL));
    printf("----- xorshift128NextU32 ------\n");
    for(i = 0; i < genNum; i++) {
        printf("%d %08x\n", i, xorshift128NextU32(rnd128));
    }
    printf("----- xorshift128NextFloat ------\n");
    for(i = 0; i < genNum; i++) {
        printf("%d %f\n", i, xorshift128NextFloat(rnd128));
    }
    printf("----- xorshift128NextDouble ------\n");
    for(i = 0; i < genNum; i++) {
        printf("%d %lf\n", i, xorshift128NextDouble(rnd128));
    }
    // 64
    XorShift64 x64, *rnd64;
    rnd64 = &x64;
    xorshift64Init(rnd64, (unsigned long long)time(NULL));
    printf("----- xorshift64NextU64 ------\n");
    for(i = 0; i < genNum; i++) {
        printf("%d %016llx\n", i, xorshift64NextU64(rnd64));
    }
    printf("----- xorshift64NextDouble ------\n");
    for(i = 0; i < genNum; i++) {
        printf("%d %lf\n", i, xorshift64NextDouble(rnd64));
    }
    
    printf("sizeof(unsigned int)=%lu\n", sizeof(unsigned int));
    printf("sizeof(unsigned long)=%lu\n", sizeof(unsigned long));
    printf("sizeof(unsigned long long)=%lu\n", sizeof(unsigned long long));
    
    return 0;
}
*/