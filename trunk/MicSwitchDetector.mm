// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "MicSwitchDetector.h"
#import "UserSettings.h"

@implementation MicSwitchDetector

@synthesize threshold, downDuration, pressed, delegate;

+ (id)createWithSampleRate:(Float32)sampleRate
{
    return [[[MicSwitchDetector alloc] initWithSampleRate:sampleRate] autorelease];
}

- (id)initWithSampleRate:(Float32)theSampleRate
{
    if ((self = [super init])) {
        delegate = nil;
        sampleRate = theSampleRate;
        [self updateFromSettings];
    }
	
    return self;
}

- (void)setDownDuration:(Float32)value
{
    downDuration = value;
    samples = value * sampleRate;
}

- (void)setPressed:(BOOL)state
{
    if (pressed != state) {
        pressed = state;
        [delegate performSelectorOnMainThread:@selector(switchStateChanged:) withObject:self waitUntilDone:NO];
    }
}

- (void)reset
{
    counter = 0;
    pressed = NO;
}

- (void)addSamples:(Float32*)ptr count:(UInt32)count
{
    while (count-- > 0) {
        Float32 sample = fabs(*ptr++);
        if (sample <= threshold) {
            if (pressed == NO) {
                ++counter;
                if (counter == samples) {
                    self.pressed = YES;
                }
            }
        }
        else {
            counter = 0;
            if (pressed == YES) {
                self.pressed = NO;
            }
        }
    }
}

- (void)updateFromSettings
{
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    self.threshold = [settings floatForKey:kSettingsMicSwitchDetectorThresholdKey];
    self.downDuration = [settings floatForKey:kSettingsMicSwitchDetectorDurationKey];
    [self reset];
}

@end
