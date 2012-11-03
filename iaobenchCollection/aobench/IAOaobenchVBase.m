//
//  IAOaobenchVBase.m
//  iaobenchCollection
//
//  Created by Satoru NAKAJIMA on 2012/10/07.
//  Copyright (c) 2012年 Satoru NAKAJIMA. All rights reserved.
//

#import "IAOaobenchVBase.h"

// original codes
#include "ao_vbase.c"


// Objective-C interface
@implementation IAOaobenchVBase

- (NSString*)name {
	return @"aobench Vector Op base";
}

- (NSString*)information {
	return @"separates vector calculation functions.";
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
