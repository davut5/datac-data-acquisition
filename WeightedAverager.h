// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "LowPassFilter.h"

/** Variant of a LowPassFilter that uses a fixed set of weights or taps that follow the linear sequence 
    (N/2N, (N-1)/2N, (N-2)/2N, ..., 1/2N)
    The sum of the weights is always 1, and each weight is followed by a weight with 1/2N less pull in the overall
    averaging.
 */
@interface WeightedAverager : LowPassFilter {
@private
    Float32 average;
}

@property (nonatomic, readonly) Float32 average;

/** Class method that creates a new WeightedAverager object and initializes it with the given number of weights.
 */
+ (id)createForSize:(NSUInteger)size;

- (id)initForSize:(NSUInteger)size;

@end
