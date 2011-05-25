// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DataCapture.h"

@interface WaveCycleDetectorInfo : NSObject
{
    NSUInteger sampleCount;
    Float32 minValue;
    Float32 maxValue;
}

@property (nonatomic, assign) NSUInteger sampleCount;
@property (nonatomic, assign) Float32 minValue;
@property (nonatomic, assign) Float32 maxValue;
@property (nonatomic, readonly) Float32 amplitude;

@end

/** A protocol for observers interested in WaveCycleDetector detections.
 */
@protocol WaveCycleDetectorObserver
@required

/** Notification sent out when the bit detector find a new bit.
 \param cycleWidth NSNumber object that was created with an NSUInteger value describing the number of 44.1 kHz samples seen by the detector since the last detection.
 */
- (void)waveCycleDetected:(WaveCycleDetectorInfo*)info;

@end

enum State {
    kFallingEdge,
    kRisingEdge,
    kUnknownValue
};

/** Simple detector that looks for waveform cycles, where a cycle is defined as a sequence of samples bounded by two negative-to-positive transitions. To mitigate against noise, the detector uses hysteresis when detecting the transition. Negative values must be at or below a specific level in order to be counted in the kNegValue state, while positive values must be at or above a specific level in order to be counted in the kPosValue state. When the transition from kNegValue to kPosValue occurs, the detector notifies any registered observer that implements the WaveCycleDetectorObserver protocol. In particular, the observer receives the waveCycleDetected: message with the sole message parameter containing the number of samples that make up the wave cycle, or the wavelength in samples, and the inverse would be the frequency as a ratio of the 44.1 kHz sample rate.
 */
@interface WaveCycleDetector : NSObject<SampleProcessorProtocol> {
@private
    Float32 lowLevel, highLevel;
    State state;
    WaveCycleDetectorInfo* info;
    NSObject<WaveCycleDetectorObserver>* observer;
}

@property (nonatomic, assign) Float32 lowLevel;
@property (nonatomic, assign) Float32 highLevel;
@property (nonatomic, retain) WaveCycleDetectorInfo* info;
@property (nonatomic, retain) NSObject<WaveCycleDetectorObserver>* observer;

/** Factory method to create and initialize a new WaveCycleDetector object.
 */
+ (WaveCycleDetector*)createWithLowLevel:(Float32)theLowLevel highLevel:(Float32)theHighLevel;

/** Initialize a new WaveCycleDetector object.
 */
- (id)initWithLowLevel:(Float32)theLowLevel highLevel:(Float32)theHighLevel;

/** Reset detector logic to known values.
 */
- (void)reset;

@end
