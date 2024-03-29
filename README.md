# Lightstreamer - Stock-List Demo with APNs Push Notifications - iOS Client

<!-- START DESCRIPTION lightstreamer-example-mpnstocklist-client-ios -->

This project contains an example of an application for iPhone, iPad and Vision Pro that employs the [Lightstreamer Swift Client library](https://www.lightstreamer.com/api/ls-swift-client/latest/), with use of mobile push notifications (MPN). The application also includes a WatchKit extension.

A simpler version, without mobile push notifications support, is also available: [Lightstreamer - Stock-List Demo - iOS Client](https://github.com/Lightstreamer/Lightstreamer-example-StockList-client-ios).

## Live Demo

[![screenshot](screenshot_newlarge.png)](https://itunes.apple.com/us/app/lightstreamer-stock-list-apns/id430328811?mt=8)<br>
### [![](http://demos.lightstreamer.com/site/img/play.png) View live demo](https://itunes.apple.com/us/app/lightstreamer-stock-list-apns/id430328811?mt=8)<br>

## Details

This app, compatible with iPhone, iPad and Vision Pro, is a Swift version of the [Stock-List Demos](https://github.com/Lightstreamer/Lightstreamer-example-Stocklist-client-javascript).<br>

This app uses the <b>Swift Client API for Lightstreamer</b> to handle the communications with Lightstreamer Server. A simple user interface is implemented to display the real-time data received from Lightstreamer Server. Additionally, the user interface provides means to activate and deactivate mobile push notifications for specific stock quotes.<br>

## Install

Binaries for the application are not provided, but it may be downloaded from the App Store at [this address](https://itunes.apple.com/us/app/lightstreamer-stock-list-apns/id430328811?mt=8). The downloaded app will connect to Lightstreamer's online demo server.

## Build

A full Xcode project, ready for compilation of the app sources, is provided. Please recall that you need a valid iOS Developer Program membership to run or debug your app on a test device.

### Compile and Run

A full local deploy of this app requires a Lightstreamer Server 7.4 or greater installation with appropriate Mobile Push Notifications (MPN) module configuration. A detailed step by step guide for setting up the server and configuring the client is available in the README of the following project:

* [Lightstreamer - MPN Stock-List Demo Metadata - Java Adapter](https://github.com/Lightstreamer/Lightstreamer-example-MPNStockListMetadata-adapter-java)

## See Also

### Lightstreamer Adapters Needed by This Demo Client

* [Lightstreamer - Stock- List Demo - Java Adapter](https://github.com/Lightstreamer/Lightstreamer-example-Stocklist-adapter-java)
* [Lightstreamer - MPN Stock-List Demo Metadata - Java Adapter](https://github.com/Lightstreamer/Lightstreamer-example-MPNStockListMetadata-adapter-java)

### Related Projects

* [Lightstreamer - Stock-List Demos - HTML Clients](https://github.com/Lightstreamer/Lightstreamer-example-Stocklist-client-javascript)
* [Lightstreamer - Stock-List Demo - iOS Client](https://github.com/Lightstreamer/Lightstreamer-example-StockList-client-ios)
* [Lightstreamer - Stock-List Demo with FCM Push Notifications - Android Client](https://github.com/Lightstreamer/Lightstreamer-example-MPNStockList-client-android)
* [Lightstreamer - Basic Stock-List Demo - OS X Client](https://github.com/Lightstreamer/Lightstreamer-example-StockList-client-osx)
* [Lightstreamer - Basic Stock-List Demo - Windows Phone Client](https://github.com/Lightstreamer/Lightstreamer-example-StockList-client-winphone)

## Lightstreamer Compatibility Notes

* Code compatible with Lightstreamer Swift Library version 6.1 or newer.
* For Lightstreamer Server version 7.4 or greater. Ensure that iOS, watchOS and/or visionOS Client SDK is supported by Lightstreamer Server license configuration, depending on where the demo will be run.
* For a version of this example compatible with Lightstreamer iOS and watchOS Client SDKs versions up to 5, please refer to [this tag](https://github.com/Lightstreamer/Lightstreamer-example-MPNStockList-client-ios/tree/latest-for-client-5.x).
* For a version of this example compatible with Lightstreamer iOS and watchOS Client SDKs versions up to 4, please refer to [this tag](https://github.com/Lightstreamer/Lightstreamer-example-MPNStockList-client-ios/tree/latest-for-client-4.x).
