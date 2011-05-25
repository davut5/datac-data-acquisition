//
//  PulseFrequencyDetector.h
//  Datac
//
//  Created by Brad Howes on 5/25/11.
//  Copyright 2011 Brad Howes. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SampleProcessorProtocol.h"
#import "SignalProcessorProtocol.h"
#import "WaveCycleDetector.h"

@class PulseFrequencyDetectorController;
@class WeightedAverager;

@protocol PulseFrequencyDetectorProtocol
@required

- (void)pulseDetected:(NSUInteger)pulseToPulseWidth filtered:(Float32)filtered;

@end

enum PulseFrequencyDetectorState {
    kInLowPulse,
    kInHighPulse,
    kUnknownState
};

@interface PulseFrequencyDetector : NSObject <SignalProcessorProtocol, WaveCycleDetectorObserver> {
@private
    WaveCycleDetector* sampleProcessor;
    PulseFrequencyDetectorController* controller;
    Float32 minHighPulseAmplitude;
    NSUInteger maxPulseToPulseWidth;
    PulseFrequencyDetectorState state;
    NSUInteger pulseToPulseWidth;
    WeightedAverager* smoother;
    Float32 currentValue;
    NSObject<PulseFrequencyDetectorProtocol>* observer;
}

@property (nonatomic, retain) WaveCycleDetector* sampleProcessor;
@property (nonatomic, assign) Float32 lowLevel;
@property (nonatomic, assign) Float32 highLevel;
@property (nonatomic, assign) Float32 minHighPulseAmplitude;
@property (nonatomic, assign) NSUInteger maxPulseToPulseWidth;
@property (nonatomic, retain) NSObject<PulseFrequencyDetectorProtocol>* observer;
@property (nonatomic, readonly) NSString* smootherValues;
@property (nonatomic, retain) WeightedAverager* smoother;

+ (PulseFrequencyDetector*)create;

- (id)init;

@end
