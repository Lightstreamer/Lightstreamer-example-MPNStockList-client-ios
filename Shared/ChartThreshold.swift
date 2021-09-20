//  Converted to Swift 5.4 by Swiftify v5.4.24488 - https://swiftify.com/
//
//  ChartThreshold.swift
//  StockList Demo for iOS
//
//  Created by Gianluca Bertani on 26/02/14.
//  Copyright (c) Lightstreamer Srl
//

import Foundation
import LightstreamerClient

class ChartThreshold: NSObject {
    // MARK: -
    // MARK: Properties
    private(set) var chartView: ChartView?

    private var _value: Float = 0.0
    @objc var value: Float {
        get {
            return _value
        }
        set(value) {
            _value = value

            chartView?.setNeedsDisplay()
        }
    }
    var mpnSubscription: MPNSubscription?

    // MARK: -
    // MARK: Initialization
    init(view chartView: ChartView?, value: Float) {
        super.init()
            // Initialization
            self.chartView = chartView

            self.value = value
    }

    // MARK: -
    // MARK: Removal

    // MARK: -
    // MARK: Deletion

    @objc func remove() {
        chartView?.remove(self)
    }

    // MARK: -
    // MARK: Properties
}
