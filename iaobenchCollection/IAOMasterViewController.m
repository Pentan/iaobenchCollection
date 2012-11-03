//
//  IAOMasterViewController.m
//  iaobenchCollection
//
//  Created by Satoru NAKAJIMA on 2012/10/05.
//  Copyright (c) 2012年 Satoru NAKAJIMA. All rights reserved.
//

#import "IAOMasterViewController.h"

//#import "IAODetailViewController.h"
#import "IAOOfflineViewController.h"

//#import "IAORenderer.h"

#import "IAOaobenchOriginal.h"
#import "IAOaobenchGCD.h"
#import "IAOaobenchXorShift64.h"
#import "IAOaobenchXorShift128.h"
#import "IAOaobenchGCDXorShift.h"
#import "IAOaobenchVBase.h"
#import "IAOaobenchBLAS.h"
#import "IAOaobenchvDSP.h"

#import "IAOaobenchFloat.h"
#import "IAOaobenchFloatXorShift.h"
#import "IAOaobenchFloatGCD.h"
#import "IAOaobenchFloatGCDXorShift.h"
#import "IAOaobenchFloatVBase.h"
#import "IAOaobenchFloatBLAS.h"
#import "IAOaobenchFloatvDSP.h"
#import "IAOaobenchFloatGLKMath.h"
#import "IAOaobenchFloatGCDXorShiftGLK.h"
#import "IAOaobenchGLSL.h"

/////
@interface IAOMasterSectionContainer : NSObject
@property (copy, nonatomic) NSString *title;
@property (strong, nonatomic) NSMutableArray *items;
- (id)initWithTitle:(NSString*)newTitle;
@end

@implementation IAOMasterSectionContainer
- (id)initWithTitle:(NSString*)newTitle {
	if(self = [super init]) {
		_title = newTitle;
		_items = [[NSMutableArray alloc] init];
		return self;
	}
	return nil;
}
@end

/////
@interface IAOMasterViewController ()
{
	NSMutableArray *aobenchItems;
}
@end

@implementation IAOMasterViewController

- (void)awakeFromNib
{
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
	    self.clearsSelectionOnViewWillAppear = NO;
	    self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
	}
	
	//
	aobenchItems = [[NSMutableArray alloc] initWithCapacity:3];
	
	IAOMasterSectionContainer *doubleSection = [[IAOMasterSectionContainer alloc] initWithTitle:@"double precision"];
	[doubleSection.items addObject:[[IAOaobenchOriginal alloc] init]];
	[doubleSection.items addObject:[[IAOaobenchXorShift64 alloc] init]];
	[doubleSection.items addObject:[[IAOaobenchXorShift128 alloc] init]];
	[doubleSection.items addObject:[[IAOaobenchGCD alloc] init]];
	[doubleSection.items addObject:[[IAOaobenchGCDXorShift alloc] init]];
	[doubleSection.items addObject:[[IAOaobenchVBase alloc] init]];
	[doubleSection.items addObject:[[IAOaobenchBLAS alloc] init]];
	[doubleSection.items addObject:[[IAOaobenchvDSP alloc] init]];
	[aobenchItems addObject:doubleSection];
	
	IAOMasterSectionContainer *floatSection = [[IAOMasterSectionContainer alloc] initWithTitle:@"single precision"];
	[floatSection.items addObject:[[IAOaobenchFloat alloc] init]];
	[floatSection.items addObject:[[IAOaobenchFloatXorShift alloc] init]];
	[floatSection.items addObject:[[IAOaobenchFloatGCD alloc] init]];
	[floatSection.items addObject:[[IAOaobenchFloatGCDXorShift alloc] init]];
	[floatSection.items addObject:[[IAOaobenchFloatVBase alloc] init]];
	[floatSection.items addObject:[[IAOaobenchFloatBLAS alloc] init]];
	[floatSection.items addObject:[[IAOaobenchFloatvDSP alloc] init]];
	[floatSection.items addObject:[[IAOaobenchFloatGLKMath alloc] init]];
	[floatSection.items addObject:[[IAOaobenchFloatGCDXorShiftGLK alloc] init]];
	[aobenchItems addObject:floatSection];
	
	IAOMasterSectionContainer *miscSection = [[IAOMasterSectionContainer alloc] initWithTitle:@"misc"];
	[miscSection.items addObject:[[IAOaobenchGLSL alloc] init]];
	[aobenchItems addObject:miscSection];
	
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	/*
	self.navigationItem.leftBarButtonItem = self.editButtonItem;
	UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
	self.navigationItem.rightBarButtonItem = addButton;
	 */
	self.detailViewController = (IAODetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
	
	UIBarButtonItem *backitem = [[UIBarButtonItem alloc] initWithTitle:@"List" style:UIBarButtonItemStyleBordered target:nil action:nil];
	self.navigationItem.backBarButtonItem = backitem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (id<IAORenderer>)selectedRenderer {
	NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
	if(indexPath) {
		IAOMasterSectionContainer *sectionContainer = [aobenchItems objectAtIndex:indexPath.section];
		return [sectionContainer.items objectAtIndex:indexPath.row];
	}
	return nil;
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return [aobenchItems count];
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	IAOMasterSectionContainer *sectionContainer = [aobenchItems objectAtIndex:section];
	return sectionContainer.title;
	
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	IAOMasterSectionContainer *sectionContainer = [aobenchItems objectAtIndex:section];
	return [sectionContainer.items count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *cellIdentifiers[] = {@"OfflineCell", @"RealtimeCell"};
	
	NSString *cellReuseId;
	IAOMasterSectionContainer *sectionContainer = [aobenchItems objectAtIndex:indexPath.section];
	id aorenderer = [sectionContainer.items objectAtIndex:indexPath.row];
	
	switch ([aorenderer rendererType]) {
		case kIAORendererTypeOffline:
			cellReuseId = cellIdentifiers[0];
			break;
		case kIAORendererTypeRealtime:
			cellReuseId = cellIdentifiers[1];
			break;
	}
	
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellReuseId forIndexPath:indexPath];
	
	cell.textLabel.text = [aorenderer name];
	cell.detailTextLabel.text = [aorenderer information];
	
    return cell;
}

/*
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [_objects removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
		UINavigationController *detailNavCon = [self.splitViewController.viewControllers lastObject];
		[detailNavCon popToRootViewControllerAnimated:NO];
		[detailNavCon.topViewController performSegueWithIdentifier:@"ShowOfflineView" sender:self];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	id aorenderer = [self selectedRenderer];
	
    if ([[segue identifier] isEqualToString:@"ShowOfflineView"]) {
		IAOOfflineViewController *offlineViewController = [segue destinationViewController];
		offlineViewController.renderer = aorenderer;
    }
}

@end
