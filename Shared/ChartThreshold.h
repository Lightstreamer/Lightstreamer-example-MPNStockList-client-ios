//
//  ChartThreshold.h
//  StockList Demo for iOS
//
//  Created by Gianluca Bertani on 26/02/14.
//  Copyright (c) 2014 Weswit srl. All rights reserved.
//

#import <Foundation/Foundation.h>


@class ChartView;

@interface ChartThreshold : NSObject {
	__weak ChartView *_chartView;
	
	NSString *_thresholdId;
	float _value;
}


#pragma mark -
#pragma mark Initialization

- (id) initWithView:(ChartView *) chartView value:(float)value;


#pragma mark -
#pragma mark Removal

- (void) remove;


#pragma mark -
#pragma mark Properties

@property (nonatomic, readonly) ChartView *chartView;
@property (nonatomic, assign) float value;
@property (nonatomic, copy) NSString *thresholdId;


@end
