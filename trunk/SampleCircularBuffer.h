// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <vector>

@interface SampleSpan : NSObject
{
    Float32* start;
    NSUInteger count;
}

@property (nonatomic, assign) Float32* start;
@property (nonatomic, assign) NSUInteger count;

+ (id)spanAt:(Float32*)start forCount:(NSUInteger)count;

- (id)initSpanAt:(Float32*)start forCount:(NSUInteger)count;

@end

@interface SampleCircularBuffer : NSObject
{
@private
    std::vector<Float32> samples;
    NSUInteger tail;
    Float32 defaultValue;
}

+ (id)bufferWithCapacity:(NSUInteger)capacity initialValue:(Float32)initialValue;

- (id)initWithCapacity:(NSUInteger)capacity initialValue:(Float32)initialValue;

- (void)clear;

- (void)addSample:(Float32)value;

- (Float32)valueAt:(NSUInteger)index;

- (Float32*)valuesStartingAt:(NSUInteger)index count:(NSUInteger*)valueCount;

- (NSArray*)valueSpans;

@end
