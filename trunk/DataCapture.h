// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <AudioUnit/AudioUnit.h>
#import <vector>

#import "CAStreamBasicDescription.h"
#import "SampleProcessorProtocol.h"

struct AudioUnitRenderProcContext;

@class SampleRecorder;
@class VertexBufferManager;

typedef void (*DataCaptureProcessSamplesProc)(id, SEL, AudioBufferList*, UInt32, const AudioTimeStamp*);

/** Data collection class for the exteral device. Uses the AudioUnit
    infrastructure to obtain samples from the external device and to emit a
    signal to the device for power.
 
    NOTE: processors will be activated in an AudioUnit thread, not the main
    thread. See the VertexBufferManager class for an example of what to do to
    remain thread-safe with the main thread.
*/
@interface DataCapture : NSObject
{
@private
    AudioUnit audioUnit;
    AURenderCallbackStruct renderCallback;
    SInt32* powerSignal;
    UInt32 maxAudioSampleCount;
    NSObject<SampleProcessorProtocol>* sampleProcessor;
    NSObject<SampleProcessorProtocol>* switchDetector;
    VertexBufferManager* vertexBufferManager;
    SampleRecorder* sampleRecorder;
    Float64 sampleRate;
    BOOL audioUnitRunning;
    BOOL emittingPowerSignal;
    BOOL pluggedIn;
    BOOL invertSignal;
    std::vector<Float32> sampleBuffer;
    struct AudioUnitRenderProcContext* audioUnitRenderProcContext;
    CAStreamBasicDescription streamFormat;
}

@property (nonatomic, assign, readonly) AudioUnit audioUnit;
@property (nonatomic, retain) NSObject<SampleProcessorProtocol>* sampleProcessor;
@property (nonatomic, retain) NSObject<SampleProcessorProtocol>* switchDetector;
@property (nonatomic, retain) VertexBufferManager* vertexBufferManager;
@property (nonatomic, assign, readonly) UInt32 maxAudioSampleCount;
@property (nonatomic, assign, readonly) BOOL audioUnitRunning;
@property (nonatomic, assign) BOOL emittingPowerSignal;
@property (nonatomic, assign) BOOL pluggedIn;
@property (nonatomic, assign) BOOL invertSignal;

@property (nonatomic, assign, readonly) Float64 sampleRate;
@property (nonatomic, retain) SampleRecorder* sampleRecorder;
@property (nonatomic, assign, readonly) CAStreamBasicDescription* streamFormat;

+ (DataCapture*)create;

- (id)init;

- (void)start;

- (void)stop;


@end
