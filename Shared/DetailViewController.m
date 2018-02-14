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

- (void) viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

	// Reset size of chart
	[_chartController.view setFrame:CGRectMake(0.0, 0.0, _detailView.chartBackgroundView.frame.size.width, _detailView.chartBackgroundView.frame.size.height)];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
		
	// We use the notification center to know when the app
	// has been successfully registered for MPN and when
	// the MPN subscription cache has been updated
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidRegisterForMPN) name:NOTIFICATION_MPN_ENABLED object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidUpdateMPNSubscriptionCache) name:NOTIFICATION_MPN_UPDATED object:nil];
    
    // Check if registration for MPN has already been completed
    if ([[Connector sharedConnector] isMpnEnabled])
        [self enableMPNControls];
}

- (void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
	
	// Unregister from control center notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_MPN_UPDATED object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_MPN_ENABLED object:nil];

	// Unsubscribe the table
	if (_subscription) {
        NSLog(@"DetailViewController: unsubscribing previous table...");
        
        [[Connector sharedConnector] unsubscribe:_subscription];
        
        _subscription= nil;
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
	
    // If needed, unsubscribe previous table
    if (_subscription) {
        NSLog(@"DetailViewController: unsubscribing previous table...");
        
        [[Connector sharedConnector] unsubscribe:_subscription];
        _subscription= nil;
    }
    
    // Subscribe new single-item table
    if (item) {
        NSLog(@"DetailViewController: subscribing table...");
        
        // The LSLightstreamerClient will reconnect and resubscribe automatically
        _subscription= [[LSSubscription alloc] initWithSubscriptionMode:@"MERGE" items:@[item] fields:DETAIL_FIELDS];
        _subscription.dataAdapter= DATA_ADAPTER;
        _subscription.requestedSnapshot= @"yes";
        [_subscription addDelegate:self];
        
        [[Connector sharedConnector] subscribe:_subscription];
    }
}

- (void) updateViewForMPNStatus {
	// This method is always called from the main thread
	
	// Clear thresholds on the chart
	_detailView.mpnSwitch.on= NO;
	[_chartController clearThresholds];

	// Early bail
	if (!_item)
		return;
    
    // Early bail
    if (![[Connector sharedConnector] isMpnEnabled])
        return;
	
	// Update view according to cached MPN subscriptions
	NSArray *mpnSubscriptions= [[Connector sharedConnector] MPNSubscriptions];
	for (LSMPNSubscription *mpnSubscription in mpnSubscriptions) {
        LSMPNBuilder *builder= [[LSMPNBuilder alloc] initWithNotificationFormat:mpnSubscription.notificationFormat];
		NSString *item= [builder.customData objectForKey:@"item"];
		if (![_item isEqualToString:item])
			continue;
		
        NSString *threshold= [builder.customData objectForKey:@"threshold"];
        if (threshold) {

            // MPN subscription is a threshold, we show it
            // only if it has not yet triggered
            if (![mpnSubscription.status isEqualToString:@"TRIGGERED"]) {
                ChartThreshold *chartThreshold= [_chartController addThreshold:[threshold floatValue]];
                chartThreshold.mpnSubscription= mpnSubscription;
            }
			
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
	
	// Get and keep current item
	NSString *item= nil;
	@synchronized (self) {
		item= _item;
	}

    if (_detailView.mpnSwitch.on) {
        if (_priceMpnSubscription) {
            
            // Delete the MPN subscription
            [[Connector sharedConnector] unsubscribeMPN:_priceMpnSubscription];
            _priceMpnSubscription= nil;
        }

        // Prepare the notification format, with a custom data
        // to match the item against the MPN list
        LSMPNBuilder *builder= [[LSMPNBuilder alloc] init];
        [builder body:@"Stock ${stock_name} is now ${last_price}"];
        [builder sound:@"Default"];
        [builder badgeWithString:@"AUTO"];
        [builder customData:@{@"item": item,
                              @"stock_name": @"${stock_name}",
                              @"last_price": @"${last_price}",
                              @"pct_change": @"${pct_change}",
                              @"time": @"${time}",
                              @"open_price": @"${open_price}"}];
        [builder category:@"STOCK_PRICE_CATEGORY"];

        // Prepare the MPN subscription
        _priceMpnSubscription= [[LSMPNSubscription alloc] initWithSubscriptionMode:@"MERGE" item:item fields:DETAIL_FIELDS];
        _priceMpnSubscription.dataAdapter= DATA_ADAPTER;
        _priceMpnSubscription.notificationFormat= [builder build];
        [_priceMpnSubscription addDelegate:self];

        [[Connector sharedConnector] subscribeMPN:_priceMpnSubscription];
    
    } else {
        if (_priceMpnSubscription) {
        
            // Delete the MPN subscription
            [[Connector sharedConnector] unsubscribeMPN:_priceMpnSubscription];
            _priceMpnSubscription= nil;
        }
    }
}


#pragma mark -
#pragma mark Methods of LSSubscriptionDelegate

- (void) subscription:(nonnull LSSubscription *)subscription didUpdateItem:(nonnull LSItemUpdate *)itemUpdate {
	// This method is always called from a background thread
	
    NSString *itemName= itemUpdate.itemName;

    @synchronized (self) {
		
		// Check if it is a late update of the previous table
		if (![_item isEqualToString:itemName])
			return;
		
        double previousLastPrice= 0.0;
		for (NSString *fieldName in DETAIL_FIELDS) {
			
            // Save previous last price to choose blick color later
            if ([fieldName isEqualToString:@"last_price"])
                previousLastPrice= [[_itemData objectForKey:fieldName] doubleValue];
            
            // Store the updated field in the item's data structures
            NSString *value= [itemUpdate valueWithFieldName:fieldName];

            if (value)
				[_itemData setObject:value forKey:fieldName];
			else
				[_itemData setObject:[NSNull null] forKey:fieldName];
			
			if ([itemUpdate isValueChangedWithFieldName:fieldName])
				[_itemUpdated setObject:[NSNumber numberWithBool:YES] forKey:fieldName];
		}
		
		double currentLastPrice= [[itemUpdate valueWithFieldName:@"last_price"] doubleValue];
		if (currentLastPrice >= previousLastPrice)
			[_itemData setObject:@"green" forKey:@"color"];
		else
			[_itemData setObject:@"orange" forKey:@"color"];
	}
	
	dispatch_async(dispatch_get_main_queue(), ^{

		// Forward the update to the chart
		[_chartController itemDidUpdate:itemUpdate];
		
		// Update the view
		[self updateView];
	});
}


#pragma mark -
#pragma mark methods of LSMPNSubscriptionDelegate

- (void) mpnSubscriptionDidSubscribe:(LSMPNSubscription *)subscription {
    // This method is always called from a background thread
    
    NSLog(@"DetailViewController: activation of MPN subscription succeeded");
}

- (void) mpnSubscription:(LSMPNSubscription *)subscription didFailSubscriptionWithErrorCode:(NSInteger)code message:(NSString *)message {
    // This method is always called from a background thread
    
    NSLog(@"DetailViewController: error while activating MPN subscription: %ld - %@", (long) code, message);
    
    // Show error alert
    LSMPNSubscription *mpnSubscription= (LSMPNSubscription *) subscription;
    dispatch_async(dispatch_get_main_queue(), ^() {
        [[[UIAlertView alloc] initWithTitle:@"Error while activating MPN subscription"
                                    message:@"An error occurred and the MPN subscription could not be activated."
                                   delegate:nil
                          cancelButtonTitle:@"Cancel"
                          otherButtonTitles:nil] show];
        
        LSMPNBuilder *builder= [[LSMPNBuilder alloc] initWithNotificationFormat:mpnSubscription.notificationFormat];
        if ([builder.customData objectForKey:@"threshold"]) {
            
            // It's the subscription of a threshold, remove it if still present
            ChartThreshold *threshold= [_chartController findThreshold:[[builder.customData objectForKey:@"threshold"] floatValue]];
            if (threshold)
                [_chartController removeThreshold:threshold];

        } else {
            
            // It's the main price subscription, reset the switch
            _priceMpnSubscription= nil;
            _detailView.mpnSwitch.on= NO;
        }
    });
}


#pragma mark -
#pragma mark ChartViewDelegate methods

- (void) chart:(ChartViewController *)chartControllter didAddThreshold:(ChartThreshold *)threshold {
    // This method is always called from the main thread

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
										 
										// Proceed
                                        [self addOrUpdateMPNSubscriptionForThreshold:threshold greaterThan:YES];
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
										 
										// Proceed
                                        [self addOrUpdateMPNSubscriptionForThreshold:threshold greaterThan:NO];
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
    // This method is always called from the main thread

    float lastPrice= 0.0;

    @synchronized (self) {
		lastPrice= [[_itemData objectForKey:@"last_price"] floatValue];
	}

	// No need to ask confirm, just proceed
    [self addOrUpdateMPNSubscriptionForThreshold:threshold greaterThan:(threshold.value > lastPrice)];
}

- (void) chart:(ChartViewController *)chartControllter didRemoveThreshold:(ChartThreshold *)threshold {
    // This method is always called from the main thread

	// No need to ask confirm, just proceed
    [self deleteMPNSubscriptionForThreshold:threshold];
}


#pragma mark -
#pragma mark Properties

@synthesize item= _item;


#pragma mark -
#pragma mark Notifications from notification center

- (void) appDidRegisterForMPN {
    dispatch_async(dispatch_get_main_queue(), ^() {
        [self enableMPNControls];
    });
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
			_detailView.dirImage.image= [UIImage imageNamed:@"Arrow-up"];
		else if (pctChange < 0.0)
			_detailView.dirImage.image= [UIImage imageNamed:@"Arrow-down"];
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
	// This method is always called from the main thread

	// Get and keep current item
	NSString *item= nil;
	@synchronized (self) {
		item= _item;
	}
    
    // Prepare the notification format, with a custom data
    // to match the item and threshold against the MPN list
    LSMPNBuilder *builder= [[LSMPNBuilder alloc] init];
    [builder body:[NSString stringWithFormat:greaterThan ? @"Stock ${stock_name} rised above %.2f" : @"Stock ${stock_name} dropped below %.2f", threshold.value]];
    [builder sound:@"Default"];
    [builder badgeWithString:@"AUTO"];
    [builder customData:@{@"item": item,
                          @"stock_name": @"${stock_name}",
                          @"last_price": @"${last_price}",
                          @"pct_change": @"${pct_change}",
                          @"time": @"${time}",
                          @"open_price": @"${open_price}",
                          @"threshold": [NSString stringWithFormat:@"%.2f", threshold.value],
                          @"subID": @"${LS_MPN_subscription_ID}"}];
    [builder category:@"STOCK_PRICE_CATEGORY"];
    
    NSString *trigger= [NSString stringWithFormat:@"Double.parseDouble(${last_price}) %@ %.2f", (greaterThan ? @">" : @"<"), threshold.value];
    NSLog(@"DetailViewController: subscribing MPN with trigger expression: %@", trigger);
    
    // Prepare the MPN subscription
    LSMPNSubscription *mpnSubscription= [[LSMPNSubscription alloc] initWithSubscriptionMode:@"MERGE" item:item fields:DETAIL_FIELDS];
    mpnSubscription.dataAdapter= DATA_ADAPTER;
    mpnSubscription.notificationFormat= [builder build];
    mpnSubscription.triggerExpression= trigger;
    [mpnSubscription addDelegate:self];

    // Delete the existing MPN subscription, if present
    if (threshold.mpnSubscription)
        [[Connector sharedConnector] unsubscribeMPN:threshold.mpnSubscription];
    
    // Activate the new MPN subscription
    [[Connector sharedConnector] subscribeMPN:mpnSubscription];
    threshold.mpnSubscription= mpnSubscription;
}

- (void) deleteMPNSubscriptionForThreshold:(ChartThreshold *)threshold {
	// This method is always called from the main thread
	
    // Delete the existing MPN subscription, if present
    if (threshold.mpnSubscription)
        [[Connector sharedConnector] unsubscribeMPN:threshold.mpnSubscription];
}


@end
