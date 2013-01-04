// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "BitDetector.h"
#import "UserSettings.h"

@implementation BitDetector

@synthesize observer, maxLowLevel, minHighLevel;

NSString* kBitDetectorUnknownBit = @"?";
NSString* kBitDetectorLowBit = @"0";
NSString* kBitDetectorHighBit = @"1";

+ (id)create
{
    return [[[BitDetector alloc] init] autorelease];
}

- (id)init
{
    if (self = [super init]) {
        observer = nil;
        [self updateFromSettings];
    }
    
    return self;
}

- (void)dealloc
{
    self.observer = nil;
    [super dealloc];
}

- (void)updateFromSettings
{
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    nominalHalfPulseWidth = [settings integerForKey:kSettingsBitDetectorSamplesPerPulseKey] * 0.5;
    maxLowLevel = [settings floatForKey:kSettingsBitDetectorMaxLowLevelKey];
    minHighLevel = [settings floatForKey:kSettingsBitDetectorMinHighLevelKey];
    [self reset];
}

- (void)reset
{
    currentBitState = kBitDetectorUnknownBit;
    pulseWidth = 0;
}

- (void)addSamples:(Float32*)ptr count:(UInt32)count
{
    while (count-- > 0) {
        Float32 sample = *ptr++;
        if (sample >= minHighLevel) {
            if (currentBitState != kBitDetectorHighBit) {
                
                //
                // Start of new high (1) bit pulse
                //
                currentBitState = kBitDetectorHighBit;
                pulseWidth = 0;
            }
        }
        else if (sample <= maxLowLevel) {
            if (currentBitState != kBitDetectorLowBit) {
                
                //
                // Start of new low (0) bit pulse
                //
                currentBitState = kBitDetectorLowBit;
                pulseWidth = 0;
            }
        }
        
        if (currentBitState != kBitDetectorUnknownBit) {
            
            //
            // Count samples that fall in the 'grey' zone as part of the current pulse - otherwise, our timing gets
            // messed up. Alternatively, do MofN detection to declare an pulse, but keep the pulseWidth counter to
            // stay aligned with edge transitions.
            //
            ++pulseWidth;
            
            if (pulseWidth == nominalHalfPulseWidth) {
                
                //
                // Doing this will allow us to trigger again if a full pulse of samples passes by with no change in
                // level.
                //
                pulseWidth *= -1;
                LOG(@"nextBitValue: %@", currentBitState);
                
                if (observer != nil) {
                    [observer performSelectorOnMainThread:@selector(nextBitValue:)
                                               withObject:currentBitState
                                            waitUntilDone:NO];
                }
            }
        }
    }
}

@end
