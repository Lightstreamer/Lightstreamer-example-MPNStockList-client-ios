//
//  StockListViewController.m
//  StockList Demo for iOS
//
// Copyright 2013 Weswit Srl
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
// http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <QuartzCore/QuartzCore.h>
#import <LightstreamerClient.h>
#import "StockListViewController.h"
#import "StockListView.h"
#import "StockListCell.h"
#import "InfoViewController.h"
#import "StatusViewController.h"
#import "Constants.h"

#define SERVER_URL     (@"http://push.lightstreamer.com")


@implementation StockListViewController


#pragma mark -
#pragma mark Initialization

- (id) init {
	if (self = [super init]) {
		self.title= @"LS StockList";
		
		_itemNames= [[NSArray alloc] initWithObjects:ITEMS, nil];
		_fieldNames= [[NSArray alloc] initWithObjects:FIELDS, nil];

		_itemData= [[NSMutableDictionary alloc] initWithCapacity:NUMBER_OF_ITEMS];
		_itemUpdated= [[NSMutableDictionary alloc] initWithCapacity:NUMBER_OF_ITEMS];
		
		_rowsToBeReloaded= [[NSMutableSet alloc] initWithCapacity:NUMBER_OF_ITEMS];
        
		// Uncomment for detailed logging
//		[LSLog enableSourceType:LOG_SRC_CLIENT];
//		[LSLog enableSourceType:LOG_SRC_SESSION];
//		[LSLog enableSourceType:LOG_SRC_STATE_MACHINE];
//		[LSLog enableSourceType:LOG_SRC_URL_DISPATCHER];
	}
	
	return self;
}

- (void) dealloc {
	[_itemNames release];
	[_fieldNames release];
	
	[_itemData release];
	[_itemUpdated release];
	
	[_rowsToBeReloaded release];
	
	[super dealloc];
}


#pragma mark -
#pragma mark User actions

- (void) infoTapped {
	if (DEVICE_IPAD) {
		if (_popoverInfoController)
			return;
		
		if (_popoverStatusController)
			return;

		InfoViewController *infoController= [[InfoViewController alloc] init];
		_popoverInfoController= [[UIPopoverController alloc] initWithContentViewController:infoController];
		
		_popoverInfoController.popoverContentSize= CGSizeMake(INFO_IPAD_WIDTH, INFO_IPAD_HEIGHT);
		_popoverInfoController.delegate= self;
		
		[_popoverInfoController presentPopoverFromBarButtonItem:self.navigationItem.rightBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		[infoController release];
		
	} else {
		[UIView beginAnimations:nil context:NULL];
		
		[UIView setAnimationDuration:FLIP_DURATION];
		[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:self.navigationController.view cache:YES];
		
		InfoViewController *infoController= [[InfoViewController alloc] init];
		[self.navigationController pushViewController:infoController animated:NO];
		[infoController release];
		
		[UIView commitAnimations];
	}
}

- (void) statusTapped {
	if (DEVICE_IPAD) {
		if (_popoverStatusController)
			return;
		
		if (_popoverInfoController)
			return;

		StatusViewController *statusController= [[StatusViewController alloc] init];
		_popoverStatusController= [[UIPopoverController alloc] initWithContentViewController:statusController];
		
		_popoverStatusController.popoverContentSize= CGSizeMake(STATUS_IPAD_WIDTH, STATUS_IPAD_HEIGHT);
		_popoverStatusController.delegate= self;
		
		[_popoverStatusController presentPopoverFromBarButtonItem:self.navigationItem.leftBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		[statusController release];
		
	} else {
		[UIView beginAnimations:nil context:NULL];
		
		[UIView setAnimationDuration:FLIP_DURATION];
		[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:self.navigationController.view cache:YES];
		
		StatusViewController *statusController= [[StatusViewController alloc] init];
		[self.navigationController pushViewController:statusController animated:NO];
		[statusController release];
		
		[UIView commitAnimations];
	}
}


#pragma mark -
#pragma mark Methods of UIViewController

- (void) loadView {
	NSArray *niblets= [[NSBundle mainBundle] loadNibNamed:DEVICE_XIB(@"StockListView") owner:self options:NULL];
	_stockListView= (StockListView *) [niblets lastObject];
	
	self.tableView= _stockListView.table;
	self.view= _stockListView;
	
	UIBarButtonItem *infoButton= [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Info.png"] style:UIBarButtonItemStylePlain target:self action:@selector(infoTapped)];
	self.navigationItem.rightBarButtonItem= [infoButton autorelease];
	
	UIBarButtonItem *statusButton= [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Dot-red.png"] style:UIBarButtonItemStylePlain target:self action:@selector(statusTapped)];
	self.navigationItem.leftBarButtonItem= [statusButton autorelease];

	[self performSelector:@selector(connectToLightstreamer) withObject:nil afterDelay:1.0];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

- (BOOL) shouldAutorotate {
	return YES;
}

- (NSUInteger) supportedInterfaceOrientations {
	return UIInterfaceOrientationMaskAll;
}


#pragma mark -
#pragma mark Methods of UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return NUMBER_OF_ITEMS;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    StockListCell *cell= (StockListCell *) [tableView dequeueReusableCellWithIdentifier:@"StockListCell"];
    if (!cell) {
		NSArray *niblets= [[NSBundle mainBundle] loadNibNamed:DEVICE_XIB(@"StockListCell") owner:self options:NULL];
		cell= (StockListCell *) [niblets lastObject];
    }

	NSMutableDictionary *item= nil;
	NSMutableDictionary *itemUpdated= nil;
	@synchronized (_itemData) {
		item= [_itemData objectForKey:[NSNumber numberWithInt:indexPath.row]];
		itemUpdated= [_itemUpdated objectForKey:[NSNumber numberWithInt:indexPath.row]];
	}
	
	if (item) {
		NSString *colorName= [item objectForKey:@"color"];
		UIColor *color= nil;
		if ([colorName isEqualToString:@"green"])
			color= GREEN_COLOR;
		else if ([colorName isEqualToString:@"orange"])
			color= ORANGE_COLOR;
		else
			color= [UIColor whiteColor];
		
		cell.nameLabel.text= [item objectForKey:@"stock_name"];
		if ([[itemUpdated objectForKey:@"stock_name"] boolValue]) {
			[self flashLabel:cell.nameLabel withColor:color];
			[itemUpdated setObject:[NSNumber numberWithBool:NO] forKey:@"stock_name"];
		}
		
		cell.lastLabel.text= [item objectForKey:@"last_price"];
		if ([[itemUpdated objectForKey:@"last_price"] boolValue]) {
			[self flashLabel:cell.lastLabel withColor:color];
			[itemUpdated setObject:[NSNumber numberWithBool:NO] forKey:@"last_price"];
		}

		cell.timeLabel.text= [item objectForKey:@"time"];
		if ([[itemUpdated objectForKey:@"time"] boolValue]) {
			[self flashLabel:cell.timeLabel withColor:color];
			[itemUpdated setObject:[NSNumber numberWithBool:NO] forKey:@"time"];
		}

		double pctChange= [[item objectForKey:@"pct_change"] doubleValue];
		if (pctChange > 0.0)
			cell.dirImage.image= [UIImage imageNamed:@"Arrow-up.png"];
		else if (pctChange < 0.0)
			cell.dirImage.image= [UIImage imageNamed:@"Arrow-down.png"];
		else
			cell.dirImage.image= nil;

		cell.changeLabel.text= [NSString stringWithFormat:@"%@%%", [item objectForKey:@"pct_change"]];
		cell.changeLabel.textColor= (([[item objectForKey:@"pct_change"] doubleValue] >= 0.0) ? DK_GREEN_COLOR : RED_COLOR);

		if ([[itemUpdated objectForKey:@"pct_change"] boolValue]) {
			[self flashImage:cell.dirImage withColor:color];
			[self flashLabel:cell.changeLabel withColor:color];
			[itemUpdated setObject:[NSNumber numberWithBool:NO] forKey:@"pct_change"];
		}
		
		cell.refLabel.text= [item objectForKey:@"ref_price"];
		if ([[itemUpdated objectForKey:@"ref_price"] boolValue]) {
			[self flashLabel:cell.refLabel withColor:color];
			[itemUpdated setObject:[NSNumber numberWithBool:NO] forKey:@"ref_price"];
		}
		
		if (DEVICE_IPAD) {
			cell.minLabel.text= [item objectForKey:@"min"];
			if ([[itemUpdated objectForKey:@"min"] boolValue]) {
				[self flashLabel:cell.minLabel withColor:color];
				[itemUpdated setObject:[NSNumber numberWithBool:NO] forKey:@"min"];
			}
			
			cell.maxLabel.text= [item objectForKey:@"max"];
			if ([[itemUpdated objectForKey:@"max"] boolValue]) {
				[self flashLabel:cell.maxLabel withColor:color];
				[itemUpdated setObject:[NSNumber numberWithBool:NO] forKey:@"max"];
			}
			
			cell.bidLabel.text= [item objectForKey:@"bid"];
			if ([[itemUpdated objectForKey:@"bid"] boolValue]) {
				[self flashLabel:cell.bidLabel withColor:color];
				[itemUpdated setObject:[NSNumber numberWithBool:NO] forKey:@"bid"];
			}

			cell.askLabel.text= [item objectForKey:@"ask"];
			if ([[itemUpdated objectForKey:@"ask"] boolValue]) {
				[self flashLabel:cell.askLabel withColor:color];
				[itemUpdated setObject:[NSNumber numberWithBool:NO] forKey:@"ask"];
			}

			cell.openLabel.text= [item objectForKey:@"open_price"];
			if ([[itemUpdated objectForKey:@"open_price"] boolValue]) {
				[self flashLabel:cell.openLabel withColor:color];
				[itemUpdated setObject:[NSNumber numberWithBool:NO] forKey:@"open_price"];
			}
		}
	}
    
    return cell;
}


#pragma mark -
#pragma mark Methods of UITableViewDelegate

- (NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	return nil;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	NSArray *niblets= [[NSBundle mainBundle] loadNibNamed:DEVICE_XIB(@"StockListSection") owner:self options:NULL];

	return (UIView *) [niblets lastObject];
}

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.row % 2 == 0)
		cell.backgroundColor= LIGHT_ROW_COLOR;
	else
		cell.backgroundColor= DARK_ROW_COLOR;
}


#pragma mark -
#pragma mark Methods of UIPopoverControllerDelegate

- (void) popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
	if (popoverController == _popoverInfoController) {
		[_popoverInfoController release];
		_popoverInfoController= nil;
	
	} else if (popoverController == _popoverStatusController) {
		[_popoverStatusController release];
		_popoverStatusController= nil;
	}
}


#pragma mark -
#pragma mark Lighstreamer management

- (void) connectToLightstreamer {
	_client= [[LSClient alloc] init];
	
	NSLog(@"StockListViewController: Connecting to Lightstreamer...");

	LSConnectionInfo *connectionInfo= [LSConnectionInfo connectionInfoWithPushServerURL:SERVER_URL pushServerControlURL:nil user:nil password:nil adapter:@"DEMO"];
	[_client openConnectionWithInfo:connectionInfo delegate:self];
}

- (void) subscribeItems {
	NSLog(@"StockListViewController: Subscribing table...");

	@try {
		LSExtendedTableInfo *tableInfo= [LSExtendedTableInfo extendedTableInfoWithItems:_itemNames mode:LSModeMerge fields:_fieldNames dataAdapter:@"QUOTE_ADAPTER" snapshot:YES];
		tableInfo.requestedMaxFrequency= 1.0;

		_tableKey= [[_client subscribeTableWithExtendedInfo:tableInfo delegate:self useCommandLogic:NO] retain];

		NSLog(@"StockListViewController: Table subscribed");

	} @catch (NSException *e) {
		NSLog(@"StockListViewController: Table subscription failed due to exception: %@", e);
	}
}

- (void) unsubscribeItems {
	NSLog(@"StockListViewController: Unsubscribing table...");
	
	@try {
		[_client unsubscribeTable:_tableKey];

		[_tableKey release];
		_tableKey= nil;
		
		NSLog(@"StockListViewController: Table unsubscribed");

	} @catch (NSException *e) {
		NSLog(@"StockListViewController: Table unsubscription failed due to exception: %@", e);
	}
}


#pragma mark -
#pragma mark Internals

- (void) reloadTableRows {
	NSMutableArray *rowsToBeReloaded= nil;
	@synchronized (_rowsToBeReloaded) {
		rowsToBeReloaded= [[NSMutableArray alloc] initWithCapacity:[_rowsToBeReloaded count]];
		
		for (NSIndexPath *indexPath in _rowsToBeReloaded)
			[rowsToBeReloaded addObject:indexPath];

		[_rowsToBeReloaded removeAllObjects];
	}
	
	[_stockListView.table reloadRowsAtIndexPaths:[rowsToBeReloaded autorelease] withRowAnimation:UITableViewRowAnimationNone];
}


#pragma mark -
#pragma mark Special effects

- (void) flashLabel:(UILabel *)label withColor:(UIColor *)color {
	if (_stockListView.table.dragging)
		return;
	
	label.layer.backgroundColor= color.CGColor;
	if (label.tag == COLORED_LABEL_TAG) 
		label.textColor= [UIColor blackColor];
	
	[self performSelector:@selector(unflashLabel:) withObject:label afterDelay:FLASH_DURATION];
}

- (void) unflashLabel:(UILabel *)label {
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
	[UIView setAnimationDuration:FLASH_DURATION];
	
	label.layer.backgroundColor= [UIColor clearColor].CGColor;
	if (label.tag == COLORED_LABEL_TAG) 
		label.textColor= (([label.text doubleValue] >= 0.0) ? DK_GREEN_COLOR : RED_COLOR);
	
	[UIView commitAnimations];
}

- (void) flashImage:(UIImageView *)imageView withColor:(UIColor *)color {
	if (_stockListView.table.dragging)
		return;

	imageView.backgroundColor= color;
	
	[self performSelector:@selector(unflashImage:) withObject:imageView afterDelay:FLASH_DURATION];
}

- (void) unflashImage:(UIImageView *)imageView {
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
	[UIView setAnimationDuration:FLASH_DURATION];
	
	imageView.backgroundColor= [UIColor clearColor];
	
	[UIView commitAnimations];
}


#pragma mark -
#pragma mark Methods of LSConnectionDelegate

- (void) clientConnection:(LSClient *)client didStartSessionWithPolling:(BOOL)polling {
	NSLog(@"StockListViewController: Session started with polling: %@", (polling ? @"YES" : @"NO"));
	
	_polling= polling;
	
	[self.navigationItem.leftBarButtonItem performSelectorOnMainThread:@selector(setImage:)
															withObject:[UIImage imageNamed:(_polling ? @"Dot-cyan.png" : @"Dot-green.png")]
														 waitUntilDone:NO];
	
	if (!_tableKey)
        [self subscribeItems];
}

- (void) clientConnection:(LSClient *)client didChangeActivityWarningStatus:(BOOL)warningStatus {
	NSLog(@"StockListViewController: Activity warning status changed: %@", (warningStatus ? @"ON" : @"OFF"));
	
	if (warningStatus) {
		[self.navigationItem.leftBarButtonItem performSelectorOnMainThread:@selector(setImage:)
																withObject:[UIImage imageNamed:@"Dot-yellow.png"]
															 waitUntilDone:NO];
		
	} else {
		[self.navigationItem.leftBarButtonItem performSelectorOnMainThread:@selector(setImage:)
																withObject:[UIImage imageNamed:(_polling ? @"Dot-cyan.png" : @"Dot-green.png")]
															 waitUntilDone:NO];
	}
}

- (void) clientConnectionDidEstablish:(LSClient *)client {
	NSLog(@"StockListViewController: Connection established");
}

- (void) clientConnectionDidClose:(LSClient *)client {
	NSLog(@"StockListViewController: Connection closed");
	
	[self.navigationItem.leftBarButtonItem performSelectorOnMainThread:@selector(setImage:)
															withObject:[UIImage imageNamed:@"Dot-red.png"]
														 waitUntilDone:NO];
}

- (void) clientConnection:(LSClient *)client didEndWithCause:(int)cause {
	NSLog(@"StockListViewController: Connection ended, cause: %d", cause);
	
	[self.navigationItem.leftBarButtonItem performSelectorOnMainThread:@selector(setImage:)
															withObject:[UIImage imageNamed:@"Dot-red.png"]
														 waitUntilDone:NO];
}

- (void) clientConnection:(LSClient *)client didReceiveDataError:(LSPushServerException *)error {
	NSLog(@"StockListViewController: Data error: %@", error);
}

- (void) clientConnection:(LSClient *)client didReceiveServerFailure:(LSPushServerException *)failure {
	NSLog(@"StockListViewController: Server failure: %@", failure);
	
	[self.navigationItem.leftBarButtonItem performSelectorOnMainThread:@selector(setImage:)
															withObject:[UIImage imageNamed:@"Dot-red.png"]
														 waitUntilDone:NO];
}

- (void) clientConnection:(LSClient *)client didReceiveConnectionFailure:(LSPushConnectionException *)failure {
	NSLog(@"StockListViewController: Connection failure: %@", failure);
	
	[self.navigationItem.leftBarButtonItem performSelectorOnMainThread:@selector(setImage:)
															withObject:[UIImage imageNamed:@"Dot-red.png"]
														 waitUntilDone:NO];
}

- (void) clientConnection:(LSClient *)client isAboutToSendURLRequest:(NSMutableURLRequest *)urlRequest {}


#pragma mark -
#pragma mark Methods of LSTableDelegate

- (void) table:(LSSubscribedTableKey *)tableKey itemPosition:(int)itemPosition itemName:(NSString *)itemName didUpdateWithInfo:(LSUpdateInfo *)updateInfo {
	NSMutableDictionary *item= nil;
	NSMutableDictionary *itemUpdated= nil;
	@synchronized (_itemData) {
		item= [_itemData objectForKey:[NSNumber numberWithInt:(itemPosition -1)]];
		if (!item) {
			item= [[[NSMutableDictionary alloc] initWithCapacity:NUMBER_OF_FIELDS] autorelease];
			[_itemData setObject:item forKey:[NSNumber numberWithInt:(itemPosition -1)]];
		}

		itemUpdated= [_itemUpdated objectForKey:[NSNumber numberWithInt:(itemPosition -1)]];
		if (!itemUpdated) {
			itemUpdated= [[[NSMutableDictionary alloc] initWithCapacity:NUMBER_OF_FIELDS] autorelease];
			[_itemUpdated setObject:itemUpdated forKey:[NSNumber numberWithInt:(itemPosition -1)]];
		}
	}
		
	for (NSString *fieldName in _fieldNames) {
		NSString *value= [updateInfo currentValueOfFieldName:fieldName];
		
		if (value)
			[item setObject:value forKey:fieldName];
		else
			[item setObject:[NSNull null] forKey:fieldName];
		
		if ([updateInfo isChangedValueOfFieldName:fieldName])
			[itemUpdated setObject:[NSNumber numberWithBool:YES] forKey:fieldName];
	}
	
	double currentLastPrice= [[updateInfo currentValueOfFieldName:@"last_price"] doubleValue];
	double previousLastPrice= [[updateInfo previousValueOfFieldName:@"last_price"] doubleValue];
	if (currentLastPrice >= previousLastPrice)
		[item setObject:@"green" forKey:@"color"];
	else
		[item setObject:@"orange" forKey:@"color"];

	@synchronized (_rowsToBeReloaded) {
		[_rowsToBeReloaded addObject:[NSIndexPath indexPathForRow:(itemPosition -1) inSection:0]];
	}
	
	[self performSelectorOnMainThread:@selector(reloadTableRows) withObject:nil waitUntilDone:NO];
}


@end

