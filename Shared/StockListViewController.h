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


@class StockListView;
@class DetailViewController;

@interface StockListViewController : UITableViewController <LSTableDelegate, UIPopoverControllerDelegate, UINavigationControllerDelegate> {
	StockListView *_stockListView;
	
	BOOL _subscribed;
	LSSubscribedTableKey *_tableKey;
	
	dispatch_queue_t _backgroundQueue;

	NSIndexPath *_selectedRow;
	
	NSMutableDictionary *_itemUpdated;
	NSMutableDictionary *_itemData;
	
	NSMutableSet *_rowsToBeReloaded;
	
	UIBarButtonItem *_infoButton;
	UIPopoverController *_popoverInfoController;
	
	UIBarButtonItem *_statusButton;
	UIPopoverController *_popoverStatusController;
    
	DetailViewController *_detailController;
}


#pragma mark -
#pragma mark Communication with App delegate

- (void) handleMPN:(NSDictionary *)mpn;


@end
