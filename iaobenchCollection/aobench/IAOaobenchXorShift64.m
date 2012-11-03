//
//  IAOaobenchXorShift64.m
//  iaobenchCollection
//
//  Created by Satoru NAKAJIMA on 2012/10/07.
//  Copyright (c) 2012年 Satoru NAKAJIMA. All rights reserved.
//

#import "IAOaobenchXorShift64.h"

// original codes
#include "ao_xorshift64.c"

// Objective-C interface
@implementation IAOaobenchXorShift64

- (NSString*)name {
	return @"aobench 64bit XorShift";
}

- (NSString*)information {
	return @"drand48 to xorshift (64bit,2^64-1 seq).";
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
