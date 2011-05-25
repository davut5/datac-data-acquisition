//
//  PulseFrequencyDetectorController.h
//  Datac
//
//  Created by Brad Howes on 5/25/11.
//  Copyright 2011 Brad Howes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SignalProcessorController.h"

@class PulseFrequencyDetector;

@interface PulseFrequencyDetectorController : SignalProcessorController {
@private
    PulseFrequencyDetector* detector;
}

+ (id)createWithDetector:(PulseFrequencyDetector*)detector;

- (id)initWithDetector:(PulseFrequencyDetector*)detector;

@end
