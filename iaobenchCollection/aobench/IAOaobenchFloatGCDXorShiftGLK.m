//
//  IAOaobenchFloatGCDXorShiftGLK.m
//  iaobenchCollection
//
//  Created by Satoru NAKAJIMA on 2012/10/07.
//  Copyright (c) 2012年 Satoru NAKAJIMA. All rights reserved.
//

#import "IAOaobenchFloatGCDXorShiftGLK.h"

// original codes
#include "aof_gcd_xor_GLK.c"


// Objective-C interface
@implementation IAOaobenchFloatGCDXorShiftGLK

- (NSString*)name {
	return @"aobench_f GCD, XorShift and GLKit";
}

- (NSString*)information {
	return @"GCD and blocks own xorshift and GLKMath.";
}

- (IAORendererType)rendererType {
	return kIAORendererTypeOffline;
}

- (NSTimeInterval)render:(unsigned char*)buffer width:(int)w height:(int)h {
	NSTimeInterval startTime = [NSDate timeIntervalSinceReferenceDate];
	
	init_scene();
	render(buffer, 4, w, h, NSUBSAMPLES, TILE_W, TILE_H);

	return [NSDate timeIntervalSinceReferenceDate] - startTime;
}

@end
