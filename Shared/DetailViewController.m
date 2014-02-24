//
//  DetailViewController.m
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

#import "DetailViewController.h"
#import "DetailView.h"
#import "ChartViewController.h"
#import "StockListAppDelegate.h"
#import "StockListViewController.h"
#import "Connector.h"
#import "Storage.h"
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

- (void) createNewMPNSubscriptionWhenGreaterThan:(BOOL)greaterThan value:(float)value withIndex:(int)index;
- (void) updateMPNSubscriptionWithIndex:(int)index whenGreaterThan:(BOOL)greaterThan value:(float)value;
- (void) deleteMPNSubscriptionWithIndex:(int)index;


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
	// has been successfully registered for MPN
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidRegisterForMPN) name:NOTIFICATION_APP_MPN object:nil];
	
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
	
	// Get and keep current item
	NSString *item= nil;
	@synchronized (self) {
		item= _item;
	}

	// Set the view according to known status
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	
	// Disable interaction until the real status has beeen checked
	[self disableMPNControls];
	
	// Clear thresholds on the chart
	[_chartController clearThresholds];
	
	// Add thresholds according to their known status
	NSArray *thresholdValues= [[Storage sharedStorage] thresholdValuesForItem:item];
	for (NSNumber *value in thresholdValues)
		[_chartController addThreshold:[value floatValue]];
	
	// Set MPN switch according to its known status
	_detailView.mpnSwitch.on= [[Storage sharedStorage] isMPNActiveForItem:item];
	
	// Check real status of MPN subscriptions in background
	dispatch_async(_backgroundQueue, ^{
		if ([[Storage sharedStorage] isMPNActiveForItem:item]) {
			
			// Check if the main MPN subscription is actually active
			LSMPNKey *mpnKey= [[Storage sharedStorage] MPNKeyForItem:item];
			
			@try {
				LSMPNStatus status= [[[Connector sharedConnector] client] inquireMPNStatus:mpnKey];
				switch (status) {
					case LSMPNStatusActive:
						
						// MPN subscription is active
						break;
						
					case LSMPNStatusSuspended:
						
						// MPN subscription has been suspended, a token change is pending
						break;
						
					default:
						break;
				}

			} @catch (LSPushServerException *pse) {
				if ((pse.errorCode == 46) || (pse.errorCode == 45)) {
					
					// MPN subscription has been deleted
					[[Storage sharedStorage] clearMPNKeyForItem:item];
				
				} else
					NSLog(@"DetailViewController: exception caught while inquiring status of MPN subscription: %@", pse);
				
			} @catch (NSException *e) {
				NSLog(@"DetailViewController: exception caught while inquiring status of MPN subscription: %@", e);
			}
		}
		
		// Check existing thresholds, they may have triggered in the background
		NSArray *mpnKeys= [[Storage sharedStorage] thresholdMPNKeysForItem:item];
		for (LSMPNKey *mpnKey in mpnKeys) {
			@try {
				LSMPNStatus status= [[[Connector sharedConnector] client] inquireMPNStatus:mpnKey];
				switch (status) {
					case LSMPNStatusActive:
						
						// MPN subscription is active and non-triggered
						break;
						
					case LSMPNStatusTriggered: {
						
						// MPN subscription did trigger, delete its threshold
						int index= [[Storage sharedStorage] indexOfThresholdWithMPNKey:mpnKey forItem:item];
						[[Storage sharedStorage] deleteThresholdAtIndex:index forItem:item];
						
						// Delete also the MPN subscription
						@try {
							[[[Connector sharedConnector] client] deactivateMPN:mpnKey];
							
						} @catch (NSException *e) {
							NSLog(@"DetailViewController: exception caught while deactivating MPN subscription: %@", e);
						}
						break;
					}
						
					case LSMPNStatusSuspended:
						
						// MPN subscription has been suspended, a token change is pending
						break;
						
					default:
						break;
				}
				
			} @catch (LSPushServerException *pse) {
				if ((pse.errorCode == 46) || (pse.errorCode == 45)) {
					
					// MPN subscription has been forcibly deleted on the Server
					int index= [[Storage sharedStorage] indexOfThresholdWithMPNKey:mpnKey forItem:item];
					[[Storage sharedStorage] deleteThresholdAtIndex:index forItem:item];
					
				} else
					NSLog(@"DetailViewController: exception caught while inquiring status of MPN subscription: %@", pse);

			} @catch (NSException *e) {
				NSLog(@"DetailViewController: exception caught while inquiring status of MPN subscription trigger: %@", e);
			}
			
		}
		
		// Check if we are still on the same item
		@synchronized (self) {
			if (![item isEqualToString:_item])
				return;
		}
		
		// Update the view again according to real status
		dispatch_async(dispatch_get_main_queue(), ^(){
			[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
			
			// Enable interaction
			[self enableMPNControls];

			// Clear thresholds on the chart
			[_chartController clearThresholds];
			
			// Add thresholds according to their real status
			NSArray *thresholdValues= [[Storage sharedStorage] thresholdValuesForItem:item];
			for (NSNumber *value in thresholdValues)
				[_chartController addThreshold:[value floatValue]];
			
			// Set MPN switch according to its real status
			_detailView.mpnSwitch.on= [[Storage sharedStorage] isMPNActiveForItem:item];
		});
	});
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
			LSMPNInfo *mpnInfo= [LSMPNInfo mpnInfoWithSound:@"Default"
													  badge:@"AUTO"
													 format:@"Stock ${stock_name} is now ${last_price}"];
			
			// Add the item name to match the MPN against the item list
			mpnInfo.customData= [NSDictionary dictionaryWithObjectsAndKeys:item, @"item", nil];
			
			@try {
				
				// Activate the new MPN subscription
				LSMPNKey *mpnKey= [[[Connector sharedConnector] client] activateMPNForTable:tableInfo withInfo:mpnInfo];

				// Save it on the app's storage
				[[Storage sharedStorage] setMPNKey:mpnKey forItem:item];
				
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
			
			// Retrieve the MPN key
			LSMPNKey *mpnKey= [[Storage sharedStorage] MPNKeyForItem:item];

			@try {
				
				// Delete the MPN subscription
				[[[Connector sharedConnector] client] deactivateMPN:mpnKey];
				
				// Remove it from the app's storage
				[[Storage sharedStorage] clearMPNKeyForItem:item];
				
			} @catch (LSPushServerException *pse) {
				if ((pse.errorCode == 46) || (pse.errorCode == 45)) {
					
					// MPN subscription has been forcibly deleted on the Server
					[[Storage sharedStorage] clearMPNKeyForItem:item];
					
				} else {
					NSLog(@"DetailViewController: exception caught while deactivating MPN subscription: %@", pse);
					
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
				}

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

- (void) chart:(ChartViewController *)chartControllter didAddThresholdWithIndex:(int)index value:(float)value {
	float lastPrice= 0.0;
	@synchronized (self) {
		lastPrice= [[_itemData objectForKey:@"last_price"] floatValue];
	}
	
	if (value > lastPrice) {

		// The threshold is higher than current price,
		// ask confirm with the appropriate alert view
		[[[UIAlertView alloc] initWithTitle:@"Add alert on threshold"
									message:[NSString stringWithFormat:@"Confirm adding a notification alert when %@ rises over %.2f", self.title, value]
							completionBlock:^(NSUInteger buttonIndex, UIAlertView *alertView) {
								switch (buttonIndex) {
									case 0:
										 
										// Cleanup
										[_chartController removeThresholdAtIndex:index];
										break;

									case 1:
										[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
										 
										// Proceed
										dispatch_async(_backgroundQueue, ^() {
											[self createNewMPNSubscriptionWhenGreaterThan:YES value:value withIndex:index];
										});
										break;
								}
							}
						  cancelButtonTitle:@"Cancel"
						  otherButtonTitles:@"Proceed", nil] show];

	} else if (value < lastPrice) {
		
		// The threshold is lower than current price,
		// ask confirm with the appropriate alert view
		[[[UIAlertView alloc] initWithTitle:@"Add alert on threshold"
									message:[NSString stringWithFormat:@"Confirm adding a notification alert when %@ lowers below %.2f", self.title, value]
							completionBlock:^(NSUInteger buttonIndex, UIAlertView *alertView) {
								switch (buttonIndex) {
									case 0:
										 
										// Cleanup
										[_chartController removeThresholdAtIndex:index];
										break;
										 
									case 1:
										[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
										 
										// Proceed
										dispatch_async(_backgroundQueue, ^() {
											[self createNewMPNSubscriptionWhenGreaterThan:NO value:value withIndex:index];
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
		[_chartController removeThresholdAtIndex:index];
	}
}

- (void) chart:(ChartViewController *)chartControllter didChangeThresholdWithIndex:(int)index newValue:(float)value {
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	
	float lastPrice= 0.0;
	@synchronized (self) {
		lastPrice= [[_itemData objectForKey:@"last_price"] floatValue];
	}

	// No need to ask confirm, just proceed
	dispatch_async(_backgroundQueue, ^(){
		[self updateMPNSubscriptionWithIndex:index whenGreaterThan:(value > lastPrice) value:value];
	});
}

- (void) chart:(ChartViewController *)chartControllter didRemoveThresholdWithIndex:(int)index {
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	
	// No need to ask confirm, just proceed
	dispatch_async(_backgroundQueue, ^(){
		[self deleteMPNSubscriptionWithIndex:index];
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

- (void) createNewMPNSubscriptionWhenGreaterThan:(BOOL)greaterThan value:(float)value withIndex:(int)index {
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
		mpnInfo= [LSMPNInfo mpnInfoWithSound:@"Default"
									   badge:@"AUTO"
									  format:@"Stock ${stock_name} rised over ${last_price}"];
		
		// Set the appropriate trigger expression (Java syntax)
		mpnInfo.triggerExpression= [NSString stringWithFormat:@"Double.parseDouble(${last_price}) > %.2f", value];

	} else {
		mpnInfo= [LSMPNInfo mpnInfoWithSound:@"Default"
									   badge:@"AUTO"
									  format:@"Stock ${stock_name} dropped below ${last_price}"];
		
		// Set the appropriate trigger expression (Java syntax)
		mpnInfo.triggerExpression= [NSString stringWithFormat:@"Double.parseDouble(${last_price}) < %.2f", value];
	}
	
	// Add the item name to match the MPN against the item list,
	// and the subscription ID to remove the threshold when triggered
	mpnInfo.customData= [NSDictionary dictionaryWithObjectsAndKeys:
						 item, @"item",
						 @"${LS_MPN_subscription_ID}", @"subscriptionId",
						 nil];

	@try {
		
		// Activate the new MPN subscription
		LSMPNKey *mpnKey= [[[Connector sharedConnector] client] activateMPNForTable:tableInfo withInfo:mpnInfo];

		// Add the MPN key on the app's storage
		[[Storage sharedStorage] addThresholdValue:value MPNKey:mpnKey forItem:item];
	
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
			[_chartController removeThresholdAtIndex:index];
		});

	} @finally {
		dispatch_async(dispatch_get_main_queue(), ^(){
			[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
		});
	}
}

- (void) updateMPNSubscriptionWithIndex:(int)index whenGreaterThan:(BOOL)greaterThan value:(float)value {
	// This method is always called from a background thread
	
	// Get and keep current item
	NSString *item= nil;
	@synchronized (self) {
		item= _item;
	}

	// Retrieve the MPN key from the app's storage
	LSMPNKey *mpnKey= [[Storage sharedStorage] MPNKeyOfThresholdAtIndex:index forItem:item];
	
	@try {
		
		// First delete the old MPN subscription
		[[[Connector sharedConnector] client] deactivateMPN:mpnKey];
		
	} @catch (LSPushServerException *pse) {
		if ((pse.errorCode == 46) || (pse.errorCode == 45)) {
			// MPN subscription has been forcibly deleted on the Server,
			// nothing else to do

		} else {
			NSLog(@"DetailViewController: exception caught while deactivating MPN subscription during an update: %@", pse);
			
			// Show error alert
			dispatch_async(dispatch_get_main_queue(), ^() {
				[[[UIAlertView alloc] initWithTitle:@"Error while updating MPN subscription"
											message:@"An error occurred and the MPN subscription could not be updated."
										   delegate:nil
								  cancelButtonTitle:@"Cancel"
								  otherButtonTitles:nil] show];
				
				// Reset the threshold to its previous value
				float oldValue= [[Storage sharedStorage] valueOfThresholdAtIndex:index forItem:item];
				[_chartController setThreshold:oldValue atIndex:index];

				[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
			});

			// Early bail
			return;
		}

	} @catch (NSException *e) {
		NSLog(@"DetailViewController: exception caught while deactivating MPN subscription during an update: %@", e);
		
		// Show error alert
		dispatch_async(dispatch_get_main_queue(), ^() {
			[[[UIAlertView alloc] initWithTitle:@"Error while updating MPN subscription"
										message:@"An error occurred and the MPN subscription could not be updated."
									   delegate:nil
							  cancelButtonTitle:@"Cancel"
							  otherButtonTitles:nil] show];
			
			// Reset the threshold to its previous value
			float oldValue= [[Storage sharedStorage] valueOfThresholdAtIndex:index forItem:item];
			[_chartController setThreshold:oldValue atIndex:index];
			
			[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
		});

		// Early bail
		return;
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
		mpnInfo= [LSMPNInfo mpnInfoWithSound:@"Default"
									   badge:@"AUTO"
									  format:@"Stock ${stock_name} rised above ${last_price}"];

		
		// Set the appropriate trigger expression (Java syntax)
		mpnInfo.triggerExpression= [NSString stringWithFormat:@"Double.parseDouble(${last_price}) > %.2f", value];
		
	} else {
		mpnInfo= [LSMPNInfo mpnInfoWithSound:@"Default"
									   badge:@"AUTO"
									  format:@"Stock ${stock_name} just dropped below ${last_price}"];
		
		// Set the appropriate trigger expression (Java syntax)
		mpnInfo.triggerExpression= [NSString stringWithFormat:@"Double.parseDouble(${last_price}) < %.2f", value];
	}
	
	// Add the item name to match the MPN against the item list,
	// and the subscription ID to remove the threshold when triggered
	mpnInfo.customData= [NSDictionary dictionaryWithObjectsAndKeys:
						 item, @"item",
						 @"${LS_MPN_subscription_ID}", @"subscriptionId",
						 nil];
		
	@try {

		// Activate the new MPN subscription
		mpnKey= [[[Connector sharedConnector] client] activateMPNForTable:tableInfo withInfo:mpnInfo];
		
		// Update the value and MPN key on app's storage
		[[Storage sharedStorage] updateThresholdValue:value MPNKey:mpnKey atIndex:index forItem:item];
	
	} @catch (NSException *e) {
		NSLog(@"DetailViewController: exception caught while activating MPN subscription during an update: %@", e);
		
		// Show error alert
		dispatch_async(dispatch_get_main_queue(), ^() {
			[[[UIAlertView alloc] initWithTitle:@"Error while updating MPN subscription"
										message:@"An error occurred and the MPN subscription could not be updated."
									   delegate:nil
							  cancelButtonTitle:@"Cancel"
							  otherButtonTitles:nil] show];
			
			// Remove the threshold
			[_chartController removeThresholdAtIndex:index];
		});
		
		// Remove the threshold from the app's storage
		[[Storage sharedStorage] deleteThresholdAtIndex:index forItem:item];

	} @finally {
		dispatch_async(dispatch_get_main_queue(), ^(){
			[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
		});
	}
}

- (void) deleteMPNSubscriptionWithIndex:(int)index {
	// This method is always called from a background thread
	
	// Get and keep current item
	NSString *item= nil;
	@synchronized (self) {
		item= _item;
	}

	// Retrieve the MPN key from the app's storage
	LSMPNKey *mpnKey= [[Storage sharedStorage] MPNKeyOfThresholdAtIndex:index forItem:item];
	
	@try {

		// Delete the MPN subscription
		[[[Connector sharedConnector] client] deactivateMPN:mpnKey];
		
		// Remove the threshold from the app's storage
		[[Storage sharedStorage] deleteThresholdAtIndex:index forItem:item];
		
	} @catch (LSPushServerException *pse) {
		if ((pse.errorCode == 46) || (pse.errorCode == 45)) {
			
			// MPN subscription has been forcibly deleted on the Server
			[[Storage sharedStorage] deleteThresholdAtIndex:index forItem:item];
			
		} else
			NSLog(@"DetailViewController: exception caught while deactivating MPN subscription: %@", pse);

	} @catch (NSException *e) {
		NSLog(@"DetailViewController: exception caught while deactivating MPN subscription: %@", e);
		
	} @finally {
		dispatch_async(dispatch_get_main_queue(), ^(){
			[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
		});
	}
}


@end
