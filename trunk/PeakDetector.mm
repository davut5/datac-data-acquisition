// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//
#import <iterator>
#import <sstream>

#import "PeakCounter.h"
#import "LowPassFilter.h"
#import "PeakDetector.h"
#import "PeakDetectorController.h"
#import "SignalProcessorController.h"
#import "UserSettings.h"

@interface PeakDetector () <UIAlertViewDelegate>

@property (nonatomic, retain) UIAlertView* postedAlert;

@end

@implementation PeakDetector

@synthesize sampleProcessor, counterDecayFilter, level, detectionScale, counterScale, lastDetection, postedAlert;

+ (id)create
{
    return [[[PeakDetector alloc] init] autorelease];
}

- (id)init
{
    if ((self = [super init])) {
        self.sampleProcessor = [PeakCounter createWithLevel:0.0];
        controller = nil;
        counterDecayFilter = nil;
        postedAlert = nil;
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
    self.postedAlert = nil;
    [controller release];
    counterHistory.clear();
    [super dealloc];
}

#pragma mark -
#pragma mark SignalProcessorProtocol

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    self.postedAlert = nil;
}

- (void)updateFromSettings
{
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    
    counterScale = [settings floatForKey:kSettingsDetectionsViewUpdateRateKey];
    int decaySteps = [settings floatForKey:kSettingsPeakDetectorCountsDecayDurationKey] * counterScale;
    
    if (counterDecayFilter == nil || decaySteps != [counterDecayFilter size]) {
        NSNumber* weight = [NSNumber numberWithFloat:1.0/decaySteps];
        NSMutableArray* weights = [NSMutableArray arrayWithCapacity:decaySteps];
        while ([weights count] < decaySteps) {
            [weights addObject:weight];
        }
        
        self.counterDecayFilter = [LowPassFilter createFromArray:weights];
        [self reset];
    }
    
    sampleProcessor.level = [settings floatForKey:kSettingsPeakDetectorLevelKey];
    
    if ([settings boolForKey:kSettingsPeakDetectorUseLowPassFilterKey] == YES) {
        NSString* fileName = [settings stringForKey:kSettingsPeakDetectorLowPassFilterFileNameKey];
        LowPassFilter* lowPassFilter = sampleProcessor.lowPassFilter;
        if (lowPassFilter == nil || [lowPassFilter.fileName isEqualToString:fileName] != YES) {
            sampleProcessor.lowPassFilter = [LowPassFilter createFromFile:fileName];
            if (sampleProcessor.lowPassFilter.fileName == nil) {
                NSString* title = NSLocalizedString(@"Missing Filter File",
                                                    @"Missing Filter File");
                NSString* msgFormat = NSLocalizedString(@"Unable to locate file '%@' for low-pass filter weights.",
                                                        @"Unable to locate file '@%' for low-pass filter weights.");
                postedAlert = [[UIAlertView alloc] initWithTitle:title
                                                         message:[NSString stringWithFormat:msgFormat, fileName]
                                                        delegate:self
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil];
                [postedAlert show];
            }
        }
    }
    else {
        sampleProcessor.lowPassFilter = nil;
    }
    
    detectionScale = [settings floatForKey:kSettingsPeakDetectorScalingKey] * counterScale;
    
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
        controller = [[PeakDetectorController createWithPeakDetector:self] retain];
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
