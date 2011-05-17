// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "LowPassFilter.h"
#import "LevelDetector.h"
#import "LevelDetectorController.h"
#import "LevelDetectorInfoOverlayController.h"
#import "SignalProcessorController.h"
#import "UserSettings.h"

NSString* kLevelDetectorCounterUpdateNotification = @"LevelDetectorCounterUpdateNotification";
NSString* kLevelDetectorCounterKey = @"counter";
NSString* kLevelDetectorRPMKey = @"rpm";

@implementation LevelDetector

@synthesize lowPassFilter, counterDecayFilter, level, rpmScaleFactor;

+ (id)create
{
    return [[[LevelDetector alloc] init] autorelease];
}

- (id)init
{
    if ((self = [super init])) {
        controller = nil;
        infoOverlayController = nil;
	lowPassFilter = nil;
        counterDecayFilter = nil;
        countScale = -1.0;
	[self updateFromSettings];
    }
    return self;
}

- (void)dealloc
{
    self.lowPassFilter = nil;
    self.counterDecayFilter = nil;
    [controller release];
    [infoOverlayController release];
    [super dealloc];
}

- (void)setRpmScaleFactor:(Float32)value
{
    rpmScaleFactor = 1000.0 / value;
}

#pragma mark -
#pragma mark SignalProcessorProtocol

- (void)start
{
}

- (void)stop
{
}

- (void)reset
{
    counter = 0;
    currentEdge = kEdgeKindUnknown;
    [lowPassFilter reset];
    [counterDecayFilter reset];
}

- (SignalProcessorController*)controller
{
    if (controller == nil) {
        controller = [[LevelDetectorController createWithLevelDetector:self] retain];
    }
    
    return controller;
}

- (UIViewController*)infoOverlayController
{
    if (infoOverlayController == nil) {
        infoOverlayController = [[LevelDetectorInfoOverlayController alloc] initWithNibName:@"LevelDetectorInfoOverlay"
                                                                                     bundle:nil];
    }
    
    return infoOverlayController;
}

- (void)updateFromSettings
{
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    
    Float32 newCountScale = 1.0 / [settings floatForKey:kSettingsDetectionsViewUpdateRateKey];
    int decaySeconds = [settings integerForKey:kSettingsLevelDetectorCountsDecayDurationKey] * newCountScale; 
    
    if (counterDecayFilter == nil || decaySeconds != [counterDecayFilter size]) {
        NSNumber* weight = [NSNumber numberWithFloat:1.0/decaySeconds];
        NSMutableArray* weights = [NSMutableArray arrayWithCapacity:decaySeconds];
        while ([weights count] < decaySeconds) {
            [weights addObject:weight];
        }
        
        self.counterDecayFilter = [LowPassFilter createFromArray:weights];
        [self reset];
    }
    
    if ([settings boolForKey:kSettingsLevelDetectorUseLowPassFilterKey] == YES) {
        NSString* fileName = [settings stringForKey:kSettingsLevelDetectorLowPassFilterFileNameKey];
        if (lowPassFilter == nil || [lowPassFilter.fileName isEqualToString:fileName] != YES) {
            self.lowPassFilter = [LowPassFilter createFromFile:fileName];
        }
    }
    else {
        self.lowPassFilter = nil;
    }
    
    self.level = [settings floatForKey:kSettingsLevelDetectorLevelKey];
    self.rpmScaleFactor = [settings floatForKey:kSettingsLevelDetectorScalingKey];
    
    if (countScale != newCountScale) {
        countScale = newCountScale;
        NSLog(@"countScale: %f", countScale);
    }
}

- (NSObject<SampleProcessorProtocol>*)sampleProcessor
{
    return self;
}

- (Float32)lastDetectionValue
{
    Float32 filteredCounter = [counterDecayFilter filter:(counter * countScale)];
    counter = 0;
    return filteredCounter * rpmScaleFactor / 1000.0;
}

#pragma mark -
#pragma mark SampleProcessorProtocol

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
