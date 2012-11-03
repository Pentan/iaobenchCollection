//
//  IAOaobenchFloatGLKMath.m
//  iaobenchCollection
//
//  Created by Satoru NAKAJIMA on 2012/10/07.
//  Copyright (c) 2012年 Satoru NAKAJIMA. All rights reserved.
//

#import "IAOaobenchFloatGLKMath.h"

// original codes
#include "aof_GLK.c"


// Objective-C interface
@implementation IAOaobenchFloatGLKMath

- (NSString*)name {
	return @"aobench_f GLKit's GLKMath";
}

- (NSString*)information {
	return @"use GLKits framework's GLKMath.";
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
