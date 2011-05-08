//
//  ZeroCrossingDetector.mm
//  Datac
//
//  Created by Brad Howes on 4/28/11.
//  Copyright 2011 Skype. All rights reserved.
//

#import "UserSettings.h"
#import "WaveCycleDetector.h"

@implementation WaveCycleDetector

@synthesize observer, level;

+ (WaveCycleDetector*)createWithLevel:(Float32)theLevel
{
    return [[[WaveCycleDetector alloc] initWithLevel:theLevel] autorelease];
}

- (id)initWithLevel:(Float32)theLevel
{
    if (self = [super init]) {
        self.level = theLevel;
    }
    
    return self;
}

- (void)setLevel:(Float32)theLevel
{
    posLevel = theLevel;
    negLevel = -theLevel;
    [self reset];
}

- (void)addSamples:(Float32*)ptr count:(UInt32)count
{
    while (count-- > 0) {
        Float32 sample = *ptr++;
        ++sampleCount;
        if (sample >= posLevel) {
            if (state != kPosValue) {
                if (state == kNegValue) {

                    //
                    // Finished rising edge detection
                    //
                    [observer performSelectorOnMainThread:@selector(waveCycleDetected:)
                                               withObject:[NSNumber numberWithUnsignedInteger:sampleCount]
                                            waitUntilDone:NO];
                }

                state = kPosValue;
                sampleCount = 0;
            }
        }
        else if (sample <= negLevel) {
            state = kNegValue;
        }
    }
}

- (void)reset
{
    state = kUnknownValue;
    sampleCount = 0;
}

- (void)updateFromSettings
{
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    posLevel = [settings floatForKey:kSettingsWaveCycleDetectorNonZeroLevelKey];
    negLevel = -posLevel;
    [self reset];
}

@end
