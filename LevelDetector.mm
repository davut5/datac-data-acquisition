// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <iterator>
#import <sstream>

#import "AboveLevelCounter.h"
#import "LowPassFilter.h"
#import "LevelDetector.h"
#import "LevelDetectorController.h"
#import "SignalProcessorController.h"
#import "UserSettings.h"

@implementation LevelDetector

@synthesize sampleProcessor, counterDecayFilter, level, detectionScale, counterScale, lastDetection;

+ (id)create
{
    return [[[LevelDetector alloc] init] autorelease];
}

- (id)init
{
    if ((self = [super init])) {
        self.sampleProcessor = [AboveLevelCounter createWithLevel:0.0];
        controller = nil;
        counterDecayFilter = nil;
        counterScale = -1.0;
        counterHistory.clear();
	[self updateFromSettings];
    }
    return self;
}

- (void)dealloc
{
    self.sampleProcessor = nil;
    self.counterDecayFilter = nil;
    [controller release];
    counterHistory.clear();
    [super dealloc];
}

#pragma mark -
#pragma mark SignalProcessorProtocol

- (void)updateFromSettings
{
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    
    counterScale = [settings floatForKey:kSettingsDetectionsViewUpdateRateKey];
    int decaySteps = [settings floatForKey:kSettingsLevelDetectorCountsDecayDurationKey] * counterScale;
    
    if (counterDecayFilter == nil || decaySteps != [counterDecayFilter size]) {
        NSNumber* weight = [NSNumber numberWithFloat:1.0/decaySteps];
        NSMutableArray* weights = [NSMutableArray arrayWithCapacity:decaySteps];
        while ([weights count] < decaySteps) {
            [weights addObject:weight];
        }
        
        self.counterDecayFilter = [LowPassFilter createFromArray:weights];
        [self reset];
    }

    sampleProcessor.level = [settings floatForKey:kSettingsLevelDetectorLevelKey];

    if ([settings boolForKey:kSettingsLevelDetectorUseLowPassFilterKey] == YES) {
        NSString* fileName = [settings stringForKey:kSettingsLevelDetectorLowPassFilterFileNameKey];
        LowPassFilter* lowPassFilter = sampleProcessor.lowPassFilter;
        if (lowPassFilter == nil || [lowPassFilter.fileName isEqualToString:fileName] != YES) {
            sampleProcessor.lowPassFilter = [LowPassFilter createFromFile:fileName];
        }
    }
    else {
        sampleProcessor.lowPassFilter = nil;
    }

    detectionScale = [settings floatForKey:kSettingsLevelDetectorScalingKey] * counterScale;

    counterHistorySize = counterScale * 10;
    while (counterHistory.size() < counterHistorySize) {
        counterHistory.push_back(0);
    }
    while (counterHistory.size() > counterHistorySize)
        counterHistory.pop_back();
}

- (void)reset
{
    [sampleProcessor reset];
    [counterDecayFilter reset];
    lastDetection = 0.0;
    counterHistory.clear();
    while (counterHistory.size() < counterHistorySize) {
        counterHistory.push_back(0);
    }
}

- (SignalProcessorController*)controller
{
    if (controller == nil) {
        controller = [[LevelDetectorController createWithLevelDetector:self] retain];
    }

    return controller;
}

- (Float32)updatedDetectionValue
{
    counterHistory.push_front([sampleProcessor counterAndReset]);
    Float32 filteredCounter = [counterDecayFilter filter:counterHistory.front()];
    lastDetection = filteredCounter * detectionScale;
    if (counterHistory.size() > counterHistorySize) counterHistory.pop_back();
    return lastDetection;
}

- (void)setLevel:(Float32)value
{
    sampleProcessor.level = value;
}

- (Float32)level
{
    return sampleProcessor.level;
}

- (NSString*)counterHistoryAsString
{
    std::ostringstream os;
    std::copy(counterHistory.begin(), counterHistory.end(), std::ostream_iterator<UInt32>(os, ", "));
    std::string s(os.str());
    return [NSString stringWithCString:s.c_str() encoding:[NSString defaultCStringEncoding]];
}

@end
