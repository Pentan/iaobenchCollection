//
//  IAOaobenchFloatBLAS.m
//  iaobenchCollection
//
//  Created by Satoru NAKAJIMA on 2012/10/07.
//  Copyright (c) 2012年 Satoru NAKAJIMA. All rights reserved.
//

#import "IAOaobenchFloatBLAS.h"

// original codes
#include "aof_blas.c"


// Objective-C interface
@implementation IAOaobenchFloatBLAS

- (NSString*)name {
	return @"aobench_f Accelerate's BLAS";
}

- (NSString*)information {
	return @"use Accelerate framework's BLAS.";
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
