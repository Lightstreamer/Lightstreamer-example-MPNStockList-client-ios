//
//  ChartViewController.m
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

#import "ChartViewController.h"
#import "ChartViewDelegate.h"
#import "ChartView.h"

#define TAP_SENSIBILITY_PIXELS              (20.0)


@implementation ChartViewController


#pragma mark -
#pragma mark Initialization

- (id) initWithDelegate:(id <ChartViewDelegate>)delegate {
    self = [super init];
    if (self) {
		
        // Initialization
		_delegate= delegate;
		
		_currentThresholdIsNew= NO;
		_currentThresholdIndex= NSNotFound;
    }
	
    return self;
}


#pragma mark -
#pragma mark Methods of UIViewController

- (void) loadView {
	_chartView= [[ChartView alloc] initWithFrame:CGRectZero];
	
	self.view= _chartView;
}


#pragma mark -
#pragma mark Chart management

- (void) clearChart {
	[self clearChartWithMin:0.0 max:0.0 time:[NSDate timeIntervalSinceReferenceDate] value:0.0];
}

- (void) clearChartWithMin:(float)min max:(float)max time:(NSTimeInterval)time value:(float)value {
	[_chartView clearValues];
	[_chartView clearThresholds];
	
	_chartView.min= min;
	_chartView.max= max;
	_chartView.end= time;
	_chartView.begin= time - 120.0;
	
	if (value != 0.0)
		[_chartView addValue:value withTime:time];
}

- (int) addThreshold:(float)value {
	return [_chartView addThreshold:value];
}

- (void) setThreshold:(float)value atIndex:(int)index {
	[_chartView setThreshold:value atIndex:index];
}

- (void) removeThresholdAtIndex:(int)index {
	[_chartView removeThresholdAtIndex:index];
}

- (void) clearThresholds {
	[_chartView clearThresholds];
}


#pragma mark -
#pragma mark User interaction

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	if ([touches count] > 1) {
		[super touchesBegan:touches withEvent:event];
		return;
	}
	
	UITouch *touch= [touches anyObject];
	CGPoint point= [touch locationInView:_chartView];

	// Transalte Y coordinate in Y value
	CGPoint valueTime= [_chartView valueAtPoint:point];
	_currentThresholdValue= valueTime.y;
	
	// Compute approximate value-width of a common tap (40 pixel)
	float tapWidth= ((_chartView.max - _chartView.min) / _chartView.frame.size.height) * TAP_SENSIBILITY_PIXELS;
	
	// Check if we are tapping an existing threshold
	int index= 0;
	NSArray *thresholds= [_chartView thresholds];
	for (NSNumber *threshold in thresholds) {
		if (ABS([threshold floatValue] - _currentThresholdValue) < tapWidth) {
			_currentThresholdIndex= index;
			break;
		}
		
		index++;
	}
	
	if (_currentThresholdIndex == NSNotFound) {
		_currentThresholdIsNew= YES;
		_currentThresholdIndex= [_chartView addThreshold:_currentThresholdValue];
	}
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	if ([touches count] > 1) {
		[super touchesMoved:touches withEvent:event];
		return;
	}
	
	UITouch *touch= [touches anyObject];
	CGPoint point= [touch locationInView:_chartView];
	
	// Transalte Y coordinate in Y value
	CGPoint valueTime= [_chartView valueAtPoint:point];
	_currentThresholdValue= valueTime.y;
	
	[_chartView setThreshold:_currentThresholdValue atIndex:_currentThresholdIndex];
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	if ([touches count] > 1) {
		[super touchesEnded:touches withEvent:event];
		return;
	}
	
	if ((_currentThresholdValue > _chartView.max) || (_currentThresholdValue < _chartView.min)) {
		[_chartView removeThresholdAtIndex:_currentThresholdIndex];
		
		// Notify the delegate
        if (!_currentThresholdIsNew)
            [_delegate chart:self didRemoveThresholdWithIndex:_currentThresholdIndex];
	
	} else {
		
		// Notify the delegate
		if (_currentThresholdIsNew)
			[_delegate chart:self didAddThresholdWithIndex:_currentThresholdIndex value:_currentThresholdValue];
		else
			[_delegate chart:self didChangeThresholdWithIndex:_currentThresholdIndex newValue:_currentThresholdValue];
	}
	
	// Cleanup
	_currentThresholdIsNew= NO;
	_currentThresholdIndex= NSNotFound;
}


#pragma mark -
#pragma mark Updates from Lightstreamer

- (void) itemDidUpdateWithInfo:(LSUpdateInfo *)updateInfo {
	
	// Extract last point data
	NSDateFormatter *formatter= [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"HH:mm:ss"];
	
	NSTimeInterval time= [[formatter dateFromString:[updateInfo currentValueOfFieldName:@"time"]] timeIntervalSinceReferenceDate];
	float value= [[updateInfo currentValueOfFieldName:@"last_price"] floatValue];
	float min= [[updateInfo currentValueOfFieldName:@"min"] floatValue];
	float max= [[updateInfo currentValueOfFieldName:@"max"] floatValue];
	
	// Update chart
	_chartView.min= min;
	_chartView.max= max;
	_chartView.end= time;
	_chartView.begin= time - 120.0;

	[_chartView addValue:value withTime:time];
}


@end
