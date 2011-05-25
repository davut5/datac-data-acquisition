//
//  PulseFrequencyDetector.mm
//  Datac
//
//  Created by Brad Howes on 5/25/11.
//  Copyright 2011 Brad Howes. All rights reserved.
//

#import "PulseFrequencyDetector.h"
#import "PulseFrequencyDetectorController.h"
#import "WeightedAverager.h"

@implementation PulseFrequencyDetector

@synthesize sampleProcessor, lowLevel, highLevel, observer, minHighPulseAmplitude;

+ (PulseFrequencyDetector*)create
{
    return [[[PulseFrequencyDetector alloc] init] autorelease];
}

- (id)init
{
    if (self = [super init]) {
        self.sampleProcessor = [WaveCycleDetector createWithLowLevel:-0.33 highLevel:0.33];
        sampleProcessor.observer = self;
        controller = nil;
        smoother = [[WeightedAverager createForSize:3] retain];
        observer = nil;
        [self updateFromSettings];
    }

    return self;
}

- (void)dealloc
{
    self.sampleProcessor = nil;
    [controller release];
    self.observer = nil;
    [super dealloc];
}

- (void)updateFromSettings
{
    [self reset];
}

- (void)reset
{
    [sampleProcessor reset];
    state = kUnknownState;
    pulseToPulseWidth = 0;
    currentValue = 0.0;
}

- (Float32)lowLevel
{
    return sampleProcessor.lowLevel;
}

- (void)setLowLevel:(Float32)value
{
    sampleProcessor.lowLevel = value;
}

- (Float32)highLevel
{
    return sampleProcessor.highLevel;
}

- (void)setHighLevel:(Float32)value
{
    sampleProcessor.highLevel = value;
}

- (SignalProcessorController*)controller
{
    if (controller == nil) {
        controller = [[PulseFrequencyDetectorController createWithDetector:self] retain];
    }
    
    return controller;
}

- (Float32)updatedDetectionValue
{
    return currentValue;
}

- (void)waveCycleDetected:(WaveCycleDetectorInfo*)info
{
    if (info.amplitude >= minHighPulseAmplitude) {
        if (state != kInHighPulse) {
            if (state == kInLowPulse) {

                //
                // We have a valid pulse-to-pulse detection.
                //
                currentValue = [smoother filter:pulseToPulseWidth];
                if (observer) {
                    [observer pulseDetected:pulseToPulseWidth filtered:currentValue];
                }
            }

            state = kInHighPulse;
            pulseToPulseWidth = 0;
        }
    }
    else {
        if (state != kInLowPulse) {
            if (state == kInHighPulse) {
                state = kInLowPulse;
            }
        }
    }

    pulseToPulseWidth += info.sampleCount;
}

@end
