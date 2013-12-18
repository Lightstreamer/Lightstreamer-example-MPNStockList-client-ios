//
//  StockListViewController.h
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

#import <UIKit/UIKit.h>
#import <LSConnectionDelegate.h>
#import <LSTableDelegate.h>


@class StockListView;
@class LSClient;
@class LSSubscribedTableKey;

@interface StockListViewController : UITableViewController <LSConnectionDelegate, LSTableDelegate, UIPopoverControllerDelegate> {
	StockListView *_stockListView;
	
	NSArray *_itemNames;
	NSArray *_fieldNames;
	
	LSClient *_client;
	LSSubscribedTableKey *_tableKey;
	
	NSMutableDictionary *_itemUpdated;
	NSMutableDictionary *_itemData;
	
	NSMutableSet *_rowsToBeReloaded;
	
	BOOL _polling;
	
	UIBarButtonItem *_infoButton;
	UIPopoverController *_popoverInfoController;
	
	UIBarButtonItem *_statusButton;
	UIPopoverController *_popoverStatusController;
    
    UIImage *_disconnectedIcon;
    UIImage *_streamingIcon;
    UIImage *_pollingIcon;
    UIImage *_stalledIcon;
}


#pragma mark -
#pragma mark User actions

- (void) infoTapped;
- (void) statusTapped;


#pragma mark -
#pragma mark Lightstreamer management

- (void) connectToLightstreamer;
- (void) subscribeItems;


#pragma mark -
#pragma mark Internals

- (void) reloadTableRows;

#pragma mark -
#pragma mark Special effects

- (void) flashLabel:(UILabel *)label withColor:(UIColor *)color;
- (void) unflashLabel:(UILabel *)label;

- (void) flashImage:(UIImageView *)imageView withColor:(UIColor *)color;
- (void) unflashImage:(UIImageView *)imageView;


@end
