//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "AudioSampleBuffer.h"
#import "LowPassFilter.h"
#import "SignalDetector.h"
#import "UserSettings.h"

NSString* kSignalDetectorCounterUpdateNotification = @"SignalDetectorCounterUpdateNotification";
NSString* kSignalDetectorCounterKey = @"counter";
NSString* kSignalDetectorRPMKey = @"rpm";

@interface SignalDetector(Private)
- (void)calculatePerSecondRates;
@end

@implementation SignalDetector

@synthesize intervalTimer, lowPassFilter, counterDecayFilter, level, counter, rpmScaleFactor;

+ (id)create
{
    return [[[SignalDetector alloc] init] autorelease];
}

- (id)init
{
    if ((self = [super init])) {
	self.lowPassFilter = nil;
	self.intervalTimer = nil;
	[self updateFromSettings];
    }
    return self;
}

- (void)updateFromSettings
{
    BOOL wasRunning = NO;
    if (self.intervalTimer != nil) {
	wasRunning = YES;
	[self stop];
    }

    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    self.level = [defaults floatForKey:kSettingsSignalDetectorLevelKey];
    self.rpmScaleFactor = [defaults floatForKey:kSettingsRPMScaleFactorKey];

    int decaySeconds = [defaults integerForKey:kSettingsCounterDecayDurationKey] /
	[[NSUserDefaults standardUserDefaults] floatForKey:kSettingsSignalDetectorUpdateRateKey];

    NSNumber* weight = [NSNumber numberWithFloat:1.0/decaySeconds];
    NSMutableArray* weights = [NSMutableArray arrayWithCapacity:decaySeconds];
    while ([weights count] < decaySeconds) {
	[weights addObject:weight];
    }
    self.counterDecayFilter = [LowPassFilter createFromArray:weights];
	
    if ([defaults boolForKey:kSettingsEnableLowPassFilterKey] == YES) {
	NSString* fileName = [defaults stringForKey:kSettingsTapsFileNameKey];
	if (lowPassFilter == nil || [lowPassFilter.fileName isEqualToString:fileName] != YES) {
	    self.lowPassFilter = [LowPassFilter createFromFile:fileName];
	}
    }
    else {
	self.lowPassFilter = nil;
    }

    if (wasRunning) {
	[self start];
    }
}

- (void)setRpmScaleFactor:(Float32)value
{
    rpmScaleFactor = 1000.0 / value;
}

- (void)dealloc
{
    [intervalTimer invalidate];
    self.intervalTimer = nil;
    self.lowPassFilter = nil;
    self.counterDecayFilter = nil;
    [super dealloc];
}

- (void)reset
{
    counter = 0;
    risingEdge = NO;
    [lowPassFilter reset];
    [counterDecayFilter reset];
}

- (void)start
{
    Float32 interval = [[NSUserDefaults standardUserDefaults] floatForKey:kSettingsSignalDetectorUpdateRateKey];
    NSLog(@"start: interval = %f", interval);
    [self reset];
    self.intervalTimer = [NSTimer scheduledTimerWithTimeInterval:interval
							  target:self 
							selector:@selector(calculatePerSecondRates)
							userInfo:nil 
							 repeats:YES];
}

- (void)stop
{
    [self.intervalTimer invalidate];
    self.intervalTimer = nil;
}

- (void)addSample:(Float32)sample
{
    if (lowPassFilter != nil) {
	sample = [lowPassFilter filter:sample];
    }

    if (sample >= level) {
	if (risingEdge == NO) {
	    risingEdge = YES;
	    ++counter;
	}
    }
    else {
	if (risingEdge == YES) risingEdge = NO;
    }
}

@end

@implementation SignalDetector(Private)

- (void)calculatePerSecondRates
{
    if (intervalTimer == nil) return;

    Float32 filteredCounter = [counterDecayFilter filter: counter * 4];
    counter = 0;
    NSDictionary* userDict = [NSDictionary dictionaryWithObjectsAndKeys:
					      [NSNumber numberWithFloat:filteredCounter], kSignalDetectorCounterKey,
					      [NSNumber numberWithFloat:(filteredCounter * rpmScaleFactor)/1000.0], kSignalDetectorRPMKey,
					   nil];

    [[NSNotificationCenter defaultCenter] postNotificationName:kSignalDetectorCounterUpdateNotification
							object:self 
						      userInfo:userDict];
}

@end
