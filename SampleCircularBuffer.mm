// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "SampleCircularBuffer.h"

@implementation SampleSpan

@synthesize start, count;

+ (id)spanAt:(Float32*)start forCount:(NSUInteger)count
{
    return [[[SampleSpan alloc] initSpanAt:start forCount:count] autorelease];
}

- (id)initSpanAt:(Float32*)theStart forCount:(NSUInteger)theCount
{
    if (self = [super init]) {
        start = theStart;
        count = theCount;
    }
    return self;
}

@end

@implementation SampleCircularBuffer

+ (id)bufferWithCapacity:(NSUInteger)capacity initialValue:(Float32)initialValue
{
    return [[[SampleCircularBuffer alloc] initWithCapacity:capacity initialValue:initialValue] autorelease];
}

- (id)initWithCapacity:(NSUInteger)capacity initialValue:(Float32)theInitialValue
{
    if (self = [super init]) {
	samples.resize(capacity, theInitialValue);
        initialValue = theInitialValue;
        tail = 0;
    }
    return self;
}

- (void)clear
{
    tail = 0;
    size_t size = samples.size();
    samples.clear();
    samples.resize(size, initialValue);
}

- (void)addSample:(Float32)value
{
    samples[tail++] = value;
    if (tail == samples.size()) tail = 0;
}

- (Float32)valueAt:(NSUInteger)index
{
    size_t pos = (tail + index) % samples.size();
    return samples[pos];
}

- (Float32*)valuesStartingAt:(NSUInteger)index count:(NSUInteger*)valueCount
{
    if (index >= samples.size()) {
        *valueCount = 0;
        return nil;
    }

    size_t pos = (tail + index) % samples.size();
    if (pos < tail) {
        *valueCount = tail - pos;
    }
    else {
        *valueCount = samples.size() - pos;
    }

    return &samples[pos];
}

- (NSArray*)valueSpans
{
    //
    // There will only ever be a max of two SampleSpan objects; at times there may only be one.
    //
    NSUInteger count;
    Float32* ptr = [self valuesStartingAt:0 count:&count];
    NSLog(@"count: %d", count);
    SampleSpan* span = [SampleSpan spanAt:ptr forCount:count];
    NSMutableArray* spans = [NSMutableArray arrayWithObject:span];
    if (count != samples.size()) {
        ptr = [self valuesStartingAt:count count:&count];
        [spans addObject:[SampleSpan spanAt:ptr forCount:count]];
    }

    return spans;
}

@end
