// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <Foundation/Foundation.h>

/** Collection of audio samples from the iPhone mic or jack. Each sample is
    represented as a signed 32-bit integer (mono) with sample values in
    fixed-format (Q8.24) with 8 bits for the integer portion and 24 bits for
    the fractional value. Note that for samples obtained by Apple devices,
    values will never be outside of the range [-1, +1].
 
    Internally, the array of SInt32 values has a capacity indicated by the
    audio system when the buffer was created. However, the number of actual
    valid values is always indicated by the 'count' value.
*/
@interface AudioSampleBuffer : NSObject
{
@private
    SInt32* samples;
    UInt32 count;
}

@property (nonatomic,assign,readonly) SInt32* samples;
@property (nonatomic,assign) UInt32 count;

/** Convenience class method that converts from fixed-point Q8.24 format to a
    floating-point value ranging between -1.0 and 1.0 inclusively.
*/
+ (Float32)convertQ824ToFloat:(SInt32)value;

/** Convenience class method that converts from a floating-point value ranging
    between -1.0 and 1.0 inclusively into a fixed-point Q8.24 format
*/
+ (SInt32)convertFloatToQ824:(Float32)value;

/** Class method that allocates and initializes a new AudioSampleBuffer of a
    given number of samples.
*/
+ (id)bufferWithCapacity:(NSUInteger)capacity;

/** Initializes a new AudioSampleBuffer instance to hold a maximum number of
    samples.
*/
- (id)initWithCapacity:(NSUInteger)capacity;

@end
