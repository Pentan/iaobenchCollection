//
//  IAOaobenchvDSP.m
//  iaobenchCollection
//
//  Created by Satoru NAKAJIMA on 2012/10/07.
//  Copyright (c) 2012年 Satoru NAKAJIMA. All rights reserved.
//

#import "IAOaobenchvDSP.h"

// original codes
#include "ao_vDSP.c"


// Objective-C interface
@implementation IAOaobenchvDSP

- (NSString*)name {
	return @"aobench Accelerate's vDSP";
}

- (NSString*)information {
	return @"use Accelerate framework's vDSP.";
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
