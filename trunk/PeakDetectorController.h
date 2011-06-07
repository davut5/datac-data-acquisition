// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "SignalProcessorController.h"

@class PeakDetector;

@interface PeakDetectorController : SignalProcessorController {
@private
    PeakDetector* peakDetector;
    CGFloat gestureStart;
    CGFloat gestureLevel;
}

+ (id)createWithPeakDetector:(PeakDetector*)peakDetector;

- (id)initWithPeakDetector:(PeakDetector*)peakDetector;

@end
