//
//  DetailViewController.h
//  StockList Demo for iOS
//
// Copyright (c) Lightstreamer Srl
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
#import "ChartViewDelegate.h"


@class DetailView;
@class ChartViewController;

@interface DetailViewController : UIViewController <LSTableDelegate, ChartViewDelegate> {
	DetailView *_detailView;
	
	ChartViewController *_chartController;
	
	LSMPNSubscription *_priceMpnSubscription;
	LSSubscribedTableKey *_tableKey;

	dispatch_queue_t _backgroundQueue;
	
	NSString *_item;
	
	NSMutableDictionary *_itemData;
	NSMutableDictionary *_itemUpdated;
}


#pragma mark -
#pragma mark Communication with StockList View Controller

- (void) changeItem:(NSString *)item;
- (void) updateViewForMPNStatus;


#pragma mark -
#pragma mark User interfaction

- (IBAction) mpnSwitchDidChange;


#pragma mark -
#pragma mark Properties

@property (nonatomic, readonly) NSString *item;


@end
