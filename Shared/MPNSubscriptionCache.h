//
//  MPNCache.h
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

#import <Foundation/Foundation.h>


@interface MPNSubscriptionCache : NSObject {
	NSMutableDictionary *_itemsMPNs;
}


#pragma mark -
#pragma mark Singleton access

+ (MPNSubscriptionCache *) sharedCache;


#pragma mark -
#pragma mark Cache update

- (void) updateWithInfos:(NSArray *)mpnInfos;

- (void) clearMPNSubscriptions;
- (void) addMPNSubscription:(LSMPNInfo *)mpnInfo;
- (void) removeMPNSubscriptionWithKey:(LSMPNKey *)mpnKey forItem:(NSString *)item;


#pragma mark -
#pragma mark MPN subscription operations

- (NSArray *) getMPNSubscriptionsForItem:(NSString *)item;
- (LSMPNInfo *) getMPNSubscriptionWithKey:(LSMPNKey *)mpnKey forItem:(NSString *)item;


@end
