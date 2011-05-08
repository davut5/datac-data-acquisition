// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "DetectorController.h"

@class LevelDetector;

@interface LevelDetectorController : DetectorController {
@private
    LevelDetector* levelDetector;
    CGFloat gestureStart;
}

+ (id)createWithLevelDetector:(LevelDetector*)levelDetector;

- (id)initWithLevelDetector:(LevelDetector*)levelDetector;

@end
