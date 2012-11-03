//
//  IAOaobenchScore.m
//  iaobenchCollection
//
//  Created by Satoru NAKAJIMA on 2012/10/07.
//  Copyright (c) 2012年 Satoru NAKAJIMA. All rights reserved.
//

#import <sys/sysctl.h>

#import "IAOaobenchScore.h"

#define kAOScoreThumbnailSize	32.0

static CGFloat cgfmin(CGFloat a, CGFloat b) {
	return (a < b)? a : b;
}

@implementation IAOaobenchScore

- (void)createThumbnailImage {
	CGSize imageSize = self.resultImage.size;
	CGFloat scale = cgfmin(imageSize.width, imageSize.height) / kAOScoreThumbnailSize;
	thumbnailImage = [UIImage imageWithCGImage:[self.resultImage CGImage]
										 scale:scale
								   orientation:UIImageOrientationUp];
}

- (void)setResultImage:(UIImage *)newImage {
	if(self.resultImage == newImage) {
		return;
	}
	self.resultImage = newImage;
	[self createThumbnailImage];
}

- (id)initWithTime:(NSTimeInterval)initTime image:(UIImage*)initImage {
	if(self = [super init]) {
		_time = initTime;
		_resultImage = initImage;
		[self createThumbnailImage];
		
		date = [NSDate date];
		NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
		[formatter setDateStyle:NSDateFormatterShortStyle];
		//[formatter setTimeStyle:NSDateFormatterShortStyle];
		[formatter setTimeStyle:NSDateFormatterNoStyle];
		dateString = [formatter stringFromDate:date];
		
		return self;
	}
	return nil;
}

- (NSString*)score {
	return [NSString stringWithFormat:@"%.3lf sec", self.time];
}

- (NSString*)detail {
	CGSize imageSize = self.resultImage.size;
	return [NSString stringWithFormat:@"%d:%d, %@", (int)imageSize.width, (int)imageSize.height, dateString];
}

- (UIImage*)thumbnail {
	return thumbnailImage;
}

- (NSString*)shareText {
	
	NSString *score = [NSString stringWithFormat:@"%.3lf sec", self.time];
	
	CGSize imageSize = self.resultImage.size;
	NSString *rendersize = [NSString stringWithFormat:@"size(%d,%d)", (int)imageSize.width, (int)imageSize.height];
	
	UIDevice *device = [UIDevice currentDevice];
	//NSString *osinfo = [NSString stringWithFormat:@"%@ %@", [device systemName], [device systemVersion]];
	NSString *osinfo = [NSString stringWithFormat:@"iOS %@", [device systemVersion]];
	
	char namebuf[32];
	memset(namebuf, 32, '\0');
	size_t size;
	sysctlbyname("hw.machine", NULL, &size, NULL, 0);
	sysctlbyname("hw.machine", namebuf, &size, NULL, 0);
	NSString *devicename = [NSString stringWithCString:namebuf encoding:NSUTF8StringEncoding];
	
	return [NSString stringWithFormat:@"%@, %@ on %@ %@. %@", score, rendersize, devicename, osinfo, dateString];
}
@end
