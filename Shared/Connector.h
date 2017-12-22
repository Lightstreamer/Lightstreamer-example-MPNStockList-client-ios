//
//  Connector.h
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

#import <Foundation/Foundation.h>


@interface Connector : NSObject <LSClientDelegate, LSMPNDeviceDelegate> {
    LSLightstreamerClient *_client;
    
    BOOL _mpnEnabled;
}


#pragma mark -
#pragma mark Singleton access

+ (Connector *) sharedConnector;


#pragma mark -
#pragma mark Operations

- (void) connect;

- (void) subscribe:(LSSubscription *)subscription;
- (void) unsubscribe:(LSSubscription *)subscription;

- (void) registerDevice:(NSData *)deviceToken;
- (void) resetMPNBadge;

- (void) subscribeMPN:(LSMPNSubscription *)mpnSubscription;
- (void) unsubscribeMPN:(LSMPNSubscription *)mpnSubscription;
- (void) unsubscribeTriggeredMPNs;

- (NSArray *) MPNSubscriptions;


#pragma mark -
#pragma mark Properties

@property (nonatomic, readonly, getter=isConnected) BOOL connected;
@property (nonatomic, readonly) NSString *connectionStatus;
@property (nonatomic, readonly, getter=isMpnEnabled) BOOL mpnEnabled;


@end
