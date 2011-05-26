// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SampleProcessorProtocol.h"
#import "SignalProcessorProtocol.h"
#import "WaveCycleDetector.h"

@class PulseWidthDetectorController;
@class WeightedAverager;

@protocol PulseWidthDetectorProtocol
@required

- (void)pulseDetected:(NSUInteger)pulseToPulseWidth filtered:(Float32)filtered;

@end

enum PulseWidthDetectorState {
    kInLowPulse,
    kInHighPulse,
    kUnknownState
};

@interface PulseWidthDetector : NSObject <SignalProcessorProtocol, WaveCycleDetectorObserver> {
@private
    WaveCycleDetector* sampleProcessor;
    PulseWidthDetectorController* controller;
    Float32 minHighPulseAmplitude;
    NSUInteger maxPulseToPulseWidth;
    PulseWidthDetectorState state;
    NSUInteger pulseToPulseWidth;
    WeightedAverager* smoother;
    Float32 currentValue;
    NSObject<PulseWidthDetectorProtocol>* observer;
}

@property (nonatomic, retain) WaveCycleDetector* sampleProcessor;
@property (nonatomic, assign) Float32 lowLevel;
@property (nonatomic, assign) Float32 highLevel;
@property (nonatomic, assign) Float32 minHighPulseAmplitude;
@property (nonatomic, assign) NSUInteger maxPulseToPulseWidth;
@property (nonatomic, retain) NSObject<PulseWidthDetectorProtocol>* observer;
@property (nonatomic, readonly) NSString* smootherValues;
@property (nonatomic, retain) WeightedAverager* smoother;

+ (PulseWidthDetector*)create;

- (id)init;

@end
