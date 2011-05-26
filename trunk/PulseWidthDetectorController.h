// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SignalProcessorController.h"

@class PulseWidthDetector;

@interface PulseWidthDetectorController : SignalProcessorController {
@private
    PulseWidthDetector* detector;
    int gestureKind;
    CGFloat gestureStart;
    CGFloat gestureLevel;
}

+ (id)createWithDetector:(PulseWidthDetector*)detector;

- (id)initWithDetector:(PulseWidthDetector*)detector;

@end
