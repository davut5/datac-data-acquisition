// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CAStreamBasicDescription.h"

@class RecordingInfo;

@interface SampleRecorder : NSObject {
@private
    CAStreamBasicDescription recordFormat;
    RecordingInfo* recording;
    NSOutputStream* outputStream;
    UInt32 runningSize;
    int updateCounter;
}

@property (retain, nonatomic) NSOutputStream* outputStream;
@property (retain, nonatomic) RecordingInfo* recording;

+ (id)createRecording:(RecordingInfo*)recording;
- (id)initRecording:(RecordingInfo*)recording;
- (void)close;
- (void)write:(const SInt32*)ptr maxLength:(UInt32)count;

@end
