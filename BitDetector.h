// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BitDetectorObserver.h"
#import "SampleProcessorProtocol.h"

extern NSString* kBitDetectorUnknownBit;
extern NSString* kBitDetectorLowBit;
extern NSString* kBitDetectorHighBit;

/** The BitDetector works on floating-point values between -1 and +1, presumably from the audio system. It detects
 transitions between a low level and high level, counts the number of samples while at a level and periodically
 sends a nextBitValue: to any registered observer. The detection logic works on a fixed bitrate (say 1200 bps), which it
 uses as a time reference to detect multiple occurances of a bit at the same level. For the 1200 bps case, each bit
 signal will consist of 36.75 audio samples when sampled at 44.1 kHz. If a bit is at a level for 1.5 * 36.75 samples,
 then the detector emits another nextBitValue: message. Rising and falling edge transitions between 0 and 1 levels reset
 this counter so that there is minimal chance of drift due to 36.75 not being a whole number.
 
 To account for noise, the low level (0) is defined by a maxLowLevel setting at which the incoming sample values must be
 at (or lower) in order to be considered part of a 0 value. Likewise, the minHighLevel defines the value incoming
 sample values must be at (or higher) to be considered part of a 1 value. Values outside of these bounds will count
 towards the sample count needed to trigger a new bit detection, but they will not trigger a new edge detection.
 
 It is possible that due to noise, transition detection occurs very late within a pulse (say 18 samples in), in which
 case the induced slew might cause the detector to miss a bit. Currently, the detector fires a nextBitValue: when it
 sees 36.75 / 2 valid samples after the start of a bit transition. This is the center of an idealized pulse width. If
 extreme slew occurs, it is possible that there would not be enough samples for the detector to see to fire the
 notification. One could make the pulse width smaller, but then one runs the risk of firing on a phantom pulse at the
 end of a string of same-value bits. Since in the current scheme, there are a maximum of 9 bits before there is a forced
 transition due to the presense of the stop/start bits in the byte frame, one could calculate the maximum drift that the
 detector could encounter without problems, and adjust the centroid position accordingly. This has not been done here.
 
 Alternative approach: use MofN logic to declare a value in the presence of noise. For a nominal pulse width N, there
 must be M samples that satisfy their acceptance criteria. If so, fire the nextBitValue: message, otherwise ignore.
 */
@interface BitDetector : NSObject<SampleProcessorProtocol> {
@private
    Float32 maxLowLevel;                // Maximum allowed sample value for a low (0) bit
    Float32 minHighLevel;               // Minimum allowed sample value for a high (1) bit
    SInt32 nominalHalfPulseWidth;       // Sample count/2 for an average pulse
    NSString* currentBitState;          // The last-detected bit value
    SInt32 pulseWidth;                  // The current sample count for the current/next bit pulse
    NSObject<BitDetectorObserver>* observer;
}

@property (nonatomic, assign) Float32 maxLowLevel;
@property (nonatomic, assign) Float32 minHighLevel;
@property (nonatomic, retain) NSObject<BitDetectorObserver>* observer;

/** Factory method to create and initialize a new BitDetector object.
 */
+ (BitDetector*)create;

/** Initialize a new BitDetector object.
 */
- (id)init;

- (void)updateFromSettings;

- (void)reset;

@end
