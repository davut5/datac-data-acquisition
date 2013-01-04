// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <AudioUnit/AUComponent.h>
#import <AudioUnit/AudioUnit.h>
#import <AudioUnit/AudioUnitProperties.h>
#import <AudioToolbox/AudioServices.h>

#import "CAStreamBasicDescription.h"
#import "AUOutputBL.h"
#import "RecordingInfo.h"
#import "SampleRecorder.h"
#import "UserSettings.h"

@interface SampleRecorder (Private)

- (void)updateSize;

@end

@implementation SampleRecorder

@synthesize recording, file;

+ (id)createRecording:(RecordingInfo*)recording withFormat:(CAStreamBasicDescription*)format
{
    return [[[SampleRecorder alloc] initRecording:recording withFormat:format] autorelease];
}

- (id)initRecording:(RecordingInfo*)theRecording withFormat:(CAStreamBasicDescription*)inputFormat
{
    if (self = [super init]) {
        self.recording = theRecording;
        runningSize = 0;
        updateCounter = 0;
        
        AudioFileTypeID audioFileType = [RecordingInfo getCurrentAudioFileType];
        
        //
        // Create format to use for the file. We base it off of the given AudioUnit format, but we make it a normal
        // PCM file.
        //
        CAStreamBasicDescription outputFormat;
        outputFormat.mSampleRate = inputFormat->mSampleRate;
        outputFormat.mFormatID = kAudioFormatLinearPCM;
        outputFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
        if (audioFileType == kAudioFileAIFFType) {
            outputFormat.mFormatFlags |= kAudioFormatFlagIsBigEndian;
        }
        
        outputFormat.mBytesPerPacket = outputFormat.mBytesPerFrame = 2 * inputFormat->mChannelsPerFrame;
        outputFormat.mChannelsPerFrame = inputFormat->mChannelsPerFrame;
        outputFormat.mFramesPerPacket = 1;
        outputFormat.mBitsPerChannel = 16;
        
        LOG(@"initRecording: path: %@", theRecording.filePath);
        LOG(@"initRecording: input format: %s", inputFormat->toString().c_str());
        LOG(@"initRecording: output format: %s", outputFormat.toString().c_str());
        
        OSStatus err = ExtAudioFileCreateWithURL((CFURLRef)[NSURL fileURLWithPath:theRecording.filePath],
                                                 //kAudioFileCAFType,
                                                 audioFileType,
                                                 &outputFormat,
                                                 NULL,
                                                 kAudioFileFlags_EraseFile,
                                                 &file);
        if (err) {
            LOG(@"failed ExtAudioFileCreateWithURL: %ld", err);
        }
        else {
            err = ExtAudioFileSetProperty(file,
                                          kExtAudioFileProperty_ClientDataFormat,
                                          sizeof(*inputFormat),
                                          inputFormat);
            if (err) {
                LOG(@"failed ExtAudioFileSetProperty: %ld", err);
            }
            else {
                err = ExtAudioFileWriteAsync(file, 0, 0);
                if (err) {
                    LOG(@"failed ExtAudioFileWriteAsync: %ld", err);
                }
            }
        }
        
        //
        // Allocate some buffers to use to hold sample values while ExtAudioFileWriteAsync runs.
        //
        for (int index = 0; index < 4; ++index) {
            AUOutputBL* buffer = new AUOutputBL(*inputFormat);
            buffers.push_back(buffer);
        }
    }
    return self;
}

- (void)dealloc
{
    while (! buffers.empty()) {
        delete buffers.back();
        buffers.pop_back();
    }
    
    [self close];
    [super dealloc];
}

- (void)close
{
    ExtAudioFileDispose(file);
    self.recording = nil;
    file = nil;
}

- (void)writeData:(AudioBufferList *)ioData frameCount:(UInt32)frameCount
{
    //
    // Grab the oldest buffer in our list and copy over the incoming AudioBufferList data so we don't have to worry
    // about it getting changed before it is written to disk.
    //
    AUOutputBL* buffer = buffers.back();
    buffers.pop_back();
    buffers.push_front(buffer);
    
    buffer->Allocate(frameCount);
    buffer->Prepare(frameCount);
    AudioBufferList* abl = buffer->ABL();
    
    AudioBuffer& from = ioData->mBuffers[0];
    AudioBuffer& to = abl->mBuffers[0];
    memcpy(to.mData, from.mData, from.mDataByteSize);
    to.mDataByteSize = from.mDataByteSize;
    runningSize += to.mDataByteSize;
    
    ExtAudioFileWriteAsync(file, frameCount, abl);
    
    if (++updateCounter == 100) {
        updateCounter = 0;
        [self performSelectorOnMainThread:@selector(updateSize) withObject:nil waitUntilDone:NO];
    }
}

@end

@implementation SampleRecorder (Private)

- (void)updateSize
{
    [recording updateSizeWith:runningSize];
}

@end
