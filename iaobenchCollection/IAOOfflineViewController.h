//
//  IAOOfflineViewController.h
//  iaobenchCollection
//
//  Created by Satoru NAKAJIMA on 2012/10/07.
//  Copyright (c) 2012年 Satoru NAKAJIMA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IAORenderer.h"

@interface IAOOfflineViewController : UITableViewController <UIActionSheetDelegate>

@property (strong, nonatomic) id<IAORenderer>renderer;

@end
