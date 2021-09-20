//  Converted to Swift 5.4 by Swiftify v5.4.24488 - https://swiftify.com/
//
//  AppDelegate_iPhone.swift
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

import UIKit
import LightstreamerClient

//@UIApplicationMain
class AppDelegate_iPhone: NSObject, UIApplicationDelegate, StockListAppDelegate {

    var navController: UINavigationController?


    // MARK: -
    // MARK: Properties
    @IBOutlet var window: UIWindow?
    private(set) var stockListController: StockListViewController?

    // MARK: -
    // MARK: Application lifecycle

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        application.statusBarStyle = .lightContent

        // Uncomment for detailed logging
        // LightstreamerClient.setLoggerProvider(ConsoleLoggerProvider(level: .debug))

        // Create the user interface
        stockListController = StockListViewController()

        if let stockListController = stockListController {
            navController = UINavigationController(rootViewController: stockListController)
        }
        navController?.navigationBar.barStyle = .black

        window?.rootViewController = navController
        window?.makeKeyAndVisible()

        // MPN Registration: first prepare an action for user notifications
        let viewAction = UIMutableUserNotificationAction()
        viewAction.identifier = "VIEW_IDENTIFIER"
        viewAction.title = "View Stock Details"
        viewAction.isDestructive = false
        viewAction.isAuthenticationRequired = false

        // Now prepare a category for user notifications
        let stockPriceCategory = UIMutableUserNotificationCategory()
        stockPriceCategory.identifier = "STOCK_PRICE_CATEGORY"
        stockPriceCategory.setActions([viewAction], for: .default)
        stockPriceCategory.setActions([viewAction], for: .minimal)

        let categories = Set<AnyHashable>([stockPriceCategory])

        // Now register for user notifications
        let types: UIUserNotificationType = [.badge, .sound, .alert]
        let mySettings = UIUserNotificationSettings(types: types, categories: categories as? Set<UIUserNotificationCategory>)

        UIApplication.shared.registerUserNotificationSettings(mySettings)

        // Let the StockList View Controller handle any pending MPN
        let mpn = launchOptions?[.remoteNotification] as? [AnyHashable : Any]
        if let mpn = mpn {
            stockListController?.perform(#selector(StockListViewController.handleMPN), with: mpn, afterDelay: ALERT_DELAY)
        }

        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {

        // Reset the app's icon badge
        application.applicationIconBadgeNumber = 0

        if Connector.shared().mpnEnabled {

            // Notify Lightstreamer that the app's icon badge has been reset
            Connector.shared().resetMPNBadge()
        }
    }

    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        let allowedTypes = notificationSettings.types

        print("AppDelegate: registration for user notifications succeeded with types: \(allowedTypes.rawValue)")

        // Finally register for remote notifications
        application.registerForRemoteNotifications()
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("AppDelegate: registration for remote notifications succeeded with token: \(deviceToken)")

        // Register device token with LS Client (will be stored for later use)
        Connector.shared().registerDevice(deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("AppDelegate: MPN registration failed with error: \(error) (user info: \((error as NSError).userInfo))")
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        print("AppDelegate: MPN with info: \(userInfo)")

        // Let the StockList View Controller handle the MPN
        stockListController?.perform(#selector(StockListViewController.handleMPN), with: userInfo, afterDelay: ALERT_DELAY)
    }

    // MARK: -
    // MARK: Properties
}
