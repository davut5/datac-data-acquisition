// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "AboveLevelCounter.h"
#import "LowPassFilter.h"

@implementation AboveLevelCounter

@synthesize level, lowPassFilter, currentEdge, counter;

+ (AboveLevelCounter*)createWithLevel:(Float32)level
{
    return [[[AboveLevelCounter alloc] initWithLevel:level] autorelease];
}

- (id)initWithLevel:(Float32)theLevel
{
    if (self = [super init]) {
        level = theLevel;
        lowPassFilter = nil;
        [self reset];
    }
    
    return self;
}

- (void)reset
{
    counter = 0;
    currentEdge = kEdgeKindUnknown;
    if (lowPassFilter) [lowPassFilter reset];
}

- (UInt32)counterAndReset
{
    UInt32 value = counter;
    counter = 0;
    return value;
}

#pragma mark -
#pragma mark SampleProcessorProtocol

- (void)addSamples:(Float32*)ptr count:(UInt32)count
{
    while (count-- > 0) {
        Float32 sample = *ptr++;
        if (lowPassFilter != nil) {
            sample = [lowPassFilter filter:sample];
        }

        if (sample >= level) {
            if (currentEdge != kEdgeKindRising) {
                currentEdge = kEdgeKindRising;
                ++counter;
            }
        }
        else {
            if (currentEdge != kEdgeKindFalling) {
                currentEdge = kEdgeKindFalling;
            }
        }
    }
}

@end
