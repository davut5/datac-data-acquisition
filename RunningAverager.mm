// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "RunningAverager.h"

@implementation RunningAverager

@synthesize average;

+ (id)createForSize:(NSUInteger)size
{
    return [[[RunningAverager alloc] initForSize:size] autorelease];
}

- (id)initForSize:(NSUInteger)size
{
    NSMutableArray* weights = [NSMutableArray arrayWithCapacity:size];
    if (size > 0) {
        NSNumber* weight = [NSNumber numberWithFloat:(1.0 / size)];
        while ([weights count] < size) {
            [weights addObject:weight];
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
