//
//  Storage.h
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


@interface Storage : NSObject {
	NSString *_currentItem;
	NSMutableDictionary *_currentItemData;
}


#pragma mark -
#pragma mark Singleton access

+ (Storage *) sharedStorage;


#pragma mark -
#pragma mark Operations on item's MPN subscription

- (BOOL) isMPNActiveForItem:(NSString *)item;
- (LSMPNKey *) MPNKeyForItem:(NSString *)item;

- (void) setMPNKey:(LSMPNKey *)mpnKey forItem:(NSString *)item;
- (void) clearMPNKeyForItem:(NSString *)item;


#pragma mark -
#pragma mark Operations on item thresholds' MPN subscriptions

- (NSArray *) thresholdValuesForItem:(NSString *)item;
- (NSArray *) thresholdMPNKeysForItem:(NSString *)item;
- (float) valueOfThresholdAtIndex:(int)index forItem:(NSString *)item;
- (LSMPNKey *) MPNKeyOfThresholdAtIndex:(int)index forItem:(NSString *)item;
- (int) indexOfThresholdWithMPNKey:(LSMPNKey *)mpnKey forItem:(NSString *)item;

- (void) addThresholdValue:(float)value MPNKey:(LSMPNKey *)mpnKey forItem:(NSString *)item;
- (void) updateThresholdValue:(float)value MPNKey:(LSMPNKey *)mpnKey atIndex:(int)index forItem:(NSString *)item;
- (void) deleteThresholdAtIndex:(int)index forItem:(NSString *)item;


@end
