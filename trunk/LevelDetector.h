// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <deque>

#import <Foundation/Foundation.h>

#import "SampleProcessorProtocol.h"
#import "SignalProcessorProtocol.h"

@class AboveLevelCounter;
@class LevelDetectorController;
@class LowPassFilter;

/** Simple signal detector that looks for and counts the rising edges of peaks above a user-settable level. Periodically
    reports these peak counts in a notification named kLevelDetectorCounterUpdateNotification.
*/

@interface LevelDetector : NSObject <SignalProcessorProtocol> {
@private
    AboveLevelCounter* sampleProcessor;
    LevelDetectorController* controller;
    LowPassFilter* counterDecayFilter;

    Float32 detectionScale;
    Float32 counterScale;
    Float32 lastDetection;

    std::deque<UInt32> counterHistory;
    size_t counterHistorySize;
}

@property (nonatomic, retain) AboveLevelCounter* sampleProcessor;
@property (nonatomic, retain) LowPassFilter* counterDecayFilter;
@property (nonatomic, assign) Float32 level;

@property (nonatomic, readonly) Float32 detectionScale;
@property (nonatomic, readonly) Float32 counterScale;
@property (nonatomic, readonly) Float32 lastDetection;

+ (LevelDetector*)create;

- (id)init;

- (NSString*)counterHistoryAsString;

@end
