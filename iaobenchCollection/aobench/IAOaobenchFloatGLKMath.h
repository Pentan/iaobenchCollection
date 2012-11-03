//
//  IAOaobenchFloatGLKMath.h
//  iaobenchCollection
//
//  Created by Satoru NAKAJIMA on 2012/10/07.
//  Copyright (c) 2012年 Satoru NAKAJIMA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IAORenderer.h"

@interface IAOaobenchFloatGLKMath : NSObject <IAORenderer>
- (NSString*)name;
- (NSString*)information;
- (IAORendererType)rendererType;

- (NSTimeInterval)render:(unsigned char*)buffer width:(int)w height:(int)h;
@end
