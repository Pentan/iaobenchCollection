//
//  SilentPushSegue.m
//  iaobenchCollection
//
//  Created by Satoru NAKAJIMA on 2012/10/15.
//  Copyright (c) 2012年 Satoru NAKAJIMA. All rights reserved.
//

#import "SilentPushSegue.h"

@implementation SilentPushSegue

- (void)perform {
	[[self.sourceViewController navigationController] pushViewController:self.destinationViewController animated:NO];
}

@end
