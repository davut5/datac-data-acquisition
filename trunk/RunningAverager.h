// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "LowPassFilter.h"

/** Variant of a LowPassFilter that just maintains a running average of the last N samples.
 */
@interface RunningAverager : LowPassFilter {
@private
    Float32 average;
}

@property (nonatomic, readonly) Float32 average;

/** Class method that creates a new RunningAverager object and initializes it with the given number of weights.
 */
+ (id)createForSize:(NSUInteger)size;

- (id)initForSize:(NSUInteger)size;

@end
