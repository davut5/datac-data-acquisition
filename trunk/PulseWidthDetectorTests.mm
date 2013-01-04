//
// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <vector>
#import <AudioToolbox/ExtendedAudioFile.h>
#import <SenTestingKit/SenTestingKit.h>

#import "PulseWidthDetector.h"
#import "WeightedAverager.h"

@interface PulseWidthDetectorTests : SenTestCase<PulseWidthDetectorProtocol> {
    std::vector<int> rawWidths;
    std::vector<Float32> filteredWidths;
    std::vector<Float32> samples;
    ExtAudioFileRef audioFile;
}

@end

@implementation PulseWidthDetectorTests

- (void)pulseDetected:(NSUInteger)thePulseToPulseWidth filtered:(Float32)filteredValue
{
    rawWidths.push_back(thePulseToPulseWidth);
    filteredWidths.push_back(filteredValue);
}

- (void)readMore
{
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
    
    int oss = ExtAudioFileRead(audioFile, &numFrames, &fillBufList);
    STAssertEquals(numFrames, 8192ul, @"");
    
    if (samples.capacity() < numFrames) {
        samples.reserve(numFrames);
    }
    
    samples.clear();
    
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
    
    STAssertEqualsWithAccuracy(min, -0.205878f, 0.01f, @"");
    STAssertEqualsWithAccuracy(max,  0.924497f, 0.01f, @"");
    
    rawWidths.clear();
    filteredWidths.clear();
}

- (void)testOne
{
    PulseWidthDetector* pfd = [PulseWidthDetector create];
    pfd.smoother = [WeightedAverager createForSize:3];
    pfd.observer = self;
    pfd.lowLevel = -0.1;
    pfd.highLevel = 0.0;
    pfd.minHighPulseAmplitude = 0.7;
    
    NSString* filePath = [[NSBundle bundleForClass:[self class] ] pathForResource:@"invertedAudio" ofType:@"wav"];
    STAssertNotNil(filePath, @"");
    
    NSURL* url = [NSURL fileURLWithPath:filePath];
    STAssertNotNil(url, @"");
    
    int oss = ExtAudioFileOpenURL((CFURLRef)url, &audioFile);
    STAssertTrue(oss == 0, @"failed ExtAudioFileOpenURL");
    
    [self readMore];
    STAssertEquals(samples.size(), 8192ul, @"");
    [pfd.sampleProcessor addSamples:&samples[0] count:samples.size()];
    STAssertEquals(rawWidths.size(), 6ul, @"");
    
    STAssertEquals(rawWidths[0], 682, @"");
    STAssertEquals(rawWidths[1], 1167, @"");
    STAssertEquals(rawWidths[2], 1571, @"");
    STAssertEquals(rawWidths[3], 1571, @"");
    STAssertEquals(rawWidths[4], 1572, @"");
    STAssertEquals(rawWidths[5], 1592, @"");
    
    STAssertEqualsWithAccuracy(filteredWidths[0], 341.0f, 0.01f, @"");
    STAssertEqualsWithAccuracy(filteredWidths[1], 810.83f, 0.01f, @"");
    STAssertEqualsWithAccuracy(filteredWidths[2], 1288.16f, 0.01f, @"");
    STAssertEqualsWithAccuracy(filteredWidths[3], 1503.66f, 0.01f, @"");
    STAssertEqualsWithAccuracy(filteredWidths[4], 1571.50f, 0.01f, @"");
    STAssertEqualsWithAccuracy(filteredWidths[5], 1581.83f, 0.01f, @"");
    
    [self readMore];
    STAssertEquals(samples.size(), 8192ul, @"");
    [pfd.sampleProcessor addSamples:&samples[0] count:samples.size()];
    STAssertEquals(rawWidths.size(), 5ul, @"");
    
    STAssertEquals(rawWidths[0], 1616, @"");
    STAssertEquals(rawWidths[1], 1593, @"");
    STAssertEquals(rawWidths[2], 1572, @"");
    STAssertEquals(rawWidths[3], 1571, @"");
    STAssertEquals(rawWidths[4], 1548, @"");
    
    STAssertEqualsWithAccuracy(filteredWidths[0], 1600.66f, 0.01f, @"");
    STAssertEqualsWithAccuracy(filteredWidths[1], 1600.50f, 0.01f, @"");
    STAssertEqualsWithAccuracy(filteredWidths[2], 1586.33f, 0.01f, @"");
    STAssertEqualsWithAccuracy(filteredWidths[3], 1575.00f, 0.01f, @"");
    STAssertEqualsWithAccuracy(filteredWidths[4], 1559.66f, 0.01f, @"");
    
    [self readMore];
    STAssertEquals(samples.size(), 8192ul, @"");
    [pfd.sampleProcessor addSamples:&samples[0] count:samples.size()];
    STAssertEquals(rawWidths.size(), 5ul, @"");
    
    STAssertEquals(rawWidths[0], 1571, @"");
    STAssertEquals(rawWidths[1], 1571, @"");
    STAssertEquals(rawWidths[2], 1571, @"");
    STAssertEquals(rawWidths[3], 1571, @"");
    STAssertEquals(rawWidths[4], 1571, @"");
    
    STAssertEqualsWithAccuracy(filteredWidths[0], 1563.33f, 0.01f, @"");
    STAssertEqualsWithAccuracy(filteredWidths[1], 1567.16f, 0.01f, @"");
    STAssertEqualsWithAccuracy(filteredWidths[2], 1571.00f, 0.01f, @"");
    STAssertEqualsWithAccuracy(filteredWidths[3], 1571.00f, 0.01f, @"");
    STAssertEqualsWithAccuracy(filteredWidths[4], 1571.00f, 0.01f, @"");
    
    [self readMore];
    STAssertEquals(samples.size(), 8192ul, @"");
    [pfd.sampleProcessor addSamples:&samples[0] count:samples.size()];
    STAssertEquals(rawWidths.size(), 5ul, @"");
    
    STAssertEquals(rawWidths[0], 1571, @"");
    STAssertEquals(rawWidths[1], 1549, @"");
    STAssertEquals(rawWidths[2], 1548, @"");
    STAssertEquals(rawWidths[3], 1526, @"");
    STAssertEquals(rawWidths[4], 1504, @"");
    
    STAssertEqualsWithAccuracy(filteredWidths[0], 1571.00f, 0.01f, @"");
    STAssertEqualsWithAccuracy(filteredWidths[1], 1560.00f, 0.01f, @"");
    STAssertEqualsWithAccuracy(filteredWidths[2], 1552.16f, 0.01f, @"");
    STAssertEqualsWithAccuracy(filteredWidths[3], 1537.16f, 0.01f, @"");
    STAssertEqualsWithAccuracy(filteredWidths[4], 1518.66f, 0.01f, @"");
    
    [self readMore];
    STAssertEquals(samples.size(), 8192ul, @"");
    [pfd.sampleProcessor addSamples:&samples[0] count:samples.size()];
    STAssertEquals(rawWidths.size(), 6ul, @"");
    
    STAssertEquals(rawWidths[0], 1481, @"");
    STAssertEquals(rawWidths[1], 1459, @"");
    STAssertEquals(rawWidths[2], 1459, @"");
    STAssertEquals(rawWidths[3], 1459, @"");
    STAssertEquals(rawWidths[4], 1414, @"");
    
    STAssertEqualsWithAccuracy(filteredWidths[0], 1496.16f, 0.01f, @"");
    STAssertEqualsWithAccuracy(filteredWidths[1], 1473.83f, 0.01f, @"");
    STAssertEqualsWithAccuracy(filteredWidths[2], 1462.66f, 0.01f, @"");
    STAssertEqualsWithAccuracy(filteredWidths[3], 1459.00f, 0.01f, @"");
    STAssertEqualsWithAccuracy(filteredWidths[4], 1436.50f, 0.01f, @"");
    
    
    oss = ExtAudioFileDispose(audioFile);
    STAssertEquals(oss, 0, @"failed ExtAudioFileDispose");
}


@end
