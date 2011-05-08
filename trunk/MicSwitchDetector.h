// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SampleProcessorProtocol.h"

@class MicSwitchDetector;

/** Protocol for a MicSwitchDetector delegate, an object that will receive notifications when the MicSwitchDetector it is a
 part of detects a change in the stat of the external microphone switch.
 */
@protocol MicSwitchDetectorDelegate
@required
- (void)switchStateChanged:(MicSwitchDetector*)sender;
@end

/** Primitive 'silence' detector which attempts to operate as a mic switch detector. In some iOS headphone sets with a
 built-in microphone, there is a momentary contact switch that grounds the mic lead when pressed. Ideally, this 
 grounding would show up as near-zero sample values for the duration of the pressing. When not pressed, then normal 
 background noise would show up as values that for a certain duration of time collectively have a high probability at 
 least one sample being above a given threshold value. It is this higher probability over time that allows the detector 
 to operate with a very high success rate and a very low false alarm rate.
 
 The reason that this detector is primitive is that at its heart it is not stochastic-based but instead sample-based: 
 it assumes that there are no gaps or missing samples.
 */
@interface MicSwitchDetector : NSObject<SampleProcessorProtocol> {
@private
    Float32 threshold;
    Float32 downDuration;
    Float32 sampleRate;
    UInt32 samples;
    UInt32 counter;
    BOOL pressed;
    NSObject<MicSwitchDetectorDelegate>* delegate;
}

@property (nonatomic, assign) Float32 threshold;
@property (nonatomic, assign) Float32 downDuration;
@property (nonatomic, assign) BOOL pressed;
@property (nonatomic, retain) NSObject<MicSwitchDetectorDelegate>* delegate;

+ (id)createWithSampleRate:(Float32)sampleRate;

- (id)initWithSampleRate:(Float32)sampleRate;

- (void)reset;

- (void)updateFromSettings;

@end
