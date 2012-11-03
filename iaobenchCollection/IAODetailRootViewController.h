//
//  IAODetailRootViewController.h
//  iaobenchCollection
//
//  Created by Satoru NAKAJIMA on 2012/10/15.
//  Copyright (c) 2012年 Satoru NAKAJIMA. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IAODetailRootViewController : UITableViewController <UISplitViewControllerDelegate>

- (void)pushDetailViewController:(id)newController;

@end
