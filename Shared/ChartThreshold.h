//
//  ChartThreshold.h
//  StockList Demo for iOS
//
//  Created by Gianluca Bertani on 26/02/14.
//  Copyright (c) Lightstreamer Srl
//

#import <Foundation/Foundation.h>


@class ChartView;

@interface ChartThreshold : NSObject {
	__weak ChartView *_chartView;
	
	LSMPNSubscription *_mpnSubscription;
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
@property (nonatomic, strong) LSMPNSubscription *mpnSubscription;


@end
