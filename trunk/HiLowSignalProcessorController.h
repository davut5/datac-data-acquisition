// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SignalProcessorController.h"

@class BitDetector;

@interface HiLowSignalProcessorController : SignalProcessorController {
@private
    HiLowSignalProcessor* signalProcessor;
    CGFloat gestureStart;
    int gestureType;
}

+ (id)createWithSignalProcessor:(HiLowSignalProcessor*)signalProcessor;

- (id)initWithSignalProcessor:(HiLowSignalProcessor*)signalProcessor;

@end
