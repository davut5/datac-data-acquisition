// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "UserSettings.h"
#import "WaveCycleDetector.h"

@implementation WaveCycleDetectorInfo

@synthesize sampleCount, minValue, maxValue, amplitude;

- (id)init
{
    if (self = [super init]) {
        minValue = 0;
        maxValue = 0;
        sampleCount = 0;
    }

    return self;
}

- (Float32)amplitude
{
    return maxValue - minValue;
}

- (void)addSample:(Float32)value
{
    if (sampleCount++ == 0) {
        minValue = value;
        maxValue = value;
    }
    else if (value < minValue) {
        minValue = value;
    }
    else if (value > maxValue) {
        maxValue = value;
    }
}

@end

@implementation WaveCycleDetector

@synthesize lowLevel, highLevel, info, observer;

+ (WaveCycleDetector*)createWithLowLevel:(Float32)theLowLevel highLevel:(Float32)theHighLevel
{
    return [[[WaveCycleDetector alloc] initWithLowLevel:theLowLevel highLevel:theHighLevel] autorelease];
}

- (id)initWithLowLevel:(Float32)theLowLevel highLevel:(Float32)theHighLevel
{
    if (self = [super init]) {
        lowLevel = theLowLevel;
        highLevel = theHighLevel;
        self.info = [[[WaveCycleDetectorInfo alloc] init] autorelease];
        [self reset];
    }

    return self;
}

- (void)addSamples:(Float32*)ptr count:(UInt32)count
{
    while (count-- > 0) {
        Float32 sample = *ptr++;
        [info addSample:sample];
        if (sample >= highLevel) {
            if (state != kRisingEdge) {
                if (state == kFallingEdge) {

                    //
                    // Finished cycle detection.
                    //
#ifdef UNIT_TESTING
                    [observer waveCycleDetected:info];
                    self.info = [[[WaveCycleDetectorInfo alloc] init] autorelease];
#else
                    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
                    [observer performSelectorOnMainThread:@selector(waveCycleDetected:)
                                               withObject:info
                                            waitUntilDone:NO];
                    self.info = [[[WaveCycleDetectorInfo alloc] init] autorelease];
                    [pool drain];
#endif
                }

                state = kRisingEdge;
            }
        }
        else if (sample <= lowLevel) {
            state = kFallingEdge;
        }
    }
}

- (void)reset
{
    state = kUnknownValue;
    info.sampleCount = 0;
}

@end
