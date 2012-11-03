//
//  IAOMasterViewController.h
//  iaobenchCollection
//
//  Created by Satoru NAKAJIMA on 2012/10/05.
//  Copyright (c) 2012年 Satoru NAKAJIMA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IAORenderer.h"

@class IAODetailViewController;

@interface IAOMasterViewController : UITableViewController

@property (strong, nonatomic) IAODetailViewController *detailViewController;

- (id<IAORenderer>)selectedRenderer;

@end
