//
//  IAOOfflineViewController.m
//  iaobenchCollection
//
//  Created by Satoru NAKAJIMA on 2012/10/07.
//  Copyright (c) 2012年 Satoru NAKAJIMA. All rights reserved.
//

#import <Social/Social.h>

#import "IAOOfflineViewController.h"

#import "IAOaobenchScore.h"

@interface IAOOfflineViewController ()
{
	NSMutableArray *scoresArray;
	UIImage *currentImage;
	
	// share
	NSMutableArray *shareSheetButtons;
	IAOaobenchScore *shareTargetScore;
}
@property (weak, nonatomic) UIImageView *renderdImageView;
@end

@implementation IAOOfflineViewController

- (void)setRenderer:(id<IAORenderer>)newRenderer {
	if(_renderer != newRenderer) {
		_renderer = newRenderer;
		self.title = [newRenderer name];
	}
}
/*
- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}
*/

- (void)awakeFromNib {
	scoresArray = [[NSMutableArray alloc] initWithCapacity:16];
	currentImage = [UIImage imageNamed:@"aodummy"];
	shareSheetButtons = [[NSMutableArray alloc] initWithCapacity:4];
	shareTargetScore = nil;
	
	[super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
	
	// When iPad, hide backbuttom
	if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
		[self.navigationItem setHidesBackButton:YES];
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Render

- (void)renderAO {
	int aowidth = 256;
	int aoheight = 256;
	unsigned char *buffer = (unsigned char*)malloc(aowidth * aoheight * 4 * sizeof(unsigned char));
	
	NSTimeInterval renderTime = [self.renderer render:buffer width:aowidth height:aoheight];
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef context = CGBitmapContextCreate(buffer, aowidth, aoheight, 8, aowidth * 4, colorSpace, kCGImageAlphaNoneSkipLast);
	UIImage *resultImage = [UIImage imageWithCGImage:CGBitmapContextCreateImage(context)];
	
	IAOaobenchScore *score = [[IAOaobenchScore alloc] initWithTime:renderTime image:resultImage];
	
	[scoresArray addObject:score];
	
	CGContextRelease(context);
	CGColorSpaceRelease(colorSpace);
	free(buffer);
	
	[self performSelectorOnMainThread:@selector(renderFinished:) withObject:score waitUntilDone:NO];
}

- (void)renderFinished:(IAOaobenchScore*)lastScore {
	currentImage = lastScore.resultImage;
	[self.tableView reloadData];
	
	NSIndexPath *showpath = [NSIndexPath indexPathForRow:[scoresArray count]-1 inSection:1];
	[self.tableView scrollToRowAtIndexPath:showpath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

#pragma mark - Share

- (void)shareScore:(IAOaobenchScore*)score {
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Share score"
															 delegate:self
													cancelButtonTitle:@"Cancel"
											   destructiveButtonTitle:nil
													otherButtonTitles:nil];
	
	shareTargetScore = score;
	
	[shareSheetButtons removeAllObjects];
	[shareSheetButtons addObject:[NSNull null]];
	
	if([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
		[actionSheet addButtonWithTitle:@"FaceBook"];
		[shareSheetButtons addObject:SLServiceTypeFacebook];
	}
	if([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
		[actionSheet addButtonWithTitle:@"Twitter"];
		[shareSheetButtons addObject:SLServiceTypeTwitter];
	}
	if([SLComposeViewController isAvailableForServiceType:SLServiceTypeSinaWeibo]) {
		[actionSheet addButtonWithTitle:@"Weibo"];
		[shareSheetButtons addObject:SLServiceTypeSinaWeibo];
	}
	
	if(actionSheet.numberOfButtons > 1) {
		[actionSheet showInView:self.view];
	}
	else {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Cannot Share"
														message:@"No available SNS found. Please setup your information at the Settings App."
													   delegate:nil
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
		[alert show];
	}
}

#pragma mark - ActionSheet delegate
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
	//NSLog(@"action sheet dismissed with: %d", buttonIndex);
	
	if(buttonIndex > 0 && shareTargetScore != nil) {
		NSString *selectedService = [shareSheetButtons objectAtIndex:buttonIndex];
		SLComposeViewController *compositeController = [SLComposeViewController composeViewControllerForServiceType:selectedService];
		
		[compositeController setInitialText:[NSString stringWithFormat:@"%@ %@", [self.renderer name], [shareTargetScore shareText]]];
		[compositeController addImage:shareTargetScore.resultImage];
		
		[self.navigationController presentViewController:compositeController animated:YES completion:nil];
	}
	shareTargetScore = nil;
	[shareSheetButtons removeAllObjects];
}

- (void)actionSheetCancel:(UIActionSheet *)actionSheet {
	NSLog(@"action sheet canceled");
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	static NSString *titles[] = {@"", @"Scores"};
	return titles[section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	switch (section) {
		case 0:
			return 2;
		case 1:
			return [scoresArray count];
	}
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell;
    IAOaobenchScore *score;
	
	switch (indexPath.section) {
		case 0:
			switch (indexPath.row) {
				case 0:
					cell = [tableView dequeueReusableCellWithIdentifier:@"RenderedImageCell" forIndexPath:indexPath];
					self.renderdImageView = (UIImageView*)[cell viewWithTag:1];
					self.renderdImageView.image = currentImage;
					break;
				case 1:
					cell = [tableView dequeueReusableCellWithIdentifier:@"RunCell" forIndexPath:indexPath];
					break;
			}
			break;
		case 1:
			cell = [tableView dequeueReusableCellWithIdentifier:@"ScoreCell" forIndexPath:indexPath];
			score = [scoresArray objectAtIndex:indexPath.row];
			cell.textLabel.text = [score score];
			cell.detailTextLabel.text = [score detail];
			cell.imageView.image = [score thumbnail];
			//cell.imageView.contentMode = UIViewContentModeCenter;
			break;
	}
	
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	switch (indexPath.section) {
		case 0:
			return (indexPath.row == 0)? 298:[tableView rowHeight];
		case 1:
			return [tableView rowHeight];
	}
	return [tableView rowHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch (indexPath.section) {
		case 0: // render
			if(indexPath.row == 1) {
				[self renderAO];
			}
			break;
		case 1: // share
			[self shareScore:[scoresArray objectAtIndex:indexPath.row]];
			break;
	}
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
