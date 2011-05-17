// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <AudioUnit/AUComponent.h>
#import <AudioUnit/AudioUnit.h>
#import <AudioUnit/AudioUnitProperties.h>
#import <AudioToolbox/AudioServices.h>

#import "RecordingInfo.h"
#import "SampleRecorder.h"

@interface SampleRecorder ()

- (void)setupAudioFormat:(UInt32)format;

- (void)updateSize;

@end

@implementation SampleRecorder

@synthesize outputStream, recording;

+ (id)createRecording:(RecordingInfo*)recording
{
    return [[[SampleRecorder alloc] initRecording:recording] autorelease];
}

- (id)initRecording:(RecordingInfo*)theRecording
{
    if (self = [super init]) {
	self.recording = theRecording;
        [self setupAudioFormat:kAudioFormatLinearPCM];
	self.outputStream = [NSOutputStream outputStreamToFileAtPath:recording.filePath append:NO];
	runningSize = 0;
	updateCounter = 0;
	[self.outputStream open];
    }

    return self;
}

- (void)dealloc
{
    [self close];
    [super dealloc];
}

- (void)setupAudioFormat:(UInt32)format
{
    memset(&recordFormat, 0, sizeof(recordFormat));
    UInt32 size = sizeof(recordFormat.mSampleRate);
    AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareSampleRate, &size, &recordFormat.mSampleRate);
    
    size = sizeof(recordFormat.mChannelsPerFrame);
    AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareInputNumberChannels, &size, 
                            &recordFormat.mChannelsPerFrame);

    recordFormat.mFormatID = format;
    if (format == kAudioFormatLinearPCM) {
        // if we want pcm, default to signed 16-bit little-endian
        recordFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
        recordFormat.mBitsPerChannel = 16;
        recordFormat.mBytesPerPacket = recordFormat.mBytesPerFrame = (recordFormat.mBitsPerChannel / 8) * 
        recordFormat.mChannelsPerFrame;
        recordFormat.mFramesPerPacket = 1;
    }
}

- (void)close
{
    if (outputStream) {
	[outputStream close];
	self.outputStream = nil;
	[recording finalizeSize];
	self.recording = nil;
    }
}

- (void)updateSize
{
    [recording updateSizeWith:runningSize];
}

- (void)write:(const SInt32*)ptr maxLength:(UInt32)count
{
    if (outputStream != nil) {
	count *= sizeof(SInt32);
	[outputStream write:reinterpret_cast<const uint8_t*>(ptr) maxLength:count];
	runningSize += count;
	if (++updateCounter == 100) {
	    updateCounter = 0;
	    [self performSelectorOnMainThread:@selector(updateSize) withObject:nil waitUntilDone:NO];
	}
    }
}

@end
