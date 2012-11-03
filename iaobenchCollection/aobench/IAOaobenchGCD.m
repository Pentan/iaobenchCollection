//
//  IAOaobenchGCD.m
//  iaobenchCollection
//
//  Created by Satoru NAKAJIMA on 2012/10/07.
//  Copyright (c) 2012年 Satoru NAKAJIMA. All rights reserved.
//

#import "IAOaobenchGCD.h"

// original codes
#include "ao_gcd.c"


// Objective-C interface
@implementation IAOaobenchGCD

- (NSString*)name {
	return @"aobench with GCD";
}

- (NSString*)information {
	return @"parallelize by GCD.";
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
