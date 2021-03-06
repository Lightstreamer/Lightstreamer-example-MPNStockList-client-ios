//
//  AppDelegate_iPhone.m
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

#import "AppDelegate_iPhone.h"
#import "StockListViewController.h"
#import "Connector.h"
#import "Constants.h"


@implementation AppDelegate_iPhone


#pragma mark -
#pragma mark Application lifecycle

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    application.statusBarStyle= UIStatusBarStyleLightContent;
	
	// Uncomment for detailed logging
//  [LSLightstreamerClient setLoggerProvider:[[LSConsoleLoggerProvider alloc] initWithLevel:LSConsoleLogLevelDebug]];

	// Create the user interface
	_stockListController= [[StockListViewController alloc] init];
	
	_navController= [[UINavigationController alloc] initWithRootViewController:_stockListController];
	_navController.navigationBar.barStyle= UIBarStyleBlack;

	_window.rootViewController= _navController;
    [_window makeKeyAndVisible];
	
    // MPN Registration: first prepare an action for user notifications
    UIMutableUserNotificationAction *viewAction= [[UIMutableUserNotificationAction alloc] init];
    viewAction.identifier= @"VIEW_IDENTIFIER";
    viewAction.title= @"View Stock Details";
    viewAction.destructive= NO;
    viewAction.authenticationRequired= NO;
    
    // Now prepare a category for user notifications
    UIMutableUserNotificationCategory *stockPriceCategory= [[UIMutableUserNotificationCategory alloc] init];
    stockPriceCategory.identifier = @"STOCK_PRICE_CATEGORY";
    [stockPriceCategory setActions:@[viewAction] forContext:UIUserNotificationActionContextDefault];
    [stockPriceCategory setActions:@[viewAction] forContext:UIUserNotificationActionContextMinimal];
    
    NSSet *categories= [NSSet setWithObjects:stockPriceCategory, nil];
    
    // Now register for user notifications
    UIUserNotificationType types= UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
    UIUserNotificationSettings *mySettings= [UIUserNotificationSettings settingsForTypes:types categories:categories];
    
    [[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];
	
	// Let the StockList View Controller handle any pending MPN
	NSDictionary *mpn= [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
	if (mpn)
		[_stockListController performSelector:@selector(handleMPN:) withObject:mpn afterDelay:ALERT_DELAY];

    return YES;
}

- (void) applicationDidBecomeActive:(UIApplication *)application {
	
	// Reset the app's icon badge
	application.applicationIconBadgeNumber= 0;
    
    if ([[Connector sharedConnector] isMpnEnabled]) {
        
        // Notify Lightstreamer that the app's icon badge has been reset
        [[Connector sharedConnector] resetMPNBadge];
    }
}

- (void) application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
	UIUserNotificationType allowedTypes= [notificationSettings types];
	
	NSLog(@"AppDelegate: registration for user notifications succeeded with types: %d", (int) allowedTypes);
	
	// Finally register for remote notifications
	[application registerForRemoteNotifications];
}

- (void) application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSLog(@"AppDelegate: registration for remote notifications succeeded with token: %@", deviceToken);
    
    // Register device token with LS Client (will be stored for later use)
    [[Connector sharedConnector] registerDevice:deviceToken];
}

- (void) application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
	NSLog(@"AppDelegate: MPN registration failed with error: %@ (user info: %@)", error, [error userInfo]);
}

- (void) application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
	NSLog(@"AppDelegate: MPN with info: %@", userInfo);
	
	// Let the StockList View Controller handle the MPN
	[_stockListController performSelector:@selector(handleMPN:) withObject:userInfo afterDelay:ALERT_DELAY];
}


#pragma mark -
#pragma mark Properties

@synthesize window= _window;
@synthesize stockListController= _stockListController;


@end
