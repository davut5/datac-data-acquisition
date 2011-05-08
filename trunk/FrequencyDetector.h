// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BitDetector.h"
#import "WaveCycleDetector.h"

@interface FrequencyDetector : NSObject<WaveCycleDetectorObserver> {
@private
    Float32 samplesPerSecond;
    Float32 nominalHalfBitLength;
    Float32 nominalLowWaveLength;
    Float32 nominalHighWaveLength;
    Float32 maxLowWaveDeviation;
    Float32 maxHighWaveDeviation;
    NSString* currentBitState;
    Float32 currentBitLength;
    NSObject<BitDetectorObserver>* observer;
}

@property (nonatomic, readonly) Float32 nominalLowWaveLength;
@property (nonatomic, readonly) Float32 nominalHighWaveLength;
@property (nonatomic, readonly) Float32 nominalHalfBitLength;
@property (nonatomic, readonly) Float32 currentBitLength;
@property (nonatomic, readonly) NSString* currentBitState;

@property (nonatomic, assign) Float32 lowFrequency;
@property (nonatomic, assign) Float32 highFrequency;
@property (nonatomic, retain) NSObject<BitDetectorObserver>* observer;

+ (FrequencyDetector*)createForSampleRate:(Float32)sampleRateInHz bitRate:(Float32)bitsPerSecond
                                  lowFreq:(Float32)lowFreqInHz highFreq:(Float32)highFreqInHz;

- (id)initForSampleRate:(Float32)sampleRateInHz bitRate:(Float32)bitsPerSecond
                lowFreq:(Float32)lowFreqInHz highFreq:(Float32)highFreqInHz;

- (void)reset;

- (void)updateFromSettings;

@end
