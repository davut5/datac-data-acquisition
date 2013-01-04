// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "PulseWidthDetector.h"
#import "PulseWidthDetectorController.h"
#import "RunningAverager.h"
#import "UserSettings.h"

@implementation PulseWidthDetector

@synthesize sampleProcessor, lowLevel, highLevel, observer, minHighPulseAmplitude, smoother, smootherValues;
@synthesize maxPulseToPulseWidth;

+ (PulseWidthDetector*)create
{
    return [[[PulseWidthDetector alloc] init] autorelease];
}

- (id)init
{
    if (self = [super init]) {
        self.sampleProcessor = [WaveCycleDetector createWithLowLevel:-0.33 highLevel:0.33];
        sampleProcessor.observer = self;
        controller = nil;
        observer = nil;
        maxPulseToPulseWidth = 22000;   // 0.5 seconds of samples
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
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    self.lowLevel = [settings floatForKey:kSettingsPulseWidthDetectorLowLevelKey];
    self.highLevel = [settings floatForKey:kSettingsPulseWidthDetectorHighLevelKey];
    self.minHighPulseAmplitude = [settings floatForKey:kSettingsPulseWidthDetectorMinHighAmplitudeKey];
    self.smoother = [RunningAverager createForSize:[settings integerForKey:kSettingsPulseWidthDetectorSmoothingKey]];
    [self reset];
}

- (void)reset
{
    [sampleProcessor reset];
    [smoother reset];
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
        controller = [[PulseWidthDetectorController createWithDetector:self] retain];
    }
    
    return controller;
}

- (NSString*)smootherValues
{
    return [smoother description];
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
                if (pulseToPulseWidth < maxPulseToPulseWidth) {
                    currentValue = [smoother filter:pulseToPulseWidth];
                    LOG(@"pulseToPulseWidth: %d  smoothed: %f", pulseToPulseWidth, currentValue);
                    if (observer) {
                        [observer pulseDetected:pulseToPulseWidth filtered:currentValue];
                    }
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
