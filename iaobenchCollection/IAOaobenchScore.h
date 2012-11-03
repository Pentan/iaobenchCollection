//
//  IAOaobenchScore.h
//  iaobenchCollection
//
//  Created by Satoru NAKAJIMA on 2012/10/07.
//  Copyright (c) 2012年 Satoru NAKAJIMA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IAOaobenchScore : NSObject
{
	UIImage *thumbnailImage;
	NSDate *date;
	NSString *dateString;
}

@property (nonatomic, readwrite) NSTimeInterval time;
@property (strong, nonatomic) UIImage *resultImage;

- (id)initWithTime:(NSTimeInterval)initTime image:(UIImage*)initImage;

- (NSString*)score;
- (NSString*)detail;
- (UIImage*)thumbnail;
- (NSString*)shareText;

@end
