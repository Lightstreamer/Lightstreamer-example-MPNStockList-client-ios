//
//  MPNCache.m
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

#import "MPNSubscriptionCache.h"
#import "Constants.h"


static MPNSubscriptionCache *__sharedInstace= nil;

@implementation MPNSubscriptionCache


#pragma mark -
#pragma mark Singleton access

+ (MPNSubscriptionCache *) sharedCache {
	if (!__sharedInstace) {
		@synchronized ([MPNSubscriptionCache class]) {
			if (!__sharedInstace)
				__sharedInstace= [[MPNSubscriptionCache alloc] init];
		}
	}
	
	return __sharedInstace;
}


#pragma mark -
#pragma mark Initialization

- (id) init {
	if ((self = [super init])) {
		
		// Initialization
		_itemsMPNs= [[NSMutableDictionary alloc] init];
	}
	
	return self;
}


#pragma mark -
#pragma mark Cache update from Server

- (void) updateWithInfos:(NSArray *)mpnInfos {
	@synchronized (self) {
		[_itemsMPNs removeAllObjects];
		
		for (LSMPNInfo *mpnInfo in mpnInfos) {
			NSString *item= [mpnInfo.customData objectForKey:@"item"];
			
			// Skip extraneous MPN subscriptions
			if (!item)
				continue;
			
			[self addMPNSubscription:mpnInfo];
		}
	}
	
	// Notify the cache has been updated
	[[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_CACHE_UPDATED object:self];
}


#pragma mark -
#pragma mark Get cached item's MPN subscriptions

- (void) clearMPNSubscriptions {
	@synchronized (self) {
		[_itemsMPNs removeAllObjects];
	}
	
	// Notify the cache has been updated
	[[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_CACHE_UPDATED object:self];
}

- (NSArray *) getMPNSubscriptionsForItem:(NSString *)item {
	@synchronized (self) {
		NSMutableDictionary *itemMPNs= [_itemsMPNs objectForKey:item];

		return [itemMPNs allValues];
	}
}

- (LSMPNInfo *) getMPNSubscriptionWithKey:(LSMPNKey *)mpnKey forItem:(NSString *)item {
	@synchronized (self) {
		NSMutableDictionary *itemMPNs= [_itemsMPNs objectForKey:item];
		
		return [itemMPNs objectForKey:mpnKey.subscriptionId];
	}
}

- (void) addMPNSubscription:(LSMPNInfo *)mpnInfo {
	@synchronized (self) {
		NSString *item= [mpnInfo.customData objectForKey:@"item"];

		NSMutableDictionary *itemMPNs= [_itemsMPNs objectForKey:item];
		if (!itemMPNs) {
			itemMPNs= [[NSMutableDictionary alloc] init];
			[_itemsMPNs setObject:itemMPNs forKey:item];
		}
		
		[itemMPNs setObject:mpnInfo forKey:mpnInfo.mpnKey.subscriptionId];
	}
}

- (void) removeMPNSubscriptionWithKey:(LSMPNKey *)mpnKey forItem:(NSString *)item {
	@synchronized (self) {
		NSMutableDictionary *itemMPNs= [_itemsMPNs objectForKey:item];
		
		return [itemMPNs removeObjectForKey:mpnKey.subscriptionId];
	}
}


@end
