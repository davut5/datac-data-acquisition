//
//  LevelDetectorController.h
//  Datac
//
//  Created by Brad Howes on 5/6/11.
//  Copyright 2011 Skype. All rights reserved.
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
