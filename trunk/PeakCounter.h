// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SampleProcessorProtocol.h"

@class LowPassFilter;

enum EdgeKind {
    kEdgeKindUnknown,
    kEdgeKindRising,
    kEdgeKindFalling
};

/** Simple processor that detects when the signal rises above a given level. Maintains a count of the number of times
    this occurs.
*/
@interface PeakCounter : NSObject<SampleProcessorProtocol> {
@private
    Float32 level;
    LowPassFilter* lowPassFilter;
    EdgeKind currentEdge;
    UInt32 counter;
}

@property (nonatomic, assign) Float32 level;
@property (nonatomic, retain) LowPassFilter* lowPassFilter;
@property (nonatomic, readonly) EdgeKind currentEdge;
@property (nonatomic, readonly) UInt32 counter;

+ (PeakCounter*)createWithLevel:(Float32)level;

- (id)initWithLevel:(Float32)level;

/** Fetch the current counter value and reset it to zero.
 */
- (UInt32)counterAndReset;

- (void)reset;

@end
