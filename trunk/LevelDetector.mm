// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "LowPassFilter.h"
#import "LevelDetector.h"
#import "LevelDetectorController.h"
#import "UserSettings.h"

NSString* kLevelDetectorCounterUpdateNotification = @"LevelDetectorCounterUpdateNotification";
NSString* kLevelDetectorCounterKey = @"counter";
NSString* kLevelDetectorRPMKey = @"rpm";

@interface LevelDetector(Private)
- (void)calculatePerSecondRates;
@end

@implementation LevelDetector

@synthesize intervalTimer, lowPassFilter, counterDecayFilter, level, rpmScaleFactor;

+ (id)create
{
    return [[[LevelDetector alloc] init] autorelease];
}

- (id)init
{
    if ((self = [super init])) {
        controller = nil;
	intervalTimer = nil;
	lowPassFilter = nil;
        counterDecayFilter = nil;
        countScale = -1.0;
	[self updateFromSettings];
    }
    return self;
}

- (void)dealloc
{
    [intervalTimer invalidate];
    self.intervalTimer = nil;
    self.lowPassFilter = nil;
    self.counterDecayFilter = nil;
    [controller release];
    [super dealloc];
}

- (void)setRpmScaleFactor:(Float32)value
{
    rpmScaleFactor = 1000.0 / value;
}

- (void)start
{
    Float32 interval = [[NSUserDefaults standardUserDefaults] floatForKey:kSettingsLevelDetectorUpdateRateKey];
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
    [intervalTimer invalidate];
    self.intervalTimer = nil;
}

#pragma mark -
#pragma mark SampleProcessorProtocol

- (void)reset
{
    counter = 0;
    currentEdge = kEdgeKindUnknown;
    [lowPassFilter reset];
    [counterDecayFilter reset];
}

- (void)updateFromSettings
{
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    
    Float32 newCountScale = 1.0 / [settings floatForKey:kSettingsLevelDetectorUpdateRateKey];
    int decaySeconds = [settings integerForKey:kSettingsCounterDecayDurationKey] * newCountScale; 
    
    if (counterDecayFilter == nil || decaySeconds != [counterDecayFilter size]) {
        NSNumber* weight = [NSNumber numberWithFloat:1.0/decaySeconds];
        NSMutableArray* weights = [NSMutableArray arrayWithCapacity:decaySeconds];
        while ([weights count] < decaySeconds) {
            [weights addObject:weight];
        }
        
        self.counterDecayFilter = [LowPassFilter createFromArray:weights];
        [self reset];
    }
    
    if ([settings boolForKey:kSettingsEnableLowPassFilterKey] == YES) {
        NSString* fileName = [settings stringForKey:kSettingsTapsFileNameKey];
        if (lowPassFilter == nil || [lowPassFilter.fileName isEqualToString:fileName] != YES) {
            self.lowPassFilter = [LowPassFilter createFromFile:fileName];
        }
    }
    else {
        self.lowPassFilter = nil;
    }
    
    self.level = [settings floatForKey:kSettingsLevelDetectorLevelKey];
    self.rpmScaleFactor = [settings floatForKey:kSettingsRPMScaleFactorKey];
    
    if (countScale != newCountScale) {
        countScale = newCountScale;
        NSLog(@"countScale: %f", countScale);
        if (intervalTimer) {
            [self stop];
            [self start];
        }
    }
}

- (DetectorController*)controller
{
    if (controller == nil) {
        controller = [[LevelDetectorController createWithLevelDetector:self] retain];
    }

    return controller;
}

- (void)addSamples:(Float32*)ptr count:(UInt32)count
{
    while (count-- > 0) {
        Float32 sample = *ptr++;
        if (lowPassFilter != nil) {
            sample = [lowPassFilter filter:sample];
        }
        
        if (sample >= level) {
            if (currentEdge != kEdgeKindRising) {
                currentEdge = kEdgeKindRising;
                ++counter;
            }
        }
        else {
            if (currentEdge != kEdgeKindFalling) {
                currentEdge = kEdgeKindFalling;
            }
        }
    }
}

@end

@implementation LevelDetector(Private)

- (void)calculatePerSecondRates
{
    if (intervalTimer == nil) return;
    Float32 filteredCounter = [counterDecayFilter filter:(counter * countScale)];
    counter = 0;
    NSDictionary* userDict = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithFloat:filteredCounter], kLevelDetectorCounterKey,
                              [NSNumber numberWithFloat:(filteredCounter * rpmScaleFactor)/1000.0], 
                              kLevelDetectorRPMKey, nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:kLevelDetectorCounterUpdateNotification
							object:self 
						      userInfo:userDict];
}

@end
