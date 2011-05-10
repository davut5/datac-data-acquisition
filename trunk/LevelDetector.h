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

/** Simple signal detector that looks for and counts the rising edges of peaks above a user-settable level. Periodically
    reports these peak counts in a notification named kLevelDetectorCounterUpdateNotification.
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
