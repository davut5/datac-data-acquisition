// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SampleProcessorProtocol.h"
#import "SignalProcessorProtocol.h"

extern NSString* kLevelDetectorCounterUpdateNotification;
extern NSString* kLevelDetectorCounterKey;
extern NSString* kLevelDetectorRPMKey;

@class LevelDetectorController;
@class LevelDetectorInfoOverlayController;
@class LowPassFilter;

enum EdgeKind {
    kEdgeKindUnknown,
    kEdgeKindRising,
    kEdgeKindFalling
};

/** Rising and falling edge detector for a low-level and high-level signals.
    Expects the two signals to be added together with the low-level one at a
    lower amplitude than the high-level one, and with the sum of both within
    [0,1) range in the Q8.24 fixed-point representation
 
    Periodically, an internal timer fires, invoking an internal recalculate
    method that generates a number of counts / second value for the upper and
    lower signal. The recalculate passes these values of to a delegate that
    implements the SignalMeasurementReader protocol.
*/

@interface LevelDetector : NSObject <SampleProcessorProtocol, SignalProcessorProtocol> {
@private
    LevelDetectorController* controller;
    LevelDetectorInfoOverlayController* infoOverlayController;
    NSTimer* intervalTimer;
    LowPassFilter* lowPassFilter;
    LowPassFilter* counterDecayFilter;
    Float32 level;
    EdgeKind currentEdge;
    UInt32 counter;
    Float32 rpmScaleFactor;
    Float32 countScale;
}

@property (nonatomic, retain) NSTimer* intervalTimer;
@property (nonatomic, retain) LowPassFilter* lowPassFilter;
@property (nonatomic, retain) LowPassFilter* counterDecayFilter;
@property (nonatomic, assign) Float32 level;
@property (nonatomic, assign) Float32 rpmScaleFactor;

+ (LevelDetector*)create;

- (id)init;

@end
