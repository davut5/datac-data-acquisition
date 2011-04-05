//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "AudioSampleBuffer.h"

@implementation AudioSampleBuffer

@synthesize samples, count;

static const SInt32 kFloatToQ824 = 1 << 24;
static const Float32 kQ824ToFloat = Float32(1.0) / Float32(kFloatToQ824);

+ (Float32)convertQ824ToFloat:(SInt32)value
{
    return value * kQ824ToFloat;
}

+ (SInt32)convertFloatToQ824:(Float32)value
{
    return value * kFloatToQ824;
}

+ (id)bufferWithCapacity:(NSUInteger)capacity
{
    return [[[AudioSampleBuffer alloc] initWithCapacity:capacity] autorelease];
}

- (id)initWithCapacity:(NSUInteger)capacity
{
    if (self = [super init]) {
	samples = new SInt32[ capacity ];
	memset(samples, 0, capacity * sizeof(SInt32));
	count = capacity;
    }
    return self;
}

- (void)dealloc
{
    delete [] samples;
    samples = 0;
    [super dealloc];
}

@end
