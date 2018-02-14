//
//  NotificationController.m
//  StockWatch Extension
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

#import <UserNotifications/UserNotifications.h>

#import "NotificationController.h"
#import "Constants.h"


@implementation NotificationController

- (instancetype) init {
    if ((self = [super init])) {

        // Nothing to do, for now
    }

    return self;
}

- (void) willActivate {
    [super willActivate];
    
    // Nothing to do, for now
}

- (void) didDeactivate {
    [super didDeactivate];
    
    // Nothing to do, for now
}

- (void) didReceiveNotification:(UNNotification *)notification withCompletion:(void(^)(WKUserNotificationInterfaceType interface)) completionHandler {
    
    // Retrieve the item's data
    NSDictionary *item= notification.request.content.userInfo;
    if (item) {
        
        // Set the message
        self.messageLabel.text= notification.request.content.body;
        
        // Update the data labels
        self.lastLabel.text= [item objectForKey:@"last_price"];
        self.timeLabel.text= [item objectForKey:@"time"];
        self.openLabel.text= [item objectForKey:@"open_price"];
        
        double pctChange= [[item objectForKey:@"pct_change"] doubleValue];
        if (pctChange > 0.0)
            self.dirImage.image= [UIImage imageNamed:@"Arrow-up"];
        else if (pctChange < 0.0)
            self.dirImage.image= [UIImage imageNamed:@"Arrow-down"];
        else
            self.dirImage.image= nil;
        
        self.changeLabel.text= [NSString stringWithFormat:@"%@%%", [item objectForKey:@"pct_change"]];
        self.changeLabel.textColor= (([[item objectForKey:@"pct_change"] doubleValue] >= 0.0) ? DARK_GREEN_COLOR : RED_COLOR);
        
        // Call the completion handler for custom (dynamic) notification
        completionHandler(WKUserNotificationInterfaceTypeCustom);
    
    } else {
        
        // Call the completion handler for default (static) notification
        completionHandler(WKUserNotificationInterfaceTypeDefault);
    }
}


@end



