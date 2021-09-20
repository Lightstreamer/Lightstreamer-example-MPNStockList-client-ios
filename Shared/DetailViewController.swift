//  Converted to Swift 5.4 by Swiftify v5.4.24488 - https://swiftify.com/
//
//  DetailViewController.swift
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

class DetailViewController: UIViewController, SubscriptionDelegate, MPNSubscriptionDelegate, ChartViewDelegate {
    
    let lockQueue = DispatchQueue(label: "lightstreamer.DetailViewController")
    var detailView: DetailView?
    var chartController: ChartViewController?
    var priceMpnSubscription: MPNSubscription?
    var subscription: Subscription?

    var itemData: [String : String]?
    var itemUpdated: [AnyHashable : Any]?

    // MARK: -
    // MARK: Properties
    private(set) var item: String?

    // MARK: -
    // MARK: Notifications from notification center

    // MARK: -
    // MARK: Internals

    // MARK: -
    // MARK: Initialization

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        // Single-item data structures: they store fields data and
        // which fields have been updated
        itemData = [:]
        itemUpdated = [:]
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        // Single-item data structures: they store fields data and
        // which fields have been updated
        itemData = [:]
        itemUpdated = [:]
    }

    // MARK: -
    // MARK: Methods of UIViewController

    override func loadView() {
        let niblets = Bundle.main.loadNibNamed(DEVICE_XIB("DetailView"), owner: self, options: nil)
        detailView = niblets?.last as? DetailView

        view = detailView

        // Add chart
        chartController = ChartViewController(delegate: self)
        chartController?.view.backgroundColor = UIColor.white
        chartController?.view.frame = CGRect(x: 0.0, y: 0.0, width: detailView?.chartBackgroundView?.frame.size.width ?? 0.0, height: detailView?.chartBackgroundView?.frame.size.height ?? 0.0)

        if let view = chartController?.view {
            detailView?.chartBackgroundView?.addSubview(view)
        }

        // Initially disable MPN controls
        disableMPNControls()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Reset size of chart
        chartController?.view.frame = CGRect(x: 0.0, y: 0.0, width: detailView?.chartBackgroundView?.frame.size.width ?? 0.0, height: detailView?.chartBackgroundView?.frame.size.height ?? 0.0)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // We use the notification center to know when the app
        // has been successfully registered for MPN and when
        // the MPN subscription cache has been updated
        NotificationCenter.default.addObserver(self, selector: #selector(appDidRegisterForMPN), name: NOTIFICATION_MPN_ENABLED, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidUpdateMPNSubscriptionCache), name: NOTIFICATION_MPN_UPDATED, object: nil)

        // Check if registration for MPN has already been completed
        if Connector.shared().mpnEnabled {
            enableMPNControls()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        // Unregister from control center notifications
        NotificationCenter.default.removeObserver(self, name: NOTIFICATION_MPN_UPDATED, object: nil)
        NotificationCenter.default.removeObserver(self, name: NOTIFICATION_MPN_ENABLED, object: nil)

        // Unsubscribe the table
        if subscription != nil {
            print("DetailViewController: unsubscribing previous table...")

            Connector.shared().unsubscribe(subscription!)

            subscription = nil
        }
    }

    // MARK: -
    // MARK: Communication with StockList View Controller
    @objc func changeItem(_ item: String?) {
        // This method is always called from the main thread

        // Set current item and clear the data
        lockQueue.sync {
            self.item = item

            itemData?.removeAll()
            itemUpdated?.removeAll()
        }

        // Update the view
        updateView()

        // Reset the chart
        chartController?.clearChart()

        // Check MPN status and update view
        updateViewForMPNStatus()

        // If needed, unsubscribe previous table
        if subscription != nil {
            print("DetailViewController: unsubscribing previous table...")

            Connector.shared().unsubscribe(subscription!)
            subscription = nil
        }

        // Subscribe new single-item table
        if let item = item {
            print("DetailViewController: subscribing table...")

            // The LSLightstreamerClient will reconnect and resubscribe automatically
            subscription = Subscription(subscriptionMode: .MERGE, items: [item], fields: DETAIL_FIELDS)
            subscription?.dataAdapter = DATA_ADAPTER
            subscription?.requestedSnapshot = .yes
            subscription?.addDelegate(self)

            Connector.shared().subscribe(subscription!)
        }
    }

    @objc func updateViewForMPNStatus() {
        // This method is always called from the main thread

        // Clear thresholds on the chart
        detailView?.mpnSwitch?.isOn = false
        chartController?.clearThresholds()

        // Early bail
        if self.item == nil {
            return
        }

        // Early bail
        if !Connector.shared().mpnEnabled {
            return
        }

        // Update view according to cached MPN subscriptions
        let mpnSubscriptions = Connector.shared().mpnSubscriptions()
        for mpnSubscription in mpnSubscriptions {
            let builder = MPNBuilder(notificationFormat: mpnSubscription.notificationFormat!)!
            let item = builder.customData!["item"] as? String
            if self.item != item {
                continue
            }

            let threshold = builder.customData!["threshold"] as? String
            if let threshold = threshold {

                // MPN subscription is a threshold, we show it
                // only if it has not yet triggered
                if mpnSubscription.status != .TRIGGERED {
                    let chartThreshold = chartController?.addThreshold(Float(threshold) ?? 0.0)
                    chartThreshold?.mpnSubscription = mpnSubscription
                }
            } else {

                // MPN subscription is main price subscription
                priceMpnSubscription = mpnSubscription
                detailView?.mpnSwitch?.isOn = true
            }
        }
    }

    // MARK: -
    // MARK: User interfaction
    @IBAction func mpnSwitchDidChange() {

        // Get and keep current item
        var item: String? = nil
        lockQueue.sync {
            item = self.item
        }

        if detailView?.mpnSwitch?.isOn ?? false {
            if priceMpnSubscription != nil {

                // Delete the MPN subscription
                Connector.shared().unsubscribeMPN(priceMpnSubscription!)
                priceMpnSubscription = nil
            }

            // Prepare the notification format, with a custom data
            // to match the item against the MPN list
            let builder = MPNBuilder()
            builder.body("Stock ${stock_name} is now ${last_price}")
            builder.sound("Default")
            builder.badge(with: "AUTO")
            builder.customData(
                [
                    "item": item ?? "",
                    "stock_name": "${stock_name}",
                    "last_price": "${last_price}",
                    "pct_change": "${pct_change}",
                    "time": "${time}",
                    "open_price": "${open_price}"
                ])
            builder.category("STOCK_PRICE_CATEGORY")

            // Prepare the MPN subscription
            priceMpnSubscription = MPNSubscription(subscriptionMode: .MERGE, item: item!, fields: DETAIL_FIELDS)
            priceMpnSubscription?.dataAdapter = DATA_ADAPTER
            priceMpnSubscription?.notificationFormat = builder.build()
            priceMpnSubscription?.addDelegate(self)

            Connector.shared().subscribeMPN(priceMpnSubscription!)
        } else {
            if priceMpnSubscription != nil {

                // Delete the MPN subscription
                Connector.shared().unsubscribeMPN(priceMpnSubscription!)
                priceMpnSubscription = nil
            }
        }
    }

    // MARK: -
    // MARK: Methods of SubscriptionDelegate
    
    func subscription(_ subscription: Subscription, didClearSnapshotForItemName itemName: String?, itemPos: UInt) {}
    func subscription(_ subscription: Subscription, didLoseUpdates lostUpdates: UInt, forCommandSecondLevelItemWithKey key: String) {}
    func subscription(_ subscription: Subscription, didFailWithErrorCode code: Int, message: String?, forCommandSecondLevelItemWithKey key: String) {}
    func subscription(_ subscription: Subscription, didEndSnapshotForItemName itemName: String?, itemPos: UInt) {}
    func subscription(_ subscription: Subscription, didLoseUpdates lostUpdates: UInt, forItemName itemName: String?, itemPos: UInt) {}
    func subscriptionDidRemoveDelegate(_ subscription: Subscription) {}
    func subscriptionDidAddDelegate(_ subscription: Subscription) {}
    func subscriptionDidSubscribe(_ subscription: Subscription) {}
    func subscription(_ subscription: Subscription, didFailWithErrorCode code: Int, message: String?) {}
    func subscriptionDidUnsubscribe(_ subscription: Subscription) {}
    func subscription(_ subscription: Subscription, didReceiveRealFrequency frequency: RealMaxFrequency?) {}

    func subscription(_ subscription: Subscription, didUpdateItem itemUpdate: ItemUpdate) {
        // This method is always called from a background thread

        let itemName = itemUpdate.itemName

        lockQueue.sync {

            // Check if it is a late update of the previous table
            if item != itemName {
                return
            }

            var previousLastPrice = 0.0
            for fieldName in DETAIL_FIELDS {

                // Save previous last price to choose blick color later
                if fieldName == "last_price" {
                    previousLastPrice = toDouble(itemData?[fieldName])
                }

                // Store the updated field in the item's data structures
                let value = itemUpdate.value(withFieldName: fieldName)

                if value != "" {
                    itemData?[fieldName] = value
                } else {
                    itemData?[fieldName] = nil
                }

                if itemUpdate.isValueChanged(withFieldName: fieldName) {
                    itemUpdated?[fieldName] = NSNumber(value: true)
                }
            }

            let currentLastPrice = Double(itemUpdate.value(withFieldName: "last_price") ?? "0")!
            if currentLastPrice >= previousLastPrice {
                itemData?["color"] = "green"
            } else {
                itemData?["color"] = "orange"
            }
        }

        DispatchQueue.main.async(execute: { [self] in

            // Forward the update to the chart
            chartController?.itemDidUpdate(itemUpdate)

            // Update the view
            updateView()
        })
    }

    // MARK: -
    // MARK: methods of MPNSubscriptionDelegate
    
    func mpnSubscriptionDidAddDelegate(_ subscription: MPNSubscription) {}
    func mpnSubscriptionDidRemoveDelegate(_ subscription: MPNSubscription) {}
    func mpnSubscriptionDidUnsubscribe(_ subscription: MPNSubscription) {}
    func mpnSubscription(_ subscription: MPNSubscription, didFailUnsubscriptionWithErrorCode code: Int, message: String?) {}
    func mpnSubscriptionDidTrigger(_ subscription: MPNSubscription) {}
    func mpnSubscription(_ subscription: MPNSubscription, didChangeStatus status: MPNSubscription.Status, timestamp: Int64) {}
    func mpnSubscription(_ subscription: MPNSubscription, didChangeProperty property: String) {}
    func mpnSubscription(_ subscription: MPNSubscription, didFailModificationWithErrorCode code: Int, message: String?, property: String) {}

    func mpnSubscriptionDidSubscribe(_ subscription: MPNSubscription) {
        // This method is always called from a background thread

        print("DetailViewController: activation of MPN subscription succeeded")
    }

    func mpnSubscription(_ subscription: MPNSubscription, didFailSubscriptionWithErrorCode code: Int, message: String?) {
        // This method is always called from a background thread

        print(String(format: "DetailViewController: error while activating MPN subscription: %ld - %@", code, message ?? ""))

        // Show error alert
        let mpnSubscription = subscription
        DispatchQueue.main.async(execute: { [self] in
            UIAlertView(title: "Error while activating MPN subscription", message: "An error occurred and the MPN subscription could not be activated.", delegate: nil, cancelButtonTitle: "Cancel", otherButtonTitles: "").show()

            let builder = MPNBuilder(notificationFormat: mpnSubscription.notificationFormat!)!
            if builder.customData!["threshold"] != nil {

                // It's the subscription of a threshold, remove it if still present
                let threshold = chartController?.findThreshold((builder.customData!["threshold"] as? NSNumber)?.floatValue ?? 0.0)
                if let threshold = threshold {
                    chartController?.remove(threshold)
                }
            } else {

                // It's the main price subscription, reset the switch
                priceMpnSubscription = nil
                detailView?.mpnSwitch?.isOn = false
            }
        })
    }

    // MARK: -
    // MARK: ChartViewDelegate methods

    func chart(_ chartControllter: ChartViewController?, didAdd threshold: ChartThreshold?) {
        // This method is always called from the main thread

        var lastPrice: Float = 0.0
        lockQueue.sync {
            lastPrice = toFloat(itemData?["last_price"])
        }

        if (threshold?.value ?? 0.0) > lastPrice {

            // The threshold is higher than current price,
            // ask confirm with the appropriate alert view
            if let value = threshold?.value {
                let alert = UIAlertController(
                    title: "Add alert on threshold",
                    message: String(format: "Confirm adding a notification alert when %@ rises above %.2f", title ?? "", value),
                    preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(
                                    title: "Proceed",
                                    style: UIAlertAction.Style.default,
                                    handler: { _ in
                                        self.addOrUpdateMPNSubscription(for: threshold, greaterThan: true)
                                    }))
                alert.addAction(UIAlertAction(
                                    title: "Cancel",
                                    style: UIAlertAction.Style.cancel,
                                    handler: { _ in
                                        self.chartController?.remove(threshold)
                                    }))
                self.present(alert, animated: true, completion: nil)
            }
        } else if (threshold?.value ?? 0.0) < lastPrice {

            // The threshold is lower than current price,
            // ask confirm with the appropriate alert view
            if let value = threshold?.value {
                let alert = UIAlertController(
                    title: "Add alert on threshold",
                    message: String(format: "Confirm adding a notification alert when %@ drops below %.2f", title ?? "", value),
                    preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(
                                    title: "Proceed",
                                    style: UIAlertAction.Style.default,
                                    handler: { _ in
                                        self.addOrUpdateMPNSubscription(for: threshold, greaterThan: false)
                                    }))
                alert.addAction(UIAlertAction(
                                    title: "Cancel",
                                    style: UIAlertAction.Style.cancel,
                                    handler: { _ in
                                        self.chartController?.remove(threshold)
                                    }))
                self.present(alert, animated: true, completion: nil)
            }
        } else {

            // The threshold matches current price,
            // show the appropriate alert view
            UIAlertView(title: "Invalid threshold", message: "Threshold must be higher or lower than current price", delegate: nil, cancelButtonTitle: "Cancel", otherButtonTitles: "").show()

            // Cleanup
            chartController?.remove(threshold)
        }
    }

    func chart(_ chartControllter: ChartViewController?, didChange threshold: ChartThreshold?) {
        // This method is always called from the main thread

        var lastPrice: Float = 0.0

        lockQueue.sync {
            lastPrice = toFloat(itemData?["last_price"])
        }

        // No need to ask confirm, just proceed
        addOrUpdateMPNSubscription(for: threshold, greaterThan: (threshold?.value ?? 0.0) > lastPrice)
    }

    func chart(_ chartControllter: ChartViewController?, didRemove threshold: ChartThreshold?) {
        // This method is always called from the main thread

        // No need to ask confirm, just proceed
        deleteMPNSubscription(for: threshold)
    }

    // MARK: -
    // MARK: Properties

    // MARK: -
    // MARK: Notifications from notification center

    @objc func appDidRegisterForMPN() {
        DispatchQueue.main.async(execute: { [self] in
            enableMPNControls()
        })
    }

    @objc func appDidUpdateMPNSubscriptionCache() {
        DispatchQueue.main.async(execute: { [self] in
            updateViewForMPNStatus()
        })
    }

    // MARK: -
    // MARK: Internals

    func disableMPNControls() {

        // Disable UI controls related to MPN
        detailView?.chartBackgroundView?.isUserInteractionEnabled = false
        detailView?.chartTipLabel?.isHidden = true
        detailView?.switchTipLabel?.isEnabled = false
        detailView?.mpnSwitch?.isEnabled = false
    }

    func enableMPNControls() {

        // Enable UI controls related to MPN
        detailView?.chartBackgroundView?.isUserInteractionEnabled = true
        detailView?.chartTipLabel?.isHidden = false
        detailView?.switchTipLabel?.isEnabled = true
        detailView?.mpnSwitch?.isEnabled = true
    }

    func updateView() {
        // This method is always called on the main thread

        lockQueue.sync {

            // Take current item status from item's data structures
            // and update the view appropriately
            let colorName = itemData?["color"]
            var color: UIColor? = nil
            if colorName == "green" {
                color = GREEN_COLOR
            } else if colorName == "orange" {
                color = ORANGE_COLOR
            } else {
                color = UIColor.white
            }

            title = itemData?["stock_name"]

            detailView?.lastLabel?.text = itemData?["last_price"]
            if (itemUpdated?["last_price"] as? NSNumber)?.boolValue ?? false {
                SpecialEffects.flash(detailView?.lastLabel, with: color)
                itemUpdated?["last_price"] = NSNumber(value: false)
            }

            detailView?.timeLabel?.text = itemData?["time"]
            if (itemUpdated?["time"] as? NSNumber)?.boolValue ?? false {
                SpecialEffects.flash(detailView?.timeLabel, with: color)
                itemUpdated?["time"] = NSNumber(value: false)
            }

            let pctChange = toDouble(itemData?["pct_change"])
            if pctChange > 0.0 {
                detailView?.dirImage?.image = UIImage(named: "Arrow-up")
            } else if pctChange < 0.0 {
                detailView?.dirImage?.image = UIImage(named: "Arrow-down")
            } else {
                detailView?.dirImage?.image = nil
            }

            detailView?.changeLabel?.text = (itemData?["pct_change"] ?? "") + "%"
            detailView?.changeLabel?.textColor = (toDouble(itemData?["pct_change"]) >= 0.0) ? DARK_GREEN_COLOR : RED_COLOR

            if (itemUpdated?["pct_change"] as? NSNumber)?.boolValue ?? false {
                SpecialEffects.flashImage(detailView?.dirImage, with: color)
                SpecialEffects.flash(detailView?.changeLabel, with: color)
                itemUpdated?["pct_change"] = NSNumber(value: false)
            }

            detailView?.minLabel?.text = itemData?["min"]
            if (itemUpdated?["min"] as? NSNumber)?.boolValue ?? false {
                SpecialEffects.flash(detailView?.minLabel, with: color)
                itemUpdated?["min"] = NSNumber(value: false)
            }

            detailView?.maxLabel?.text = itemData?["max"]
            if (itemUpdated?["max"] as? NSNumber)?.boolValue ?? false {
                SpecialEffects.flash(detailView?.maxLabel, with: color)
                itemUpdated?["max"] = NSNumber(value: false)
            }

            detailView?.bidLabel?.text = itemData?["bid"]
            if (itemUpdated?["bid"] as? NSNumber)?.boolValue ?? false {
                SpecialEffects.flash(detailView?.bidLabel, with: color)
                itemUpdated?["bid"] = NSNumber(value: false)
            }

            detailView?.askLabel?.text = itemData?["ask"]
            if (itemUpdated?["ask"] as? NSNumber)?.boolValue ?? false {
                SpecialEffects.flash(detailView?.askLabel, with: color)
                itemUpdated?["ask"] = NSNumber(value: false)
            }

            detailView?.bidSizeLabel?.text = itemData?["bid_quantity"]
            if (itemUpdated?["bid_quantity"] as? NSNumber)?.boolValue ?? false {
                SpecialEffects.flash(detailView?.bidSizeLabel, with: color)
                itemUpdated?["bid_quantity"] = NSNumber(value: false)
            }

            detailView?.askSizeLabel?.text = itemData?["ask_quantity"]
            if (itemUpdated?["ask_quantity"] as? NSNumber)?.boolValue ?? false {
                SpecialEffects.flash(detailView?.askSizeLabel, with: color)
                itemUpdated?["ask_quantity"] = NSNumber(value: false)
            }

            detailView?.openLabel?.text = itemData?["open_price"]
            if (itemUpdated?["open_price"] as? NSNumber)?.boolValue ?? false {
                SpecialEffects.flash(detailView?.openLabel, with: color)
                itemUpdated?["open_price"] = NSNumber(value: false)
            }
        }
    }

    func addOrUpdateMPNSubscription(for threshold: ChartThreshold?, greaterThan: Bool) {
        // This method is always called from the main thread

        // Get and keep current item
        var item: String? = nil
        lockQueue.sync {
            item = self.item
        }

        // Prepare the notification format, with a custom data
        // to match the item and threshold against the MPN list
        let builder = MPNBuilder()
        if let value = threshold?.value {
            builder.body(String(format: greaterThan ? "Stock ${stock_name} rised above %.2f" : "Stock ${stock_name} dropped below %.2f", value))
        }
        builder.sound("Default")
        builder.badge(with: "AUTO")
        if let value = threshold?.value {
            builder.customData(
                [
                    "item": item ?? "",
                    "stock_name": "${stock_name}",
                    "last_price": "${last_price}",
                    "pct_change": "${pct_change}",
                    "time": "${time}",
                    "open_price": "${open_price}",
                    "threshold": String(format: "%.2f", value),
                    "subID": "${LS_MPN_subscription_ID}"
                ])
        }
        builder.category("STOCK_PRICE_CATEGORY")

        var trigger: String? = nil
        if let value = threshold?.value {
            trigger = String(format: "Double.parseDouble(${last_price}) %@ %.2f", (greaterThan ? ">" : "<"), value)
        }
        print("DetailViewController: subscribing MPN with trigger expression: \(trigger ?? "")")

        // Prepare the MPN subscription
        let mpnSubscription = MPNSubscription(subscriptionMode: .MERGE, item: item!, fields: DETAIL_FIELDS)
        mpnSubscription.dataAdapter = DATA_ADAPTER
        mpnSubscription.notificationFormat = builder.build()
        mpnSubscription.triggerExpression = trigger
        mpnSubscription.addDelegate(self)

        // Delete the existing MPN subscription, if present
        if ((threshold?.mpnSubscription) != nil) {
            Connector.shared().unsubscribeMPN((threshold?.mpnSubscription)!)
        }

        // Activate the new MPN subscription
        Connector.shared().subscribeMPN(mpnSubscription)
        threshold?.mpnSubscription = mpnSubscription
    }

    func deleteMPNSubscription(for threshold: ChartThreshold?) {
        // This method is always called from the main thread

        // Delete the existing MPN subscription, if present
        if ((threshold?.mpnSubscription) != nil) {
            Connector.shared().unsubscribeMPN((threshold?.mpnSubscription)!)
        }
    }
    
    func toDouble(_ s: String?) -> Double {
        Double(s ?? "0") ?? 0
    }
    
    func toFloat(_ s: String?) -> Float {
        Float(s ?? "0") ?? 0
    }
}

// MARK: -
// MARK: DetailViewController extension
// MARK: -
// MARK: DetailViewController implementation
