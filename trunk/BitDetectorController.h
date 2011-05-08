//
//  BitDetectorController.h
//  Datac
//
//  Created by Brad Howes on 5/6/11.
//  Copyright 2011 Skype. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "DetectorController.h"

@class BitDetector;

@interface BitDetectorController : DetectorController {
@private
    BitDetector* bitDetector;
    CGFloat gestureStart;
    int gestureType;
}

+ (id)createWithBitDetector:(BitDetector*)bitDetector;

- (id)initWithBitDetector:(BitDetector*)bitDetector;

@end
