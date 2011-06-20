// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <vector>

/**
 * Utility class that represents a contiguous span of Float32 values.
 */
@interface SampleSpan : NSObject {}

/**
 * Address of the first Float32 value in the span.
 */
@property (nonatomic, assign, readonly) Float32* start;

/**
 * Number of Float32 values in the span. Guaranteed to be > 0.
 */
@property (nonatomic, assign, readonly) NSUInteger count;

/**
 * Factory method that creates and returns new SampleSpan objects.
 * \param start address of the first Float32 value in the span
 * \param count number of Float32 values in the span. Must be > 0.
 * \return allocated SampleSpan object, or nil if error.
 */
+ (id)spanAt:(Float32*)start forCount:(NSUInteger)count;

/**
 * Designated constructor for SampleSpan objects.
 * \param start address of the first Float32 value in the span
 * \param count number of Float32 values in the span. Must be > 0.
 * \return initialized SampleSpan object, or nil if error.
 */
- (id)initSpanAt:(Float32*)start forCount:(NSUInteger)count;

@end

/**
 * Representation of a fixed-size circular buffer of Float32 values.
 */
@interface SampleCircularBuffer : NSObject
{
@private
    std::vector<Float32> samples;
    NSUInteger tail;
    Float32 initialValue;
}

+ (id)bufferWithCapacity:(NSUInteger)capacity initialValue:(Float32)initialValue;

- (id)initWithCapacity:(NSUInteger)capacity initialValue:(Float32)initialValue;

- (void)clear;

- (void)addSample:(Float32)value;

- (Float32)valueAt:(NSUInteger)index;

- (Float32*)valuesStartingAt:(NSUInteger)index count:(NSUInteger*)valueCount;

- (NSArray*)valueSpans;

@end
