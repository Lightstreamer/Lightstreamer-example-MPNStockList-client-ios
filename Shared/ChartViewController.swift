//  Converted to Swift 5.4 by Swiftify v5.4.24488 - https://swiftify.com/
//
//  ChartViewController.swift
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

class ChartViewController: UIViewController {
    var chartView: ChartView?
    weak var delegate: ChartViewDelegate?
    var currentThreshold: ChartThreshold?
    var currentThresholdIsNew = false
    var timeFormatter: DateFormatter?
    var referenceDate: Date?

    // MARK: -
    // MARK: Initialization
    init(delegate: ChartViewDelegate?) {
        super.init(nibName: nil, bundle: nil)
        // Initialization
        self.delegate = delegate

        // Prepare reference date (release date of SDK 1.3 a1)
        var calendar = Calendar(identifier: .gregorian)
        if let time = NSTimeZone(abbreviation: "GMT") {
            calendar.timeZone = time as TimeZone
        }

        var comps = DateComponents()
        comps.day = 19
        comps.month = 2
        comps.year = 2014
        referenceDate = calendar.date(from: comps)

        // Prepare time parser
        timeFormatter = DateFormatter()
        timeFormatter?.dateFormat = "HH:mm:ss"
    }

    // MARK: -
    // MARK: Methods of UIViewController

    override func loadView() {
        chartView = ChartView(frame: CGRect.zero)

        view = chartView
    }

    // MARK: -
    // MARK: Chart management
    func clearChart() {
        if let referenceDate = referenceDate {
            clearChart(withMin: 0.0, max: 0.0, time: Date().timeIntervalSince(referenceDate), value: 0.0)
        }
    }

    func clearChart(withMin min: Float, max: Float, time: TimeInterval, value: Float) {
        chartView?.clearValues()
        chartView?.clearThresholds()

        chartView?.min = min
        chartView?.max = max
        chartView?.end = time
        chartView?.begin = time - 120.0

        if value != 0.0 {
            chartView?.addValue(value, withTime: time)
        }
    }

    func addThreshold(_ value: Float) -> ChartThreshold? {
        return chartView?.addThreshold(value)
    }

    func findThreshold(_ value: Float) -> ChartThreshold? {
        return chartView?.findThreshold(within: 0.01, fromValue: value)
    }

    func remove(_ threshold: ChartThreshold?) {
        chartView?.remove(threshold)
    }

    func clearThresholds() {
        chartView?.clearThresholds()
    }

    // MARK: -
    // MARK: User interaction

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.count > 1 {
            super.touchesBegan(touches, with: event)
            return
        }

        let touch = touches.first!
        let point = touch.location(in: chartView)

        // Transalte Y coordinate in Y value
        let valueTime = chartView!.value(at: point)

        // Compute approximate value-width of a common tap (40 pixel)
        let tapWidth = ((chartView!.max - chartView!.min) / Float(chartView!.frame.size.height)) * Float(TAP_SENSIBILITY_PIXELS)

        // Check if we are tapping an existing threshold
        currentThreshold = chartView?.findThreshold(within: tapWidth, fromValue: Float(valueTime.y))
        if currentThreshold == nil {

            // Create new threshold
            currentThresholdIsNew = true
            currentThreshold = chartView?.addThreshold(Float(valueTime.y))
        } else {
            currentThresholdIsNew = false
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.count > 1 {
            super.touchesMoved(touches, with: event)
            return
        }

        let touch = touches.first!
        let point = touch.location(in: chartView)

        // Transalte Y coordinate in Y value
        let valueTime = chartView!.value(at: point)

        // Update threshold (updates view)
        currentThreshold?.value = Float(valueTime.y)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.count > 1 {
            super.touchesEnded(touches, with: event)
            return
        }

        if (currentThreshold!.value > chartView!.max) || (currentThreshold!.value < chartView!.min) {
            currentThreshold?.remove()

            // Notify the delegate
            if !currentThresholdIsNew {
                delegate?.chart(self, didRemove: currentThreshold)
            }
        } else {

            // Notify the delegate
            if currentThresholdIsNew {
                delegate?.chart(self, didAdd: currentThreshold)
            } else {
                delegate?.chart(self, didChange: currentThreshold)
            }
        }
    }

    // MARK: -
    // MARK: Updates from Lightstreamer
    func itemDidUpdate(_ itemUpdate: ItemUpdate?) {

        // Extract last point time
        let timeString = itemUpdate?.value(withFieldName: "time")
        let updateTime = timeFormatter?.date(from: timeString ?? "")

        // Compute the full date knowing the Server lives in the West European time zone
        // (which is not simply GMT, as it may undergo daylight savings)
        var calendar = Calendar(identifier: .gregorian)
        let timeZone = NSTimeZone(name: SERVER_TIMEZONE)
        if let timeZone = timeZone {
            calendar.timeZone = timeZone as TimeZone
        }

        let nowComponents = calendar.dateComponents([.day, .month, .year], from: Date())
        var timeComponents: DateComponents? = nil
        if let updateTime = updateTime {
            timeComponents = calendar.dateComponents([.hour, .minute, .second], from: updateTime)
        }

        var dateComponents = DateComponents()
        dateComponents.timeZone = timeZone as TimeZone? // The timezone is known a-priori
        dateComponents.year = nowComponents.year ?? 0 // Take the current day
        dateComponents.month = nowComponents.month ?? 0
        dateComponents.day = nowComponents.day ?? 0
        dateComponents.hour = timeComponents?.hour ?? 0 // Take the time of the update
        dateComponents.minute = timeComponents?.minute ?? 0
        dateComponents.second = timeComponents?.second ?? 0

        let updateDate = calendar.date(from: dateComponents)
        var time: TimeInterval? = nil
        if let referenceDate = referenceDate {
            time = updateDate?.timeIntervalSince(referenceDate) ?? 0.0
        }

        // Extract last point data
        let value = Float(itemUpdate?.value(withFieldName: "last_price") ?? "0") ?? 0.0
        let min = Float(itemUpdate?.value(withFieldName: "min") ?? "0") ?? 0.0
        let max = Float(itemUpdate?.value(withFieldName: "max") ?? "0") ?? 0.0

        // Update chart
        chartView?.min = min
        chartView?.max = max
        chartView?.end = time ?? 0
        chartView?.begin = (time ?? 0.0) - 120.0

        chartView?.addValue(value, withTime: time ?? 0)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

let SERVER_TIMEZONE = "Europe/Dublin"

let TAP_SENSIBILITY_PIXELS = 20.0
