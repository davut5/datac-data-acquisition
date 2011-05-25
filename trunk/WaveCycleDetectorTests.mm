// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import <vector>
#import <AudioToolbox/ExtendedAudioFile.h>

#import "WaveCycleDetector.h"

@interface WaveCycleDetectorTests : SenTestCase<WaveCycleDetectorObserver> {
    BOOL found;
    NSUInteger width;
    std::vector<Float32> detections;
    std::vector<int> widths;
}

@end

@implementation WaveCycleDetectorTests

- (void)waveCycleDetected:(WaveCycleDetectorInfo*)info
{
    found = YES;
    width = info.sampleCount;
    detections.push_back(info.amplitude);
    widths.push_back(info.sampleCount);
}

- (void)test1 
{
    NSString* filePath = [[NSBundle bundleForClass:[self class] ] pathForResource:@"invertedAudio" ofType:@"wav"];
    STAssertNotNil(filePath, @"");
    
    NSURL* url = [NSURL fileURLWithPath:filePath];
    STAssertNotNil(url, @"");
    
    ExtAudioFileRef audioFile;
    int oss = ExtAudioFileOpenURL((CFURLRef)url, &audioFile);
    STAssertTrue(oss == 0, @"failed ExtAudioFileOpenURL");
    
    UInt32 bufferByteSize = 32768;
    char srcBuffer[bufferByteSize];
    
    AudioBufferList fillBufList;
    fillBufList.mNumberBuffers = 1;
    fillBufList.mBuffers[0].mNumberChannels = 2;
    fillBufList.mBuffers[0].mDataByteSize = bufferByteSize;
    fillBufList.mBuffers[0].mData = srcBuffer;
    
    // client format is always linear PCM - so here we determine how many frames of lpcm
    // we can read/write given our buffer size
    UInt32 numFrames = bufferByteSize / 4;

    oss = ExtAudioFileRead(audioFile, &numFrames, &fillBufList);
    
    STAssertEquals(numFrames, 8192ul, @"");
    
    std::vector<Float32> samples;
    samples.reserve(numFrames);
    
    char* bptr = srcBuffer;
    Float32 min, max;
    for (int index = 0; index < numFrames; ++index) {
        SInt16 s = SInt16(bptr[1]) * 256 + SInt16(bptr[0]);
        Float32 f = s / 32767.0;
        if (samples.empty()) {
            min = max = f;
        }
        else if (f < min) {
            min = f;
        }
        else if (f > max) {
            max = f;
        }
        
        bptr += 4;
        samples.push_back(f);
    }
    
    STAssertEqualsWithAccuracy(min, -0.205878f, 0.00001f, @"");
    STAssertEqualsWithAccuracy(max,  0.924497f, 0.00001f, @"");
    
    WaveCycleDetector* wcd = [WaveCycleDetector createWithLowLevel:-0.1 highLevel:0.0];
    wcd.observer = self;
    detections.clear();
    [wcd addSamples:&samples[0] count:samples.size()];

    STAssertEquals(detections.size(), 361ul, @"");
    for (int index = 1; index < 23; ++index) {
        STAssertEqualsWithAccuracy(detections[index], 0.9f, 0.25, @"");
    }

    for (int index = 23; index < 31; ++index) {
        STAssertEqualsWithAccuracy(detections[index], 0.28f, 0.4, @"");
    }

    for (int index = 31; index < 48; ++index) {
        STAssertEqualsWithAccuracy(detections[index], 0.9f, 0.25, @"");
    }

    for (int index = 48; index < 82; ++index) {
        STAssertEqualsWithAccuracy(detections[index], 0.28f, 0.4, @"");
    }

    for (int index = 82; index < 117; ++index) {
        STAssertEqualsWithAccuracy(detections[index], 0.9f, 0.25, @"");
    }
    
    oss = ExtAudioFileDispose(audioFile);
    STAssertEquals(oss, 0, @"failed ExtAudioFileDispose");
}

@end
