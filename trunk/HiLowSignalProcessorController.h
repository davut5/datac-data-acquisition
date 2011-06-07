// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SignalProcessorController.h"

@class HiLowSignalProcessor;

@interface HiLowSignalProcessorController : SignalProcessorController {
@private
    HiLowSignalProcessor* detector;
    int gestureKind;
    CGFloat gestureStart;
    CGFloat gestureLevel;
}

+ (id)createWithDetector:(HiLowSignalProcessor*)detector;

- (id)initWithDetector:(HiLowSignalProcessor*)detector;

@end
