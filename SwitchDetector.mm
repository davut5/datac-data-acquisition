//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "SwitchDetector.h"
#import "UserSettings.h"

@implementation SwitchDetector

@synthesize threshold, downDuration, pressed, delegate;

+ (id)createWithSampleRate:(Float32)sampleRate
{
    return [[[SwitchDetector alloc] initWithSampleRate:sampleRate] autorelease];
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

- (void)setThreshold:(Float32)value
{
    NSLog(@"setThreshold: %f", value);
    threshold = value;
}

- (void)setDownDuration:(Float32)value
{
    NSLog(@"setDuration: %f, %d", value, samples);
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

- (void)addSample:(Float32)sample
{
    sample = fabs(sample);
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

- (void)updateFromSettings
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    self.threshold = [defaults floatForKey:kSettingsSwitchDetectorThresholdKey];
    self.downDuration = [defaults floatForKey:kSettingsSwitchDetectorDurationKey];
    [self reset];
}

@end
