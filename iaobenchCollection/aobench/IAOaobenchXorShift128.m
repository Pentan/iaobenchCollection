//
//  IAOaobenchXorShift128.m
//  iaobenchCollection
//
//  Created by Satoru NAKAJIMA on 2012/10/07.
//  Copyright (c) 2012年 Satoru NAKAJIMA. All rights reserved.
//

#import "IAOaobenchXorShift128.h"

// original codes
#include "ao_xorshift128.c"

// Objective-C interface
@implementation IAOaobenchXorShift128

- (NSString*)name {
	return @"aobench 32bit XorShift";
}

- (NSString*)information {
	return @"drand48 to xorshift (32bit,2^128-1 seq).";
}

- (IAORendererType)rendererType {
	return kIAORendererTypeOffline;
}

- (NSTimeInterval)render:(unsigned char*)buffer width:(int)w height:(int)h {
	NSTimeInterval startTime = [NSDate timeIntervalSinceReferenceDate];
	
	init_scene();
	render(buffer, 4, w, h, NSUBSAMPLES);

	return [NSDate timeIntervalSinceReferenceDate] - startTime;
}

@end
