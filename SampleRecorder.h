// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <deque>

#import <AudioToolbox/ExtendedAudioFile.h>
#import <Foundation/Foundation.h>

class CAStreamBasicDescription;
class AUOutputBL;

@class RecordingInfo;

@interface SampleRecorder : NSObject {
@private
    ExtAudioFileRef file;
    RecordingInfo* recording;
    UInt32 runningSize;
    int updateCounter;
    std::deque<AUOutputBL*> buffers;
}

@property (nonatomic, retain) RecordingInfo* recording;
@property (nonatomic, assign, readonly) ExtAudioFileRef file;

+ (id)createRecording:(RecordingInfo*)recording withFormat:(CAStreamBasicDescription*)format;

- (id)initRecording:(RecordingInfo*)recording withFormat:(CAStreamBasicDescription*)format;

- (void)close;

- (void)writeData:(AudioBufferList*)ioData frameCount:(UInt32)frameCount;

@end

