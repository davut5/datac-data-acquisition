// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "WaveCycleDetector.h"

@interface WaveCycleDetectorTests : SenTestCase<WaveCycleDetectorObserver> {
    BOOL found;
    NSUInteger width;
}

@end

@implementation WaveCycleDetectorTests

- (void)waveCycleDetected:(NSNumber*)theWidth
{
    found = YES;
    width = [theWidth unsignedIntegerValue];
}

- (void)test1 
{
    found = NO;
    WaveCycleDetector* zcd = [WaveCycleDetector createWithLevel:0.3];
    zcd.observer = self;
    Float32 samples1[] = { -0.5, -0.2, -0.01, 0.012, 0.3, 0.5, 0.6 };
    [zcd addSamples:samples1 count:7];

    [[NSRunLoop currentRunLoop] acceptInputForMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];

    STAssertTrue(found, @"expected found = YES");
    STAssertEquals(width, 5u, @"");
    
    found = NO;
    width = 0;

    Float32 samples2[] = { 0.75, 0.25, -0.01, -0.012, -0.3, -0.5, 0.3, 0.012, 0.75, 0.4 };
    [zcd addSamples:samples2 count:10];
    
    [[NSRunLoop currentRunLoop] acceptInputForMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];

    STAssertTrue(found, @"");
    STAssertEquals(width, 9u, @"");
    
    zcd.level = 0.4;
    [zcd addSamples:samples2 count:10];
    
    [[NSRunLoop currentRunLoop] acceptInputForMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];

    STAssertEquals(width, 8u, @"");
}

@end
