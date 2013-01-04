// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "FrequencyDetector.h"

@interface FrequencyDetectorTests : SenTestCase<BitDetectorObserver> {
    NSString* lastBitValue;
}

@end

@implementation FrequencyDetectorTests

- (void)nextBitValue:(NSString*)value
{
    lastBitValue = value;
}

- (void)test1
{
    FrequencyDetector* fd = [FrequencyDetector createForSampleRate:44100 bitRate:150 lowFreq:4000 highFreq:8000];
    fd.observer = self;
    
    STAssertEquals(fd.nominalLowWaveLength, 11.025f, @"");
    STAssertEquals(fd.nominalHighWaveLength, 5.5125f, @"");
    STAssertEquals(fd.nominalHalfBitLength, 147.0f, @"");
    
    lastBitValue = nil;
    
    WaveCycleDetectorInfo* info = [[WaveCycleDetectorInfo alloc] init];
    info.sampleCount = 11;
    
    [fd waveCycleDetected:info];
    STAssertTrue(lastBitValue == nil, @"");
    STAssertTrue([fd.currentBitState isEqualToString:@"0"], @"");
    STAssertEquals(fd.currentBitLength, 11.0f, @"");
    
    info.sampleCount = 11;
    [fd waveCycleDetected:info];
    STAssertTrue(lastBitValue == nil, @"");
    STAssertTrue([fd.currentBitState isEqualToString:@"0"], @"");
    STAssertEquals(fd.currentBitLength, 22.0f, @"");
    
    [fd waveCycleDetected:info];
    STAssertTrue(lastBitValue == nil, @"");
    [fd waveCycleDetected:info];
    STAssertTrue(lastBitValue == nil, @"");
    [fd waveCycleDetected:info];
    STAssertTrue(lastBitValue == nil, @"");
    [fd waveCycleDetected:info];
    STAssertTrue(lastBitValue == nil, @"");
    [fd waveCycleDetected:info];
    STAssertTrue(lastBitValue == nil, @"");
    [fd waveCycleDetected:info];
    STAssertTrue(lastBitValue == nil, @"");
    [fd waveCycleDetected:info];
    STAssertTrue(lastBitValue == nil, @"");
    [fd waveCycleDetected:info];
    STAssertTrue(lastBitValue == nil, @"");
    [fd waveCycleDetected:info];
    STAssertTrue(lastBitValue == nil, @"");
    [fd waveCycleDetected:info];
    STAssertTrue(lastBitValue == nil, @"");
    [fd waveCycleDetected:info];
    STAssertTrue(lastBitValue == nil, @"");
    STAssertEquals(fd.currentBitLength, 143.0f, @"");
    
    [fd waveCycleDetected:info];
    [[NSRunLoop currentRunLoop] acceptInputForMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
    
    STAssertEquals(fd.currentBitLength, -140.0f, @"");
    
    STAssertTrue([fd.currentBitState isEqualToString:@"0"], @"");
    STAssertTrue(lastBitValue != nil, @"");
    
    [fd reset];
    lastBitValue = nil;
    info.sampleCount = 5;
    while (fd.currentBitLength >= 0.0) {
        [fd waveCycleDetected:info];
    }
    
    [[NSRunLoop currentRunLoop] acceptInputForMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
    
    STAssertEquals(fd.currentBitLength, -144.0f, @"");
    STAssertTrue([fd.currentBitState isEqualToString:@"1"], @"");
    STAssertTrue([lastBitValue isEqualToString:@"1"], @"");
    
    lastBitValue = nil;
    while (fd.currentBitLength <= 0.0) {
        [fd waveCycleDetected:info];
    }
    
    while (fd.currentBitLength >= 0.0) {
        [fd waveCycleDetected:info];
    }
    
    [[NSRunLoop currentRunLoop] acceptInputForMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
    
    STAssertEquals(fd.currentBitLength, -143.0f, @"");
    STAssertTrue([fd.currentBitState isEqualToString:@"1"], @"");
    STAssertTrue([lastBitValue isEqualToString:@"1"], @"");
    
    lastBitValue = nil;
    while (fd.currentBitLength <= 0.0) {
        [fd waveCycleDetected:info];
    }
    
    while (fd.currentBitLength >= 0.0) {
        [fd waveCycleDetected:info];
    }
    
    [[NSRunLoop currentRunLoop] acceptInputForMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
    
    STAssertEquals(fd.currentBitLength, -147.0f, @"");
    STAssertTrue([fd.currentBitState isEqualToString:@"1"], @"");
    STAssertTrue([lastBitValue isEqualToString:@"1"], @"");
}

@end
