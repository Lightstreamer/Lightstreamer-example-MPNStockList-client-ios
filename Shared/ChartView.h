//
//  ChartView.h
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


@class ChartThreshold;

@interface ChartView : UIView {
	NSMutableArray *_data;
	
	float _min;
	float _max;
	NSTimeInterval _begin;
	NSTimeInterval _end;
	
	NSMutableArray *_thresholds;
}


#pragma mark -
#pragma mark Data management

- (void) addValue:(float)value withTime:(NSTimeInterval)time;
- (void) clearValues;


#pragma mark -
#pragma mark Threshold management

- (ChartThreshold *) addThreshold:(float)value;
- (ChartThreshold *) findThresholdWithin:(float)margin fromValue:(float)value;
- (void) removeThreshold:(ChartThreshold *)threshold;
- (void) clearThresholds;


#pragma mark -
#pragma mark Coordinates managements

- (CGPoint) valueAtPoint:(CGPoint)point;
- (CGPoint) pointForValue:(CGPoint)point;


#pragma mark -
#pragma mark Properties

@property (nonatomic, assign) float min;
@property (nonatomic, assign) float max;
@property (nonatomic, assign) NSTimeInterval begin;
@property (nonatomic, assign) NSTimeInterval end;


@end
