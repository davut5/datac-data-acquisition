// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DataCapture.h"

@class SwitchDetector;

@protocol SwitchDetectorDelegate
@required
- (void)switchStateChanged:(SwitchDetector*)sender;
@end

@interface SwitchDetector : NSObject {
@private
    Float32 threshold;
    Float32 downDuration;
    Float32 sampleRate;
    UInt32 samples;
    UInt32 counter;
    BOOL pressed;
    NSObject<SwitchDetectorDelegate>* delegate;
}

@property (nonatomic, assign) Float32 threshold;
@property (nonatomic, assign) Float32 downDuration;
@property (nonatomic, assign) BOOL pressed;
@property (nonatomic, retain) NSObject<SwitchDetectorDelegate>* delegate;

+ (id)createWithSampleRate:(Float32)sampleRate;

- (id)initWithSampleRate:(Float32)sampleRate;

- (void)reset;

- (void)addSample:(Float32)sample;

- (void)updateFromSettings;

@end
