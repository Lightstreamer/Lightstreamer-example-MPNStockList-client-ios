//
//  Storage.m
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

#import "Storage.h"

#define KEY_ITEM_MPN_ACTIVE        (@"LSItemMPNActive")
#define KEY_ITEM_MPN_SUB_ID        (@"LSItemMPNSubscriptionId")
#define KEY_THRESHOLD_MPN_VALUES   (@"LSThresholdMPNValues")
#define KEY_THRESHOLD_MPN_SUB_IDS  (@"LSThresholdMPNSubscriptionIds")


#pragma mark -
#pragma mark Storage extension

@interface Storage ()


#pragma mark -
#pragma mark Internals

- (void) fetchDataForItem:(NSString *)item;
- (void) storeData;


@end



#pragma mark -
#pragma mark Storage implementation

static Storage *__sharedInstace= nil;

@implementation Storage


#pragma mark -
#pragma mark Singleton access

+ (Storage *) sharedStorage {
	if (!__sharedInstace) {
		@synchronized ([Storage class]) {
			if (!__sharedInstace)
				__sharedInstace= [[Storage alloc] init];
		}
	}
	
	return __sharedInstace;
}


#pragma mark -
#pragma mark Initialization

- (id) init {
	if ((self = [super init])) {
		
		// Nothing to do
	}
	
	return self;
}


#pragma mark -
#pragma mark Operations on item's MPN subscription

- (BOOL) isMPNActiveForItem:(NSString *)item {
	@synchronized (self) {
	
		// Fetch item data, if necessary
		if (![_currentItem isEqualToString:item])
			[self fetchDataForItem:item];
		
		// Retrive status of item's MPN subscription
		return [[_currentItemData objectForKey:KEY_ITEM_MPN_ACTIVE] boolValue];
	}
}

- (LSMPNKey *) MPNKeyForItem:(NSString *)item {
	@synchronized (self) {
	
		// Fetch item data, if necessary
		if (![_currentItem isEqualToString:item])
			[self fetchDataForItem:item];
		
		// Retrive the subscription ID of item's MPN subscription
		NSString *subscriptionId= [_currentItemData objectForKey:KEY_ITEM_MPN_SUB_ID];
		if (!subscriptionId)
			return nil;

		// Wrap the subscription ID in an MPN key
		return [LSMPNKey mpnKeyWithSubscriptionId:subscriptionId];
	}
}

- (void) setMPNKey:(LSMPNKey *)mpnKey forItem:(NSString *)item {
	NSLog(@"Storage: setting MPN for item %@...", item);

	@synchronized (self) {
	
		// Fetch item data, if necessary
		if (![_currentItem isEqualToString:item])
			[self fetchDataForItem:item];

		// Update item's MPN subscription data
		[_currentItemData setObject:[NSNumber numberWithBool:YES] forKey:KEY_ITEM_MPN_ACTIVE];
		[_currentItemData setObject:mpnKey.subscriptionId forKey:KEY_ITEM_MPN_SUB_ID];
		
		// Store item data
		[self storeData];
	}
}

- (void) clearMPNKeyForItem:(NSString *)item {
	NSLog(@"Storage: clearing MPN for item %@...", item);

	@synchronized (self) {
	
		// Fetch item data, if necessary
		if (![_currentItem isEqualToString:item])
			[self fetchDataForItem:item];
		
		// Update item's MPN subscription data
		[_currentItemData setObject:[NSNumber numberWithBool:NO] forKey:KEY_ITEM_MPN_ACTIVE];
		[_currentItemData removeObjectForKey:KEY_ITEM_MPN_SUB_ID];
		
		// Store item data
		[self storeData];
	}
}


#pragma mark -
#pragma mark Operations on item thresholds' MPN subscriptions

- (NSArray *) thresholdValuesForItem:(NSString *)item {
	@synchronized (self) {
	
		// Fetch item data, if necessary
		if (![_currentItem isEqualToString:item])
			[self fetchDataForItem:item];
		
		// Retrieve the list of threshold values
		return [[_currentItemData objectForKey:KEY_THRESHOLD_MPN_VALUES] copy];
	}
}

- (NSArray *) thresholdMPNKeysForItem:(NSString *)item {
	@synchronized (self) {
		
		// Fetch item data, if necessary
		if (![_currentItem isEqualToString:item])
			[self fetchDataForItem:item];
		
		// Retrieve the list of threshold subscription IDs
		NSArray *thresholdSubIds= [NSMutableArray arrayWithArray:[_currentItemData objectForKey:KEY_THRESHOLD_MPN_SUB_IDS]];
		
		// Create a list of MPN keys
		NSMutableArray *thresholdMPNKeys= [NSMutableArray array];
		for (NSString *subId in thresholdSubIds)
			[thresholdMPNKeys addObject:[LSMPNKey mpnKeyWithSubscriptionId:subId]];
		
		return thresholdMPNKeys;
	}
}

- (float) valueOfThresholdAtIndex:(int)index forItem:(NSString *)item {
	@synchronized (self) {
		
		// Fetch item data, if necessary
		if (![_currentItem isEqualToString:item])
			[self fetchDataForItem:item];
		
		// Retrieve the MPN key
		NSArray *thresholdValues= [NSMutableArray arrayWithArray:[_currentItemData objectForKey:KEY_THRESHOLD_MPN_VALUES]];
		return [[thresholdValues objectAtIndex:index] floatValue];
	}
}

- (LSMPNKey *) MPNKeyOfThresholdAtIndex:(int)index forItem:(NSString *)item {
	@synchronized (self) {
	
		// Fetch item data, if necessary
		if (![_currentItem isEqualToString:item])
			[self fetchDataForItem:item];
		
		// Retrieve the MPN key
		NSArray *thresholdSubIds= [NSMutableArray arrayWithArray:[_currentItemData objectForKey:KEY_THRESHOLD_MPN_SUB_IDS]];
		return [LSMPNKey mpnKeyWithSubscriptionId:[thresholdSubIds objectAtIndex:index]];
	}
}

- (int) indexOfThresholdWithMPNKey:(LSMPNKey *)mpnKey forItem:(NSString *)item {
	@synchronized (self) {
		
		// Fetch item data, if necessary
		if (![_currentItem isEqualToString:item])
			[self fetchDataForItem:item];
		
		// Search the MPN key
		NSArray *thresholdSubIds= [NSMutableArray arrayWithArray:[_currentItemData objectForKey:KEY_THRESHOLD_MPN_SUB_IDS]];
		return [thresholdSubIds indexOfObject:mpnKey.subscriptionId];
	}
}

- (void) addThresholdValue:(float)value MPNKey:(LSMPNKey *)mpnKey forItem:(NSString *)item {
	NSLog(@"Storage: adding threshold with value %.2f to item %@...", value, item);

	@synchronized (self) {
	
		// Fetch item data, if necessary
		if (![_currentItem isEqualToString:item])
			[self fetchDataForItem:item];
		
		// Retrieve and update the list of threshold values and MPN keys
		NSMutableArray *thresholdValues= [NSMutableArray arrayWithArray:[_currentItemData objectForKey:KEY_THRESHOLD_MPN_VALUES]];
		NSMutableArray *thresholdSubIds= [NSMutableArray arrayWithArray:[_currentItemData objectForKey:KEY_THRESHOLD_MPN_SUB_IDS]];
		
		[thresholdValues addObject:[NSNumber numberWithFloat:value]];
		[thresholdSubIds addObject:mpnKey.subscriptionId];
		
		[_currentItemData setObject:thresholdValues forKey:KEY_THRESHOLD_MPN_VALUES];
		[_currentItemData setObject:thresholdSubIds forKey:KEY_THRESHOLD_MPN_SUB_IDS];
		
		// Store item data
		[self storeData];
	}
}

- (void) updateThresholdValue:(float)value MPNKey:(LSMPNKey *)mpnKey atIndex:(int)index forItem:(NSString *)item {
	NSLog(@"Storage: updating threshold with value %.2f at index %d of item %@...", value, index, item);
	
	@synchronized (self) {
	
		// Fetch item data, if necessary
		if (![_currentItem isEqualToString:item])
			[self fetchDataForItem:item];
		
		// Retrieve and update the list of threshold values and MPN keys
		NSMutableArray *thresholdValues= [NSMutableArray arrayWithArray:[_currentItemData objectForKey:KEY_THRESHOLD_MPN_VALUES]];
		NSMutableArray *thresholdSubIds= [NSMutableArray arrayWithArray:[_currentItemData objectForKey:KEY_THRESHOLD_MPN_SUB_IDS]];
		
		[thresholdValues setObject:[NSNumber numberWithFloat:value] atIndexedSubscript:index];
		[thresholdSubIds setObject:mpnKey.subscriptionId atIndexedSubscript:index];
		
		[_currentItemData setObject:thresholdValues forKey:KEY_THRESHOLD_MPN_VALUES];
		[_currentItemData setObject:thresholdSubIds forKey:KEY_THRESHOLD_MPN_SUB_IDS];
		
		// Store item data
		[self storeData];
	}
}

- (void) deleteThresholdAtIndex:(int)index forItem:(NSString *)item {
	NSLog(@"Storage: deleting threshold at index %d of item %@...", index, item);

	@synchronized (self) {
	
		// Fetch item data, if necessary
		if (![_currentItem isEqualToString:item])
			[self fetchDataForItem:item];
		
		// Retrieve and update the list of threshold values and MPN keys
		NSMutableArray *thresholdValues= [NSMutableArray arrayWithArray:[_currentItemData objectForKey:KEY_THRESHOLD_MPN_VALUES]];
		NSMutableArray *thresholdSubIds= [NSMutableArray arrayWithArray:[_currentItemData objectForKey:KEY_THRESHOLD_MPN_SUB_IDS]];
		
		[thresholdValues removeObjectAtIndex:index];
		[thresholdSubIds removeObjectAtIndex:index];
		
		[_currentItemData setObject:thresholdValues forKey:KEY_THRESHOLD_MPN_VALUES];
		[_currentItemData setObject:thresholdSubIds forKey:KEY_THRESHOLD_MPN_SUB_IDS];
		
		// Store item data
		[self storeData];
	}
}


#pragma mark -
#pragma mark Internals

- (void) fetchDataForItem:(NSString *)item {
	NSLog(@"Storage: reading data for item %@..", item);
	
	_currentItem= item;
	
	if (item)
		_currentItemData= [[NSMutableDictionary alloc] initWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:_currentItem]];
	else
		_currentItemData= [[NSMutableDictionary alloc] init];
}

- (void) storeData {
	NSLog(@"Storage: writing data for item %@...", _currentItem);

	[[NSUserDefaults standardUserDefaults] setObject:_currentItemData forKey:_currentItem];
	[[NSUserDefaults standardUserDefaults] synchronize];
}


@end
