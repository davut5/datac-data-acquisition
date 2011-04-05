// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <AudioUnit/AudioUnit.h>

struct AudioUnitRenderProcContext;

@class AudioSampleBuffer;
@class LowPassFilter;
@class SampleRecorder;
@class SignalDetector;
@class SwitchDetector;
@class VertexBufferManager;

typedef void (*DataCaptureProc)(id, SEL, Float32);
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
    SignalDetector* signalDetector;
    SwitchDetector* switchDetector;
    VertexBufferManager* vertexBufferManager;
    SampleRecorder* sampleRecorder;
    Float64 sampleRate;
    BOOL audioUnitRunning;
    BOOL emittingPowerSignal;
    BOOL pluggedIn;

    //
    // Method cache for the internal processSamples callback that receives raw
    // audio samples. Probably naive attempt to speed up method dispatch...
    //
    SEL addSampleSelector;
    DataCaptureProc vertexBufferProc;
    DataCaptureProc signalDetectorProc;
    DataCaptureProc switchDetectorProc;

    struct AudioUnitRenderProcContext* audioUnitRenderProcContext;
}

@property (nonatomic, assign, readonly) AudioUnit audioUnit;
@property (nonatomic, retain) AudioSampleBuffer* audioSampleBuffer;
@property (nonatomic, retain) SignalDetector* signalDetector;
@property (nonatomic, retain) SwitchDetector* switchDetector;
@property (nonatomic, retain) VertexBufferManager* vertexBufferManager;
@property (nonatomic, retain) SampleRecorder* sampleRecorder;
@property (nonatomic, assign, readonly) UInt32 maxAudioSampleCount;
@property (nonatomic, assign, readonly) BOOL audioUnitRunning;
@property (nonatomic, assign) BOOL emittingPowerSignal;
@property (nonatomic, assign) BOOL pluggedIn;

@property (nonatomic, assign, readonly) Float64 sampleRate;
@property (nonatomic, assign, readonly) SEL processSamplesSelector;
@property (nonatomic, assign, readonly) DataCaptureProcessSamplesProc processSamplesProc;

+ (DataCapture*)create;

- (id)init;
- (void)start;
- (void)stop;

@end
