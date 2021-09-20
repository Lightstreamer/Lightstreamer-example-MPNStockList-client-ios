//  Converted to Swift 5.4 by Swiftify v5.4.22271 - https://swiftify.com/
//
//  NotificationController.swift
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

import Foundation
import UserNotifications
import WatchKit

class NotificationController: WKUserNotificationInterfaceController {
    // MARK: -
    // MARK: Notification message
    @IBOutlet var messageLabel: WKInterfaceLabel!
    // MARK: -
    // MARK: Data visualization
    @IBOutlet var lastLabel: WKInterfaceLabel!
    @IBOutlet var dirImage: WKInterfaceImage!
    @IBOutlet var changeLabel: WKInterfaceLabel!
    @IBOutlet var openLabel: WKInterfaceLabel!
    @IBOutlet var timeLabel: WKInterfaceLabel!

    override init() {
        super.init()
            // Nothing to do, for now
    }

    override func willActivate() {
        super.willActivate()

        // Nothing to do, for now
    }

    override func didDeactivate() {
        super.didDeactivate()

        // Nothing to do, for now
    }

    override func didReceive(_ notification: UNNotification, withCompletion completionHandler: @escaping (WKUserNotificationInterfaceType) -> Void) {

        // Retrieve the item's data
        let item = notification.request.content.userInfo as? [String:String?]
        if let item = item {

            // Set the message
            messageLabel.setText(notification.request.content.body)

            // Update the data labels
            lastLabel.setText(item["last_price"] ?? "")
            timeLabel.setText(item["time"] ?? "")
            openLabel.setText(item["open_price"] ?? "")

            let pctChange = Double((item["pct_change"] ?? "0") ?? "0") ?? 0.0
            if pctChange > 0.0 {
                dirImage.setImage(UIImage(named: "Arrow-up"))
            } else if pctChange < 0.0 {
                dirImage.setImage(UIImage(named: "Arrow-down"))
            } else {
                dirImage.setImage(nil)
            }

            if let object = item["pct_change"] ?? "0" {
                changeLabel.setText(String(format: "%@%%", object))
            }
            changeLabel.setTextColor(Double((item["pct_change"] ?? "0") ?? "0") ?? 0.0 >= 0.0 ? DARK_GREEN_COLOR : RED_COLOR)

            // Call the completion handler for custom (dynamic) notification
            completionHandler(WKUserNotificationInterfaceType.custom)
        } else {

            // Call the completion handler for default (static) notification
            completionHandler(WKUserNotificationInterfaceType.default)
        }
    }
}
