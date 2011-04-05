// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* kSignalDetectorCounterUpdateNotification;
extern NSString* kSignalDetectorCounterKey;
extern NSString* kSignalDetectorRPMKey;

@class LowPassFilter;

/** Rising and falling edge detector for a low-level and high-level signals.
    Expects the two signals to be added together with the low-level one at a
    lower amplitude than the high-level one, and with the sum of both within
    [0,1) range in the Q8.24 fixed-point representation
 
    Periodically, an internal timer fires, invoking an internal recalculate
    method that generates a number of counts / second value for the upper and
    lower signal. The recalculate passes these values of to a delegate that
    implements the SignalMeasurementReader protocol.
*/

@interface SignalDetector : NSObject {
@private
    NSTimer* intervalTimer;
    LowPassFilter* lowPassFilter;
    LowPassFilter* counterDecayFilter;
    Float32 level;
    BOOL risingEdge;
    UInt32 counter;
    UInt32 pastSum;
    Float32 rpmScaleFactor;
}

@property (nonatomic, retain) NSTimer* intervalTimer;
@property (nonatomic, retain) LowPassFilter* lowPassFilter;
@property (nonatomic, retain) LowPassFilter* counterDecayFilter;
@property (nonatomic, assign) Float32 level;
@property (nonatomic, assign) UInt32 counter;
@property (nonatomic, assign) Float32 rpmScaleFactor;

+ (SignalDetector*)create;

- (id)init;
- (void)reset;
- (void)start;
- (void)stop;
- (void)addSample:(Float32)sample;
- (void)updateFromSettings;

@end
