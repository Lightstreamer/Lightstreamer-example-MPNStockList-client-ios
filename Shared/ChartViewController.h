//
//  ChartViewController.h
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

#import <UIKit/UIKit.h>


@class ChartView;
@class ChartThreshold;
@protocol ChartViewDelegate;

@interface ChartViewController : UIViewController {
	ChartView *_chartView;
	id <ChartViewDelegate> _delegate;
	
	ChartThreshold *_currentThreshold;
	BOOL _currentThresholdIsNew;
	
	NSDateFormatter *_timeFormatter;
	NSDate *_referenceDate;
}


#pragma mark -
#pragma mark Initialization

- (id) initWithDelegate:(id <ChartViewDelegate>)delegate;


#pragma mark -
#pragma mark Chart management

- (void) clearChart;
- (void) clearChartWithMin:(float)min max:(float)max time:(NSTimeInterval)time value:(float)value;

- (ChartThreshold *) addThreshold:(float)value;
- (void) removeThreshold:(ChartThreshold *)threshold;
- (void) clearThresholds;


#pragma mark -
#pragma mark Updates from Lightstreamer

- (void) itemDidUpdateWithInfo:(LSUpdateInfo *)updateInfo;



@end
