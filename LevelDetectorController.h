// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "SignalProcessorController.h"

@class LevelDetector;

@interface LevelDetectorController : SignalProcessorController {
@private
    LevelDetector* levelDetector;
    CGFloat gestureStart;
}

+ (id)createWithLevelDetector:(LevelDetector*)levelDetector;

- (id)initWithLevelDetector:(LevelDetector*)levelDetector;

@end
