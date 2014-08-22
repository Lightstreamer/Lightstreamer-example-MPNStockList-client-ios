/*
 *  Constants.h
 *  StockList Demo for iOS
 *
 * Copyright 2013 Weswit Srl
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#define PUSH_SERVER_URL            (@"http://push.lightstreamer.com")
//#define PUSH_SERVER_URL          (@"http://10.0.1.24:8080/")
#define ADAPTER_SET                (@"DEMO")
#define DATA_ADAPTER               (@"QUOTE_ADAPTER")

#define NUMBER_OF_ITEMS            (30)
#define NUMBER_OF_LIST_FIELDS      (4)
#define NUMBER_OF_DETAIL_FIELDS    (11)

#define TABLE_ITEMS                ([NSArray arrayWithObjects:@"item1", @"item2", @"item3", @"item4", @"item5", @"item6", @"item7", @"item8", @"item9", @"item10", @"item11", @"item12", @"item13", @"item14", @"item15", @"item16", @"item17", @"item18", @"item19", @"item20", @"item21", @"item22", @"item23", @"item24", @"item25", @"item26", @"item27", @"item28", @"item29", @"item30", nil])
#define LIST_FIELDS                ([NSArray arrayWithObjects:@"last_price", @"time", @"pct_change", @"stock_name", nil])
#define DETAIL_FIELDS              ([NSArray arrayWithObjects:@"last_price", @"time", @"pct_change", @"bid_quantity", @"bid", @"ask", @"ask_quantity", @"min", @"max", @"open_price", @"stock_name", nil])

#define DEVICE_IPAD                ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
#define DEVICE_XIB(xib)            (DEVICE_IPAD ? [xib stringByAppendingString:@"_iPad"] : [xib stringByAppendingString:@"_iPhone"])

#define NOTIFICATION_APP_MPN       (@"LSAppDidRegisterForMPN")
#define NOTIFICATION_CONN_STATUS   (@"LSConnectionStatusChanged")
#define NOTIFICATION_CONN_ENDED    (@"LSConnectionEnded")
#define NOTIFICATION_CACHE_UPDATED (@"LSMPNSubscriptionCacheUpdated")

#define ALERT_DELAY                (0.250)
#define FLASH_DURATION             (0.150)

#define GREEN_COLOR                ([UIColor colorWithRed:0.5647 green:0.9294 blue:0.5373 alpha:1.0])
#define ORANGE_COLOR               ([UIColor colorWithRed:0.9843 green:0.7216 blue:0.4510 alpha:1.0])

#define DARK_GREEN_COLOR           ([UIColor colorWithRed:0.0000 green:0.6000 blue:0.2000 alpha:1.0])
#define RED_COLOR                  ([UIColor colorWithRed:1.0000 green:0.0706 blue:0.0000 alpha:1.0])

#define LIGHT_ROW_COLOR            ([UIColor colorWithRed:0.9333 green:0.9333 blue:0.9333 alpha:1.0])
#define DARK_ROW_COLOR             ([UIColor colorWithRed:0.8667 green:0.8667 blue:0.9373 alpha:1.0])
#define SELECTED_ROW_COLOR         ([UIColor colorWithRed:0.0000 green:0.0000 blue:1.0000 alpha:1.0])

#define DEFAULT_TEXT_COLOR         ([UIColor colorWithRed:0.0000 green:0.0000 blue:0.0000 alpha:1.0])
#define SELECTED_TEXT_COLOR        ([UIColor colorWithRed:1.0000 green:1.0000 blue:1.0000 alpha:1.0])

#define COLORED_LABEL_TAG          (456)

#define FLIP_DURATION              (0.3)

#define INFO_IPAD_WIDTH            (600.0)
#define INFO_IPAD_HEIGHT           (400.0)

#define STATUS_IPAD_WIDTH          (400.0)
#define STATUS_IPAD_HEIGHT         (200.0)
