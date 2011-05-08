// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "WeightedAverager.h"

@implementation WeightedAverager

@synthesize average;

+ (id)createForSize:(NSUInteger)size
{
    return [[[WeightedAverager alloc] initForSize:size] autorelease];
}

- (id)initForSize:(NSUInteger)size
{
    NSMutableArray* weights = [NSMutableArray arrayWithCapacity:size];
    if (size > 0) {
        Float32 scale = 1.0 / (2.0 * size);
        for (size_t index = 0; index < size; ++index) {
            [weights addObject:[NSDecimalNumber numberWithFloat:((size - index) * scale)]];
        }
    }

    if (self = [super initFromArray:weights]) {
        average = 0.0;
    }

    return self;
}

- (void)reset
{
    [super reset];
    average = 0.0;
}

- (Float32)filter:(Float32)value
{
    average = [super filter:value];
    return average;
}

@end
