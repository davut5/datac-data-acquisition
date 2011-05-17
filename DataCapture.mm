// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <AudioUnit/AUComponent.h>
#import <AudioUnit/AudioUnitProperties.h>
#import <AudioToolbox/AudioServices.h>

#import "CAXException.h"
#import "DataCapture.h"
#import "SampleRecorder.h"
#import "VertexBuffer.h"
#import "VertexBufferManager.h"

struct AudioUnitRenderProcContext
{
    DataCapture* self;
    AudioUnit audioUnit;
    SEL processSamplesSelector;
    DataCaptureProcessSamplesProc processSamplesProc;
};

static const SInt32 kFloatToQ824 = 1 << 24;
static const Float32 kQ824ToFloat = Float32(1.0) / Float32(kFloatToQ824);

#define Q824_TO_FLOAT(V) ((V) * kQ824ToFloat);

@interface DataCapture(Private)

/** Initialize the audio session for the application.
 */
- (void)initializeAudioSession;

/** Initlialize the AudioUnit graph that we use to obtain samples from the microphone (if present) and to emit 
    a power signal for the external device (if present).
*/
- (void)initializeAudioUnit;

/** Start the AudioUnit graph to being signal processing.
 */
- (void)startAudioUnit;

/** Stop the AudioUnit graph.
 */
- (void)stopAudioUnit;

/** Determine if we are attached to an external device that has both input and outputs (mic + speakers).
 */
- (BOOL)isPluggedIn;

/** Determine if we are able to obtain audio input.
 */
- (BOOL)hasAudioInput;

/** Callback invoked when the audio route of the device changes. Evaluates the new route to see if we can use
    it for data collection and power harvesting.
*/
- (void)audioRouteDidChange:(CFDictionaryRef)dict;

/** Callback invoked when the audio session for the application is interrupted.
 */
- (void)audioSessionWasInterrupted:(UInt32)kind;

/** Callback invoked when the audio system has incoming samples to process.
 */
- (void)processSamples:(AudioBufferList*)ioData frameCount:(UInt32)frameCount atTime:(const AudioTimeStamp*)timeStamp;

@end

@implementation DataCapture

@synthesize audioUnit, maxAudioSampleCount, vertexBufferManager, sampleProcessor, switchDetector, sampleRecorder;
@synthesize audioUnitRunning, emittingPowerSignal, pluggedIn, sampleRate, processSamplesSelector, processSamplesProc;

+ (DataCapture*)create
{
    return [[[DataCapture alloc] init] autorelease];
}

- (id)init
{
    if ((self = [super init])) {
	audioUnit = nil;
	sampleProcessor = nil;
	switchDetector = nil;
	vertexBufferManager = nil;
	sampleRecorder = nil;
	maxAudioSampleCount = 0;
	sampleRate = 44100.0;
	powerSignal = nil;
	audioUnitRunning = NO;
	emittingPowerSignal = NO;
	pluggedIn = NO;
        sampleBuffer.clear();

	processSamplesSelector = @selector(processSamples:frameCount:atTime:);
	processSamplesProc = (DataCaptureProcessSamplesProc)[self methodForSelector:processSamplesSelector];

	audioUnitRenderProcContext = new AudioUnitRenderProcContext;
	[self initializeAudioSession];
    }

    return self;
}

- (void)dealloc
{
    delete audioUnitRenderProcContext;

    [self stop];
    self.sampleProcessor = nil;
    self.switchDetector = nil;
    self.vertexBufferManager = nil;
    self.sampleRecorder = nil;
    [super dealloc];
}

- (void)start
{
    if (audioUnit == nil) {
	self.pluggedIn = [self isPluggedIn];
	if (pluggedIn == NO) 
	    self.emittingPowerSignal = NO;

	[self initializeAudioUnit];
	if (audioUnit) {
	    [self startAudioUnit];
	}
    }
}

- (void)stop
{
    if (audioUnit) {
	[self stopAudioUnit];
	AudioComponentInstanceDispose(audioUnit);
	audioUnit = nil;
	delete [] powerSignal;
	powerSignal = 0;
    }
}

- (CAStreamBasicDescription*)streamFormat
{
    return &streamFormat;
}

@end // public interface

static void 
audioSessionInterruptionListener(void* context, UInt32 kind)
{
    [static_cast<DataCapture*>(context) audioSessionWasInterrupted:kind];
}

static void 
audioSessionPropertyListener(void* context, AudioSessionPropertyID inID, UInt32 inDataSize,
			     const void* inData)
{
    DataCapture* THIS = static_cast<DataCapture*>(context);
    if (inID == kAudioSessionProperty_AudioRouteChange) {
	CFDictionaryRef dict = static_cast<CFDictionaryRef>(inData);
	[THIS audioRouteDidChange:dict];
    }
}

static OSStatus
audioUnitRenderProc(void* context, AudioUnitRenderActionFlags* ioActionFlags, const AudioTimeStamp* inTimeStamp,
		    UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList* ioData)
{
    AudioUnitRenderProcContext* ctxt = static_cast<AudioUnitRenderProcContext*>(context);
    OSStatus err = AudioUnitRender(ctxt->audioUnit, ioActionFlags, inTimeStamp, 1, inNumberFrames, ioData);
    (ctxt->processSamplesProc)(ctxt->self, ctxt->processSamplesSelector, ioData, inNumberFrames, inTimeStamp);
    return err;
}

@implementation DataCapture(Private)

- (void)initializeAudioSession
{
    //
    // Initialize our audio session for simultaneous record and playback.
    //
    XThrowIfError(AudioSessionInitialize(NULL, // main run loop
					 NULL, // kCFRunLoopDefaultMode
					 audioSessionInterruptionListener, self),
		  "failed to initialize audio session");

    UInt32 value = kAudioSessionCategory_PlayAndRecord;
    XThrowIfError(AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(value), &value),
		  "failed to set audio category");
	
    XThrowIfError(AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange, audioSessionPropertyListener,
						  self), "failed to set property listener");

    //
    // Request small buffer for low-latency display and processing
    //
    Float32 preferredBufferSize = 0.005;
    XThrowIfError(AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration, 
					  sizeof(preferredBufferSize), &preferredBufferSize), 
		  "failed to set buffer duration");

    XThrowIfError(AudioSessionSetActive(true), "failed to set audio session active");
}

- (void)initializeAudioUnit
{
    try {
	//
	// Create AudioUnits graph that allows us to read from mic write to speakers.
	//
	AudioComponentDescription desc;
	desc.componentType = kAudioUnitType_Output;
	desc.componentSubType = kAudioUnitSubType_RemoteIO;
	desc.componentManufacturer = kAudioUnitManufacturer_Apple;
	desc.componentFlags = 0;
	desc.componentFlagsMask = 0;

	AudioComponent comp = AudioComponentFindNext(NULL, &desc);
	XThrowIfError(AudioComponentInstanceNew(comp, &audioUnit), "failed to open the remote I/O unit");

	//
	// Enable (1) mic (Bus 1 of Remote I/O)
	//
	AudioUnitElement bus = 1;
	UInt32 value = 1;
	XThrowIfError(AudioUnitSetProperty(audioUnit, 
                                           kAudioOutputUnitProperty_EnableIO, 
                                           kAudioUnitScope_Input, 
                                           bus,
					   &value, 
                                           sizeof(value)), "failed to enable mic");

	//
	// Install render callback so we can muck with input samples. (Bus 0 of remote I/O for speakers, headphones).
	// Install aspects of ourselves into the context object.
	//
	bus = 0;
	audioUnitRenderProcContext->self = self;
	audioUnitRenderProcContext->audioUnit = audioUnit;
	audioUnitRenderProcContext->processSamplesSelector = processSamplesSelector;
	audioUnitRenderProcContext->processSamplesProc = processSamplesProc;
        renderCallback.inputProc = audioUnitRenderProc;
        renderCallback.inputProcRefCon = audioUnitRenderProcContext;
	XThrowIfError(AudioUnitSetProperty(audioUnit,
                                           kAudioUnitProperty_SetRenderCallback, 
                                           kAudioUnitScope_Input, 
                                           bus, 
					   &renderCallback, 
                                           sizeof(renderCallback)), "failed to set render callback");

	//
	// Set our required format - Canonical AU format: LPCM non-interleaved 8.24 fixed point (1 channel)
	//
	streamFormat.SetAUCanonical(1, false);

	//
	// Set format for input to speakers/headphones
	//
	bus = 0;
	XThrowIfError(AudioUnitSetProperty(audioUnit, 
                                           kAudioUnitProperty_StreamFormat, 
                                           kAudioUnitScope_Input, 
                                           bus,
					   &streamFormat, 
                                           sizeof(streamFormat)), "failed to set speaker input format");

	//
	// Set format for output from mic.
	//
	bus = 1;
	XThrowIfError(AudioUnitSetProperty(audioUnit, 
                                           kAudioUnitProperty_StreamFormat, 
                                           kAudioUnitScope_Output, 
                                           bus,
					   &streamFormat, 
                                           sizeof(streamFormat)), "failed to set mic output format");
	XThrowIfError(AudioUnitInitialize(audioUnit), "failed to initialize the remote I/O unit");

	UInt32 size = sizeof(maxAudioSampleCount);
	XThrowIfError(AudioUnitGetProperty(audioUnit,
                                           kAudioUnitProperty_MaximumFramesPerSlice, 
                                           kAudioUnitScope_Global, 
                                           0,
					   &maxAudioSampleCount, 
                                           &size), "failed to get max sample count");
	NSLog(@"maxAudioSampleCount: %d", maxAudioSampleCount);

        sampleBuffer.clear();
        sampleBuffer.resize(maxAudioSampleCount, 0.0f);

	//
	// 8.24 fixed-point representation
	// 2^24 --> (1 << 24)
	// FIXED(I) -> (I << 24)
	// FIXED(R) -> (R * (1<<24))
	//
	powerSignal = new SInt32[maxAudioSampleCount];
	const SInt32 kAmplitude = 1 << 24; // +1 in Q8.24 format
	SInt32* ptr = powerSignal;
	for (UInt32 index = 0; index < maxAudioSampleCount; ++index, ++ptr) {
	    *ptr = kAmplitude * ( 1 - 2 * ( index & 1 ) ); // 1/2 of 44.1 kHz = 22.05 kHz
	}

	return;
    }
    catch (CAXException &e) {
	char buf[1024];
	fprintf(stderr, "Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
    }
    catch (...) {
	fprintf(stderr, "An unknown error occurred\n");
    }	

    //
    // Failure from above. Clean up.
    //
    if (audioUnit) {
	AudioComponentInstanceDispose(audioUnit);
	audioUnit = nil;
    }
}

- (void)startAudioUnit
{
    if (audioUnit != nil && audioUnitRunning == NO) {
	XThrowIfError(AudioSessionSetActive(true), "could not activate session");
	XThrowIfError(AudioOutputUnitStart(audioUnit), "could not start audio unit");
	audioUnitRunning = YES;
    }
}

- (void)stopAudioUnit
{
    if (audioUnit != nil && audioUnitRunning == YES) {
	audioUnitRunning = NO;
	XThrowIfError(AudioOutputUnitStop(audioUnit), "could not stop audio unit");
    }
}

- (void)audioSessionWasInterrupted:(UInt32)kind
{
    if (kind == kAudioSessionBeginInterruption) {
	NSLog(@"AudioSession BEGIN interruption\n");
	[self stopAudioUnit];
    }
    else if (kind == kAudioSessionEndInterruption) {
	NSLog(@"AudioSession END interruption\n");
	[self startAudioUnit];
    }
    else {
	NSLog(@"AudioSession unknown interruption - %d\n", kind);
    }
}

- (BOOL)hasAudioInput
{
    UInt32 value;
    UInt32 size = sizeof(value);
    XThrowIfError(AudioSessionGetProperty(kAudioSessionProperty_AudioInputAvailable, &size, &value),
		  "failed to get AudioInputAvailable property value");
    NSLog(@"hasAudioInput: %d", value);
    return value;
}

- (BOOL)isPluggedIn
{
    NSLog(@"iphone simulator - %d", TARGET_IPHONE_SIMULATOR);
#if TARGET_IPHONE_SIMULATOR
    return NO;
#endif

    CFStringRef audioRoute;
    UInt32 size = sizeof(CFStringRef);
    OSStatus err = AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &size, &audioRoute);
    if (err) {
	NSLog(@"failed to get audio route: %d", err);
	return NO;
    }

    NSLog(@"audio route: %@", audioRoute);

    BOOL result = CFStringCompare(audioRoute, CFSTR("HeadsetInOut"), 0) == kCFCompareEqualTo ? YES : NO;
    CFRelease(audioRoute);
	
    return result;
}

- (void)audioRouteDidChange:(CFDictionaryRef)dict
{
    UInt32 value;
    CFNumberRef routeChangeReasonRef = (CFNumberRef)CFDictionaryGetValue(dict, CFSTR(kAudioSession_AudioRouteChangeKey_Reason));
    CFNumberGetValue(routeChangeReasonRef, kCFNumberSInt32Type, &value);
    NSLog(@"route change reason: %d", value);

    BOOL audioInputAvailable = [self hasAudioInput];
    self.pluggedIn = [self isPluggedIn];

    //
    // Since we don't know what is plugged in, be safe and disable the power signal.
    //
    self.emittingPowerSignal = NO;

    if (audioUnitRunning == YES && audioInputAvailable == NO) {
	[self stopAudioUnit];
    }
    else if (audioUnitRunning == NO && audioInputAvailable == YES) {
	[self startAudioUnit];
    }
}

- (void)processSamples:(AudioBufferList*)ioData frameCount:(UInt32)frameCount atTime:(const AudioTimeStamp*)timeStamp
{
    UInt32 count = frameCount;
    SInt32* sptr = static_cast<SInt32*>(ioData->mBuffers[0].mData); 

    if (sampleBuffer.size() < frameCount) {
        sampleBuffer.resize(frameCount, 0.0f);
    }

    //
    // Save samples if recording
    //
    if (sampleRecorder != nil) {
	[sampleRecorder write:sptr maxLength:count];
    }

    //
    // Convert samples to floats
    //
    Float32* fptr = &sampleBuffer[0];
    for (UInt32 index = 0; index < count; ++index) {
        *fptr++ = Q824_TO_FLOAT(*sptr++);
    }

    fptr = &sampleBuffer[0];
    [sampleProcessor addSamples:fptr count:count];
    [switchDetector addSamples:fptr count:count];

    VertexBuffer* vertexBuffer = [vertexBufferManager getBufferForCount:count];
    if (vertexBuffer)
        [vertexBuffer addSamples:fptr count:count];

    if (emittingPowerSignal == YES) {
	for (UInt32 buffer = 0; buffer < ioData->mNumberBuffers; ++buffer ) {
	    memcpy(ioData->mBuffers[buffer].mData, powerSignal, ioData->mBuffers[buffer].mDataByteSize);
	}
    }
    else {
	for (UInt32 buffer=0; buffer < ioData->mNumberBuffers; ++buffer) {
	    memset(ioData->mBuffers[buffer].mData, 0, ioData->mBuffers[buffer].mDataByteSize);
	}
    }
}

@end
