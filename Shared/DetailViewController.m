//
//  DetailViewController.m
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

#import "DetailViewController.h"
#import "DetailView.h"
#import "ChartViewController.h"
#import "ChartThreshold.h"
#import "StockListAppDelegate.h"
#import "StockListViewController.h"
#import "Connector.h"
#import "SpecialEffects.h"
#import "Constants.h"
#import "UIAlertView+BlockExtensions.h"


#pragma mark -
#pragma mark DetailViewController extension

@interface DetailViewController ()


#pragma mark -
#pragma mark Notifications from notification center

- (void) appDidRegisterForMPN;


#pragma mark -
#pragma mark Internals

- (void) disableMPNControls;
- (void) enableMPNControls;

- (void) updateView;

- (void) addOrUpdateMPNSubscriptionForThreshold:(ChartThreshold *)threshold greaterThan:(BOOL)greaterThan;
- (void) deleteMPNSubscriptionForThreshold:(ChartThreshold *)threshold;


@end


#pragma mark -
#pragma mark DetailViewController implementation

@implementation DetailViewController


#pragma mark -
#pragma mark Initialization

- (id) init {
	if (self = [super init]) {
		
        // Queue for background execution
		_backgroundQueue= dispatch_queue_create("backgroundQueue", 0);
		
		// Single-item data structures: they store fields data and
		// which fields have been updated
		_itemData= [[NSMutableDictionary alloc] init];
		_itemUpdated= [[NSMutableDictionary alloc] init];
	}
	
	return self;
}


#pragma mark -
#pragma mark Methods of UIViewController

- (void) loadView {
	NSArray *niblets= [[NSBundle mainBundle] loadNibNamed:DEVICE_XIB(@"DetailView") owner:self options:NULL];
	_detailView= (DetailView *) [niblets lastObject];
	
	self.view= _detailView;
	
	// Add chart
	_chartController= [[ChartViewController alloc] initWithDelegate:self];
	[_chartController.view setBackgroundColor:[UIColor whiteColor]];
	[_chartController.view setFrame:CGRectMake(0.0, 0.0, _detailView.chartBackgroundView.frame.size.width, _detailView.chartBackgroundView.frame.size.height)];
	
	[_detailView.chartBackgroundView addSubview:_chartController.view];
	
	// Initially disable MPN controls
	[self disableMPNControls];
}

- (void) viewWillAppear:(BOOL)animated {
	
	// Reset size of chart
	[_chartController.view setFrame:CGRectMake(0.0, 0.0, _detailView.chartBackgroundView.frame.size.width, _detailView.chartBackgroundView.frame.size.height)];
		
	// We use the notification center to know when the app
	// has been successfully registered for MPN and when
	// the MPN subscription cache has been updated
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidRegisterForMPN) name:NOTIFICATION_APP_MPN object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidUpdateMPNSubscriptionCache) name:NOTIFICATION_CACHE_UPDATED object:nil];
	
	// Check if registration for MPN has already been completed
	id <StockListAppDelegate> appDelegate= (id <StockListAppDelegate>) [[UIApplication sharedApplication] delegate];
	BOOL registrationSucceeded= appDelegate.registrationForMPNSucceeded;
	if (registrationSucceeded)
		[self enableMPNControls];
}

- (void) viewDidDisappear:(BOOL)animated {
	
	// Unregister from control center notifications
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_APP_MPN object:nil];
	
	// Unsubscribe the table
	if (_tableKey) {
		dispatch_async(_backgroundQueue, ^{
			NSLog(@"DetailViewController: unsubscribing previous table...");
			
			@try {
				[[[Connector sharedConnector] client] unsubscribeTable:_tableKey];
				
				NSLog(@"DetailViewController: previous table unsubscribed");
				
			} @catch (NSException *e) {
				NSLog(@"DetailViewController: previous table unsubscription failed with exception: %@", e);
			}
			
			_tableKey= nil;
		});
	}
}


#pragma mark -
#pragma mark Communication with StockList View Controller

- (void) changeItem:(NSString *)item {
	// This method is always called from the main thread
	
	// Set current item and clear the data
	@synchronized (self) {
		_item= item;
		
		[_itemData removeAllObjects];
		[_itemUpdated removeAllObjects];
	}
	
	// Update the view
	[self updateView];

	// Reset the chart
	[_chartController clearChart];
	
	// Check MPN status and update view
	[self updateViewForMPNStatus];
	
	dispatch_async(_backgroundQueue, ^{

		// If needed, unsubscribe previous table
		if (_tableKey) {
			NSLog(@"DetailViewController: unsubscribing previous table...");
			
			@try {
				[[[Connector sharedConnector] client] unsubscribeTable:_tableKey];
				
				NSLog(@"DetailViewController: previous table unsubscribed");
				
			} @catch (NSException *e) {
				NSLog(@"DetailViewController: previous table unsubscription failed with exception: %@", e);
			}
			
			_tableKey= nil;
		}
		
		// Subscribe new single-item table
		if (item) {
			NSLog(@"DetailViewController: subscribing table...");
			
			@try {
				
				// The LSClient will reconnect and resubscribe automatically
				LSExtendedTableInfo *tableInfo= [LSExtendedTableInfo extendedTableInfoWithItems:[NSArray arrayWithObject:item]
																						   mode:LSModeMerge
																						 fields:DETAIL_FIELDS
																					dataAdapter:DATA_ADAPTER
																					   snapshot:YES];
				
				_tableKey= [[[Connector sharedConnector] client] subscribeTableWithExtendedInfo:tableInfo
																					   delegate:self
																				useCommandLogic:NO];
				
				NSLog(@"DetailViewController: table subscribed");
				
			} @catch (NSException *e) {
				NSLog(@"DetailViewController: table subscription failed with exception: %@", e);
			}
		}
	});
}

- (void) updateViewForMPNStatus {
	// This method is always called from the main thread
	
	// Clear thresholds on the chart
	_detailView.mpnSwitch.on= NO;
	[_chartController clearThresholds];

	// Early bail
	if (!_item)
		return;
	
	// Update view according to cached MPN subscriptions
	NSArray *mpnSubscriptions= [[[Connector sharedConnector] client] cachedMPNSubscriptions];
	for (LSMPNSubscription *mpnSubscription in mpnSubscriptions) {
		NSString *item= [mpnSubscription.mpnInfo.customData objectForKey:@"item"];
		if (![_item isEqualToString:item])
			continue;
		
		NSString *subscriptionId= [mpnSubscription.mpnInfo.customData objectForKey:@"subscriptionId"];
		NSString *threshold= [mpnSubscription.mpnInfo.customData objectForKey:@"threshold"];
		
		if (subscriptionId && threshold) {
			
			// MPN subscription is a threshold
			ChartThreshold *chartThreshold= [_chartController addThreshold:[threshold floatValue]];
			chartThreshold.mpnSubscription= mpnSubscription;
			
		} else if (subscriptionId || threshold) {
			
			// MPN subscription is a threshold from the old version of the app,
			// extract the threshold from the trigger expression
			NSArray *components= [mpnSubscription.mpnInfo.triggerExpression componentsSeparatedByString:@" "];
			NSString *thresholdValue= [components lastObject];
			
			ChartThreshold *chartThreshold= [_chartController addThreshold:[thresholdValue floatValue]];
			chartThreshold.mpnSubscription= mpnSubscription;
			
		} else {
			
			// MPN subscription is main price subscription
			_priceMpnSubscription= mpnSubscription;
			_detailView.mpnSwitch.on= YES;
		}
	}
}


#pragma mark -
#pragma mark User interfaction

- (IBAction) mpnSwitchDidChange {
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	
	// Get and keep current item
	NSString *item= nil;
	@synchronized (self) {
		item= _item;
	}

	dispatch_async(_backgroundQueue, ^() {
		if (_detailView.mpnSwitch.on) {
			
			// Prepare the table info
			LSExtendedTableInfo *tableInfo= [LSExtendedTableInfo extendedTableInfoWithItems:[NSArray arrayWithObject:item]
																					   mode:LSModeMerge
																					 fields:DETAIL_FIELDS
																				dataAdapter:DATA_ADAPTER
																				   snapshot:NO];
			
			// Prepare the MPN info
			LSMPNInfo *mpnInfo= [LSMPNInfo mpnInfoWithTableInfo:tableInfo
														  sound:@"Default"
														  badge:@"AUTO"
														 format:@"Stock ${stock_name} is now ${last_price}"];
			
			// Add the custom data to match the subscription against the MPN list
			mpnInfo.customData= [NSDictionary dictionaryWithObjectsAndKeys:
								 item, @"item",
								 nil];
			
			// Add category for iOS >= 8.0
			mpnInfo.category= @"STOCK_PRICE_CATEGORY";
			
			@try {
				
				// Activate the new MPN subscription. Here we use the coalescing flag
				// to ensure the subscription may never get duplicated: if it should do,
				// we would not be able to deactivate them with the UI provided (a manual
				// deactivation on the Server would be required)
				_priceMpnSubscription= [[[Connector sharedConnector] client] activateMPN:mpnInfo coalescing:YES];
				
			} @catch (NSException *e) {
				NSLog(@"DetailViewController: exception caught while activating MPN subscription: %@", e);
				
				// Show error alert
				dispatch_async(dispatch_get_main_queue(), ^() {
					[[[UIAlertView alloc] initWithTitle:@"Error while activating MPN subscription"
												message:@"An error occurred and the MPN subscription could not be activated."
											   delegate:nil
									  cancelButtonTitle:@"Cancel"
									  otherButtonTitles:nil] show];
					
					// Cleanup
					_detailView.mpnSwitch.on= NO;
				});
				
			} @finally {
				dispatch_async(dispatch_get_main_queue(), ^(){
					[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
				});
			}
		
		} else {
			
			@try {
				
				// Delete the MPN subscription
                [_priceMpnSubscription deactivate];

				_priceMpnSubscription= nil;
				
			} @catch (NSException *e) {
				NSLog(@"DetailViewController: exception caught while deactivating MPN subscription: %@", e);
				
				// Show error alert
				dispatch_async(dispatch_get_main_queue(), ^() {
					[[[UIAlertView alloc] initWithTitle:@"Error while deactivating MPN subscription"
												message:@"An error occurred and the MPN subscription could not be deactivated."
											   delegate:nil
									  cancelButtonTitle:@"Cancel"
									  otherButtonTitles:nil] show];
					
					// Reset the MPN to its previous status
					_detailView.mpnSwitch.on= YES;
				});
				
			} @finally {
				dispatch_async(dispatch_get_main_queue(), ^(){
					[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
				});
			}
		}
	});
}


#pragma mark -
#pragma mark Methods of LSTableDelegate

- (void) table:(LSSubscribedTableKey *)tableKey itemPosition:(int)itemPosition itemName:(NSString *)itemName didUpdateWithInfo:(LSUpdateInfo *)updateInfo {
	// This method is always called from a background thread
	
	@synchronized (self) {
		
		// Check if it is a late update of the previous table
		if (![_item isEqualToString:itemName])
			return;
		
		// Store the updated fields in the item's data structures
		for (NSString *fieldName in DETAIL_FIELDS) {
			NSString *value= [updateInfo currentValueOfFieldName:fieldName];
			
			if (value)
				[_itemData setObject:value forKey:fieldName];
			else
				[_itemData setObject:[NSNull null] forKey:fieldName];
			
			if ([updateInfo isChangedValueOfFieldName:fieldName])
				[_itemUpdated setObject:[NSNumber numberWithBool:YES] forKey:fieldName];
		}
		
		double currentLastPrice= [[updateInfo currentValueOfFieldName:@"last_price"] doubleValue];
		double previousLastPrice= [[updateInfo previousValueOfFieldName:@"last_price"] doubleValue];
		if (currentLastPrice >= previousLastPrice)
			[_itemData setObject:@"green" forKey:@"color"];
		else
			[_itemData setObject:@"orange" forKey:@"color"];
	}
	
	dispatch_async(dispatch_get_main_queue(), ^{

		// Forward the update to the chart
		[_chartController itemDidUpdateWithInfo:updateInfo];
		
		// Update the view
		[self updateView];
	});
}


#pragma mark -
#pragma mark ChartViewDelegate methods

- (void) chart:(ChartViewController *)chartControllter didAddThreshold:(ChartThreshold *)threshold {
	float lastPrice= 0.0;
	@synchronized (self) {
		lastPrice= [[_itemData objectForKey:@"last_price"] floatValue];
	}
	
	if (threshold.value > lastPrice) {

		// The threshold is higher than current price,
		// ask confirm with the appropriate alert view
		[[[UIAlertView alloc] initWithTitle:@"Add alert on threshold"
									message:[NSString stringWithFormat:@"Confirm adding a notification alert when %@ rises above %.2f", self.title, threshold.value]
							completionBlock:^(NSUInteger buttonIndex, UIAlertView *alertView) {
								switch (buttonIndex) {
									case 0:
										 
										// Cleanup
										[_chartController removeThreshold:threshold];
										break;

									case 1:
										[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
										 
										// Proceed
										dispatch_async(_backgroundQueue, ^() {
											[self addOrUpdateMPNSubscriptionForThreshold:threshold greaterThan:YES];
										});
										break;
								}
							}
						  cancelButtonTitle:@"Cancel"
						  otherButtonTitles:@"Proceed", nil] show];

	} else if (threshold.value < lastPrice) {
		
		// The threshold is lower than current price,
		// ask confirm with the appropriate alert view
		[[[UIAlertView alloc] initWithTitle:@"Add alert on threshold"
									message:[NSString stringWithFormat:@"Confirm adding a notification alert when %@ drops below %.2f", self.title, threshold.value]
							completionBlock:^(NSUInteger buttonIndex, UIAlertView *alertView) {
								switch (buttonIndex) {
									case 0:
										 
										// Cleanup
										[_chartController removeThreshold:threshold];
										break;
										 
									case 1:
										[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
										 
										// Proceed
										dispatch_async(_backgroundQueue, ^() {
											[self addOrUpdateMPNSubscriptionForThreshold:threshold greaterThan:NO];
										});
										break;
								}
							}
						  cancelButtonTitle:@"Cancel"
						  otherButtonTitles:@"Proceed", nil] show];
	
	} else {
		
		// The threshold matches current price,
		// show the appropriate alert view
		[[[UIAlertView alloc] initWithTitle:@"Invalid threshold"
									message:@"Threshold must be higher or lower than current price"
								   delegate:nil
						  cancelButtonTitle:@"Cancel"
						  otherButtonTitles:nil] show];
		
		// Cleanup
		[_chartController removeThreshold:threshold];
	}
}

- (void) chart:(ChartViewController *)chartControllter didChangeThreshold:(ChartThreshold *)threshold {
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	
	float lastPrice= 0.0;
	@synchronized (self) {
		lastPrice= [[_itemData objectForKey:@"last_price"] floatValue];
	}

	// No need to ask confirm, just proceed
	dispatch_async(_backgroundQueue, ^(){
		[self addOrUpdateMPNSubscriptionForThreshold:threshold greaterThan:(threshold.value > lastPrice)];
	});
}

- (void) chart:(ChartViewController *)chartControllter didRemoveThreshold:(ChartThreshold *)threshold {
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	
	// No need to ask confirm, just proceed
	dispatch_async(_backgroundQueue, ^(){
		[self deleteMPNSubscriptionForThreshold:threshold];
	});
}


#pragma mark -
#pragma mark Properties

@synthesize item= _item;


#pragma mark -
#pragma mark Notifications from notification center

- (void) appDidRegisterForMPN {
	// This method is always called from the main thread
	
	[self enableMPNControls];
}

- (void) appDidUpdateMPNSubscriptionCache {
	dispatch_async(dispatch_get_main_queue(), ^() {
		[self updateViewForMPNStatus];
	});
}


#pragma mark -
#pragma mark Internals

- (void) disableMPNControls {
	
	// Disable UI controls related to MPN
	_detailView.chartBackgroundView.userInteractionEnabled= NO;
	_detailView.chartTipLabel.hidden= YES;
	_detailView.switchTipLabel.enabled= NO;
	_detailView.mpnSwitch.enabled= NO;
}

- (void) enableMPNControls {
	
	// Enable UI controls related to MPN
	_detailView.chartBackgroundView.userInteractionEnabled= YES;
	_detailView.chartTipLabel.hidden= NO;
	_detailView.switchTipLabel.enabled= YES;
	_detailView.mpnSwitch.enabled= YES;
}

- (void) updateView {
	// This method is always called on the main thread
	
	@synchronized (self) {

		// Take current item status from item's data structures
		// and update the view appropriately
		NSString *colorName= [_itemData objectForKey:@"color"];
		UIColor *color= nil;
		if ([colorName isEqualToString:@"green"])
			color= GREEN_COLOR;
		else if ([colorName isEqualToString:@"orange"])
			color= ORANGE_COLOR;
		else
			color= [UIColor whiteColor];

		self.title= [_itemData objectForKey:@"stock_name"];
		
		_detailView.lastLabel.text= [_itemData objectForKey:@"last_price"];
		if ([[_itemUpdated objectForKey:@"last_price"] boolValue]) {
			[SpecialEffects flashLabel:_detailView.lastLabel withColor:color];
			[_itemUpdated setObject:[NSNumber numberWithBool:NO] forKey:@"last_price"];
		}
		
		_detailView.timeLabel.text= [_itemData objectForKey:@"time"];
		if ([[_itemUpdated objectForKey:@"time"] boolValue]) {
			[SpecialEffects flashLabel:_detailView.timeLabel withColor:color];
			[_itemUpdated setObject:[NSNumber numberWithBool:NO] forKey:@"time"];
		}
		
		double pctChange= [[_itemData objectForKey:@"pct_change"] doubleValue];
		if (pctChange > 0.0)
			_detailView.dirImage.image= [UIImage imageNamed:@"Arrow-up.png"];
		else if (pctChange < 0.0)
			_detailView.dirImage.image= [UIImage imageNamed:@"Arrow-down.png"];
		else
			_detailView.dirImage.image= nil;
		
		_detailView.changeLabel.text= [[_itemData objectForKey:@"pct_change"] stringByAppendingString:@"%"];
		_detailView.changeLabel.textColor= (([[_itemData objectForKey:@"pct_change"] doubleValue] >= 0.0) ? DARK_GREEN_COLOR : RED_COLOR);
		
		if ([[_itemUpdated objectForKey:@"pct_change"] boolValue]) {
			[SpecialEffects flashImage:_detailView.dirImage withColor:color];
			[SpecialEffects flashLabel:_detailView.changeLabel withColor:color];
			[_itemUpdated setObject:[NSNumber numberWithBool:NO] forKey:@"pct_change"];
		}
			
		_detailView.minLabel.text= [_itemData objectForKey:@"min"];
		if ([[_itemUpdated objectForKey:@"min"] boolValue]) {
			[SpecialEffects flashLabel:_detailView.minLabel withColor:color];
			[_itemUpdated setObject:[NSNumber numberWithBool:NO] forKey:@"min"];
		}
		
		_detailView.maxLabel.text= [_itemData objectForKey:@"max"];
		if ([[_itemUpdated objectForKey:@"max"] boolValue]) {
			[SpecialEffects flashLabel:_detailView.maxLabel withColor:color];
			[_itemUpdated setObject:[NSNumber numberWithBool:NO] forKey:@"max"];
		}
		
		_detailView.bidLabel.text= [_itemData objectForKey:@"bid"];
		if ([[_itemUpdated objectForKey:@"bid"] boolValue]) {
			[SpecialEffects flashLabel:_detailView.bidLabel withColor:color];
			[_itemUpdated setObject:[NSNumber numberWithBool:NO] forKey:@"bid"];
		}
		
		_detailView.askLabel.text= [_itemData objectForKey:@"ask"];
		if ([[_itemUpdated objectForKey:@"ask"] boolValue]) {
			[SpecialEffects flashLabel:_detailView.askLabel withColor:color];
			[_itemUpdated setObject:[NSNumber numberWithBool:NO] forKey:@"ask"];
		}
		
		_detailView.bidSizeLabel.text= [_itemData objectForKey:@"bid_quantity"];
		if ([[_itemUpdated objectForKey:@"bid_quantity"] boolValue]) {
			[SpecialEffects flashLabel:_detailView.bidSizeLabel withColor:color];
			[_itemUpdated setObject:[NSNumber numberWithBool:NO] forKey:@"bid_quantity"];
		}
		
		_detailView.askSizeLabel.text= [_itemData objectForKey:@"ask_quantity"];
		if ([[_itemUpdated objectForKey:@"ask_quantity"] boolValue]) {
			[SpecialEffects flashLabel:_detailView.askSizeLabel withColor:color];
			[_itemUpdated setObject:[NSNumber numberWithBool:NO] forKey:@"ask_quantity"];
		}

		_detailView.openLabel.text= [_itemData objectForKey:@"open_price"];
		if ([[_itemUpdated objectForKey:@"open_price"] boolValue]) {
			[SpecialEffects flashLabel:_detailView.openLabel withColor:color];
			[_itemUpdated setObject:[NSNumber numberWithBool:NO] forKey:@"open_price"];
		}
	}
}

- (void) addOrUpdateMPNSubscriptionForThreshold:(ChartThreshold *)threshold greaterThan:(BOOL)greaterThan {
	// This method is always called from a background thread

	// Get and keep current item
	NSString *item= nil;
	@synchronized (self) {
		item= _item;
	}
	
	// Prepare the table info
	LSExtendedTableInfo *tableInfo= [LSExtendedTableInfo extendedTableInfoWithItems:[NSArray arrayWithObject:item]
																			   mode:LSModeMerge
																			 fields:DETAIL_FIELDS
																		dataAdapter:DATA_ADAPTER
																		   snapshot:NO];
	
	// Prepare the appropriate MPN info
	LSMPNInfo *mpnInfo= nil;
	if (greaterThan) {
		mpnInfo= [LSMPNInfo mpnInfoWithTableInfo:tableInfo
										   sound:@"Default"
										   badge:@"AUTO"
										  format:@"Stock ${stock_name} rised above ${last_price}"];
		
		// Set the appropriate trigger expression (Java syntax)
		mpnInfo.triggerExpression= [NSString stringWithFormat:@"Double.parseDouble(${last_price}) > %.2f", threshold.value];

	} else {
		mpnInfo= [LSMPNInfo mpnInfoWithTableInfo:tableInfo
										   sound:@"Default"
										   badge:@"AUTO"
										  format:@"Stock ${stock_name} dropped below ${last_price}"];
		
		// Set the appropriate trigger expression (Java syntax)
		mpnInfo.triggerExpression= [NSString stringWithFormat:@"Double.parseDouble(${last_price}) < %.2f", threshold.value];
	}
	
	// Add the custom data to match the subscription against the MPN list
	mpnInfo.customData= [NSDictionary dictionaryWithObjectsAndKeys:
						 item, @"item",
						 [NSString stringWithFormat:@"%.2f", threshold.value], @"threshold",
						 @"${LS_MPN_subscription_ID}", @"subscriptionId",
						 nil];
	
	// Add category for iOS >= 8.0
	mpnInfo.category= @"STOCK_PRICE_CATEGORY";

	@try {
		if (threshold.mpnSubscription) {
			
			// Modify the existing MPN subscription
			[threshold.mpnSubscription modify:mpnInfo];
		
		} else {
			
			// Activate the new MPN subscription
			LSMPNSubscription *mpnSubscription= [[[Connector sharedConnector] client] activateMPN:mpnInfo coalescing:NO];
			threshold.mpnSubscription= mpnSubscription;
		}
	
	} @catch (NSException *e) {
		NSLog(@"DetailViewController: exception caught while activating or modifying MPN subscription: %@", e);

		// Show error alert
		dispatch_async(dispatch_get_main_queue(), ^() {
			[[[UIAlertView alloc] initWithTitle:@"Error while activating MPN subscription"
										message:@"An error occurred and the MPN subscription could not be activated."
									   delegate:nil
							  cancelButtonTitle:@"Cancel"
							  otherButtonTitles:nil] show];
			
			if (threshold.mpnSubscription) {
			
				// Reset the threshold to its previous value
				float oldValue= [[threshold.mpnSubscription.mpnInfo.customData objectForKey:@"threshold"] floatValue];
				threshold.value= oldValue;
				
			} else {

				// Cleanup
				[_chartController removeThreshold:threshold];
			}
		});

	} @finally {
		dispatch_async(dispatch_get_main_queue(), ^(){
			[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
		});
	}
}

- (void) deleteMPNSubscriptionForThreshold:(ChartThreshold *)threshold {
	// This method is always called from a background thread
	
	@try {

		// Delete the MPN subscription
		[threshold.mpnSubscription deactivate];
		
    } @catch (NSException *e) {
		NSLog(@"DetailViewController: exception caught while deactivating MPN subscription: %@", e);
		
	} @finally {
		dispatch_async(dispatch_get_main_queue(), ^(){
			[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
		});
	}
}


@end
