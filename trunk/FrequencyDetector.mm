//
//  FrequencyDetector.mm
//  Datac
//
//  Created by Brad Howes on 5/2/11.
//  Copyright 2011 Skype. All rights reserved.
//

#import "FrequencyDetector.h"
#import "WeightedAverager.h"

NSString* kFrequencyDetectorUnknownBit = @"?";
NSString* kFrequencyDetectorLowBit = @"0";
NSString* kFrequencyDetectorHighBit = @"1";

@implementation FrequencyDetector

@synthesize lowFrequency, highFrequency, observer, nominalHalfBitLength, nominalLowWaveLength, nominalHighWaveLength;
@synthesize currentBitLength, currentBitState;

+ (FrequencyDetector*)createForSampleRate:(Float32)samplesPerSecond bitRate:(Float32)bitsPerSecond 
                                  lowFreq:(Float32)lowFreqInHz highFreq:(Float32)highFreqInHz
{
    return [[[FrequencyDetector alloc] initForSampleRate:samplesPerSecond
                                                 bitRate:bitsPerSecond
                                                 lowFreq:lowFreqInHz 
                                                highFreq:highFreqInHz] autorelease];
}

- (id)initForSampleRate:(Float32)theSamplesPerSecond bitRate:(Float32)bitsPerSecond
                lowFreq:(Float32)lowFreqInHz highFreq:(Float32)highFreqInHz
{
    if (self = [super init]) {
        samplesPerSecond = theSamplesPerSecond;
        Float32 samplesPerBit = samplesPerSecond / bitsPerSecond; // 44100 / 150  = 294 samples / bit
        nominalHalfBitLength = samplesPerBit / 2;                 // 147 samples
        self.lowFrequency = lowFreqInHz;
        self.highFrequency = highFreqInHz;
    }

    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)setLowFrequency:(Float32)lowFreqInHz
{
    nominalLowWaveLength = samplesPerSecond / lowFreqInHz;
    maxLowWaveDeviation = 0.10 * nominalLowWaveLength;
    [self reset];
}

- (void)setHighFrequency:(Float32)highFreqInHz
{
    nominalHighWaveLength = samplesPerSecond / highFreqInHz;
    maxHighWaveDeviation = 0.10 * nominalHighWaveLength;
    [self reset];
}

- (void)waveCycleDetected:(NSNumber*)length
{
    Float32 waveLength = [length unsignedIntegerValue];
    Float32 dLow = fabs(waveLength - nominalLowWaveLength);
    Float32 dHigh = fabs(waveLength - nominalHighWaveLength);

    if (dLow <= maxLowWaveDeviation) {
        if (currentBitState != kFrequencyDetectorLowBit) {
            currentBitState = kFrequencyDetectorLowBit;
            currentBitLength = 0;
        }
    }
    else if (dHigh <= maxHighWaveDeviation) {
        if (currentBitState != kFrequencyDetectorHighBit) {
            currentBitState = kFrequencyDetectorHighBit;
            currentBitLength = 0;
        }
    }

    if (currentBitState != kFrequencyDetectorUnknownBit) {

        //
        // We don't announce a new bit until we've accumulated about 1/2 of a bit length. There will be twice as many
        // cycles for a 8000 Hz signal vs. a 4000 Hz signal, but the samples per bit are constant.
        //
        currentBitLength += waveLength;
        if (currentBitLength >= nominalHalfBitLength) {
            currentBitLength -= 2 * nominalHalfBitLength;
            NSLog(@"nextBitValue: %@", currentBitState);
            if (observer != nil) {
                [observer performSelectorOnMainThread:@selector(nextBitValue:)
                                           withObject:currentBitState
                                        waitUntilDone:NO];
            }
        }
    }
}

- (void)reset
{
    currentBitState = kFrequencyDetectorUnknownBit;
    currentBitLength = 0.0;
}

- (void)updateFromSettings
{
}

@end
