//
//  AppDelegate_iPhone.m
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

#import "AppDelegate_iPhone.h"
#import "StockListViewController.h"


@implementation AppDelegate_iPhone


#pragma mark -
#pragma mark Application lifecycle

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    application.statusBarStyle= UIStatusBarStyleDefault;

	_stockListController= [[StockListViewController alloc] init];
	_navController= [[UINavigationController alloc] initWithRootViewController:_stockListController];
	_navController.navigationBar.barStyle= UIBarStyleBlack;

    if ([_window respondsToSelector:@selector(setRootViewController:)]) {
		
		// iOS >= 6.0
        _window.rootViewController= _navController;
		
    } else {
        
        // iOS < 6.0
        [_window addSubview:_navController.view];
    }
	
    [_window makeKeyAndVisible];
    
    return YES;
}

- (void) applicationDidEnterBackground:(UIApplication *)application {
	[_stockListController unsubscribeItems];
}

- (void) applicationWillEnterForeground:(UIApplication *)application {
	[_stockListController subscribeItems];
}

- (void) dealloc {
	[_stockListController release];
	[_navController release];
    [_window release];
    
	[super dealloc];
}


#pragma mark -
#pragma mark Properties

@synthesize window= _window;


@end
