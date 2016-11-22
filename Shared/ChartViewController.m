//
//  ChartViewController.m
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

#import "ChartViewController.h"
#import "ChartViewDelegate.h"
#import "ChartView.h"
#import "ChartThreshold.h"

#define SERVER_TIMEZONE                     (@"Europe/Dublin")

#define TAP_SENSIBILITY_PIXELS              (20.0)


@implementation ChartViewController


#pragma mark -
#pragma mark Initialization

- (id) initWithDelegate:(id <ChartViewDelegate>)delegate {
    self = [super init];
    if (self) {
		
        // Initialization
		_delegate= delegate;
		
		// Prepare reference date (release date of SDK 1.3 a1)
		NSCalendar *calendar= [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
		[calendar setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];

		NSDateComponents *comps= [[NSDateComponents alloc] init];
		[comps setDay:19];
		[comps setMonth:2];
		[comps setYear:2014];
		_referenceDate= [calendar dateFromComponents:comps];
		
		// Prepare time parser
		_timeFormatter= [[NSDateFormatter alloc] init];
		[_timeFormatter setDateFormat:@"HH:mm:ss"];
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
	[self clearChartWithMin:0.0 max:0.0 time:[[NSDate date] timeIntervalSinceDate:_referenceDate] value:0.0];
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

- (ChartThreshold *) addThreshold:(float)value {
	return [_chartView addThreshold:value];
}

- (void) removeThreshold:(ChartThreshold *)threshold {
	[_chartView removeThreshold:threshold];
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
	
	// Compute approximate value-width of a common tap (40 pixel)
	float tapWidth= ((_chartView.max - _chartView.min) / _chartView.frame.size.height) * TAP_SENSIBILITY_PIXELS;
	
	// Check if we are tapping an existing threshold
	_currentThreshold= [_chartView findThresholdWithin:tapWidth fromValue:valueTime.y];
	if (!_currentThreshold) {
		
		// Create new threshold
		_currentThresholdIsNew= YES;
		_currentThreshold= [_chartView addThreshold:valueTime.y];
	
	} else
		_currentThresholdIsNew= NO;
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
	
	// Update threshold (updates view)
	_currentThreshold.value= valueTime.y;
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	if ([touches count] > 1) {
		[super touchesEnded:touches withEvent:event];
		return;
	}
	
	if ((_currentThreshold.value > _chartView.max) || (_currentThreshold.value < _chartView.min)) {
		[_currentThreshold remove];
		
		// Notify the delegate
		if (!_currentThresholdIsNew)
			[_delegate chart:self didRemoveThreshold:_currentThreshold];
	
	} else {
		
		// Notify the delegate
		if (_currentThresholdIsNew)
			[_delegate chart:self didAddThreshold:_currentThreshold];
		else
			[_delegate chart:self didChangeThreshold:_currentThreshold];
	}
}


#pragma mark -
#pragma mark Updates from Lightstreamer

- (void) itemDidUpdateWithInfo:(LSUpdateInfo *)updateInfo {
	
	// Extract last point time
	NSString *timeString= [updateInfo currentValueOfFieldName:@"time"];
	NSDate *updateTime= [_timeFormatter dateFromString:timeString];
	
	// Compute the full date knowing the Server lives in the West European time zone
	// (which is not simply GMT, as it may undergo daylight savings)
	NSCalendar *calendar= [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
	NSTimeZone *timeZone= [NSTimeZone timeZoneWithName:SERVER_TIMEZONE];
	[calendar setTimeZone:timeZone];
	
	NSDateComponents *nowComponents= [calendar components:(NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear) fromDate:[NSDate date]];
	NSDateComponents *timeComponents=[calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond) fromDate:updateTime];
	
	NSDateComponents *dateComponents= [[NSDateComponents alloc] init];
	[dateComponents setTimeZone:timeZone]; // The timezone is known a-priori
	[dateComponents setYear:nowComponents.year]; // Take the current day
	[dateComponents setMonth:nowComponents.month];
	[dateComponents setDay:nowComponents.day];
	[dateComponents setHour:timeComponents.hour]; // Take the time of the update
	[dateComponents setMinute:timeComponents.minute];
	[dateComponents setSecond:timeComponents.second];
	
	NSDate *updateDate= [calendar dateFromComponents:dateComponents];
	NSTimeInterval time= [updateDate timeIntervalSinceDate:_referenceDate];
	
	// Extract last point data
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
