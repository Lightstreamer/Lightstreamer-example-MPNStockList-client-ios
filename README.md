# Lightstreamer - Basic Stock-List Demo - iOS Client #

This project contains an example of an application for iPhone and iPad that employs the Lightstreamer iOS Client library.

<table>
  <tr>
    <td style="text-align: left">
      &nbsp;<a href="http://itunes.apple.com/us/app/lightstreamer-stocklist/id430328811#" target="_blank"><img src="screen_iphone.png"></a>&nbsp;
      
    </td>
    <td>
      &nbsp;Click here to download and install the application:<br>
      &nbsp;<a href="http://itunes.apple.com/us/app/lightstreamer-stocklist/id430328811#" target="_blank">http://itunes.apple.com/us/app/lightstreamer-stocklist/id430328811#</a>
    </td>
  </tr>
</table>

This app, compatible with both iPhone and iPad, is an Objective-C version of the [Stock-List Demos](https://github.com/Weswit/Lightstreamer-example-Stocklist-client-javascript).<br>

This app uses the <b>iOS Client API for Lightstreamer</b> to handle the communications with Lightstreamer Server. A simple user interface is implemented to display the real-time data received from Lightstreamer Server.<br>
To install the app from the iTunes Store you can either go to the [iTunes Preview page](http://itunes.apple.com/us/app/lightstreamer-stocklist/id430328811#) and choose "View In iTunes", or open iTunes and search for "Lightstreamer".<br>

# Build #

Binaries for the application are not provided, but it may be downloaded from the App Store at [this address](https://itunes.apple.com/app/lightstreamer-stocklist/id430328811?l=en&mt=8).
Otherwise a full Xcode project specification, ready for a compilation of the demo sources is provided. Please recall that you need a valid iOS Developer Program membership in order to debug or deploy your app on a test device.
Before you can build this demo you should complete this project with the Lighstreamer iOS Client library. Please:
* drop into the "Lightstreamer client for iOS/lib" folder of this project the Lightstreamer_iOS_client.a file from the "/DOCS-SDKs/sdk_client_ios/lib" of [latest Lightstreamer distribution](http://www.lightstreamer.com/download).
* drop into the "Lightstreamer client for iOS/include" folder of this project all the include files from the "/DOCS-SDKs/sdk_client_ios/include" of [latest Lightstreamer distribution](http://www.lightstreamer.com/download).

# Deploy #

With the current settings, the demo tries to connect to the demo server currently running on Lightstreamer website.
The demo can be reconfigured and recompiled in order to connect to the local installation of Lightstreamer Server. You just have to change SERVER_URL, as defined in "Shared/StockListViewController.m"; a ":port" part can also be added.
The example requires that the [QUOTE_ADAPTER](https://github.com/Weswit/Lightstreamer-example-Stocklist-adapter-java) and [LiteralBasedProvider](https://github.com/Weswit/Lightstreamer-example-ReusableMetadata-adapter-java) have to be deployed in your local Lightstreamer server instance. The factory configuration of Lightstreamer server already provides this adapter deployed.<br>

# See Also #

## Lightstreamer Adapters needed by this demo client ##

* [Lightstreamer - Stock- List Demo - Java SE Adapter](https://github.com/Weswit/Lightstreamer-example-Stocklist-adapter-java)
* [Lightstreamer - Reusable Metadata Adapters- Java SE Adapter](https://github.com/Weswit/Lightstreamer-example-ReusableMetadata-adapter-java)

## Similar demo clients that may interest you ##

* [Lightstreamer - Stock-List Demos - HTML Clients](https://github.com/Weswit/Lightstreamer-example-Stocklist-client-javascript)
* [Lightstreamer - Basic Stock-List Demo - OS X Client](https://github.com/Weswit/Lightstreamer-example-StockList-client-osx)
* [Lightstreamer - Basic Stock-List Demo - Android Client](https://github.com/Weswit/Lightstreamer-example-StockList-client-android)
* [Lightstreamer - Basic Stock-List Demo - Windows Phone Client](https://github.com/Weswit/Lightstreamer-example-StockList-client-winphone)
* [Lightstreamer - Basic Stock-List and Round-Trip Demo - BlackBerry Client](https://github.com/Weswit/Lightstreamer-example-StockList-client-blackberry)
* [Lightstreamer - Basic Stock-List Demo jQuery (jqGrid) Client](https://github.com/Weswit/Lightstreamer-example-StockList-client-jquery)
* [Lightstreamer - Stock-List Demo - Dojo Toolkit Client](https://github.com/Weswit/Lightstreamer-example-StockList-client-dojo)
* [Lightstreamer - Basic Stock-List Demo - Java SE (Swing) Client](https://github.com/Weswit/Lightstreamer-example-StockList-client-java)
* [Lightstreamer - Basic Stock-List Demo - .NET Client](https://github.com/Weswit/Lightstreamer-example-StockList-client-dotnet)
* [Lightstreamer - Basic Stock-List Demo - Flex Client](https://github.com/Weswit/Lightstreamer-example-StockList-client-flex)

# Lightstreamer Compatibility Notes #

- Compatible with Lightstreamer iOS Client Library version 1.2 or newer.
- For Lightstreamer Allegro (+ iOS Client API support), Presto, Vivace.
