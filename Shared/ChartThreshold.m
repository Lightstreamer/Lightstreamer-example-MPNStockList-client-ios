//
//  ChartThreshold.m
//  StockList Demo for iOS
//
//  Created by Gianluca Bertani on 26/02/14.
//  Copyright (c) Lightstreamer Srl
//

#import "ChartThreshold.h"
#import "ChartView.h"


@implementation ChartThreshold


#pragma mark -
#pragma mark Initialization

- (id) initWithView:(ChartView *)chartView value:(float)value {
	if ((self = [super init])) {

		// Initialization
		_chartView= chartView;

		_value= value;
	}
	
	return self;
}


#pragma mark -
#pragma mark Deletion

- (void) remove {
	[_chartView removeThreshold:self];
}


#pragma mark -
#pragma mark Properties

@synthesize chartView= _chartView;

@dynamic value;

- (float) value {
	return _value;
}

- (void) setValue:(float)value {
	_value= value;
	
	[_chartView setNeedsDisplay];
}

@synthesize mpnSubscription= _mpnSubscription;


@end
