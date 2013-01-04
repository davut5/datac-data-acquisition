// -*- Mode: ObjC -*-
// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "SampleCircularBuffer.h"

@interface SampleCircularBufferTests : SenTestCase {
    
}

@end

@implementation SampleCircularBufferTests

- (void)testOne
{
    SampleCircularBuffer* obj = [SampleCircularBuffer bufferWithCapacity:3 initialValue:1.0f];
    STAssertEquals(1.0f, [obj valueAt:0], @"");
    STAssertEquals(1.0f, [obj valueAt:1], @"");
    STAssertEquals(1.0f, [obj valueAt:2], @"");
    
    [obj addSample:0.0f];
    STAssertEquals(1.0f, [obj valueAt:0], @"");
    STAssertEquals(1.0f, [obj valueAt:1], @"");
    STAssertEquals(0.0f, [obj valueAt:2], @"");
    
    [obj addSample:0.5f];
    STAssertEquals(1.0f, [obj valueAt:0], @"");
    STAssertEquals(0.0f, [obj valueAt:1], @"");
    STAssertEquals(0.5f, [obj valueAt:2], @"");
    
    [obj addSample:0.2f];
    STAssertEquals(0.0f, [obj valueAt:0], @"");
    STAssertEquals(0.5f, [obj valueAt:1], @"");
    STAssertEquals(0.2f, [obj valueAt:2], @"");
    
    [obj addSample:0.4f];
    STAssertEquals(0.5f, [obj valueAt:0], @"");
    STAssertEquals(0.2f, [obj valueAt:1], @"");
    STAssertEquals(0.4f, [obj valueAt:2], @"");
    
    STAssertEquals(0.5f, [obj valueAt:3], @"");
    STAssertEquals(0.5f, [obj valueAt:27], @"");
    
    [obj clear];
    STAssertEquals(1.0f, [obj valueAt:0], @"");
    STAssertEquals(1.0f, [obj valueAt:1], @"");
    STAssertEquals(1.0f, [obj valueAt:2], @"");
}

- (void)testTwo
{
    SampleCircularBuffer* obj = [SampleCircularBuffer bufferWithCapacity:3 initialValue:1.0f];
    [obj addSample:0.1f];
    [obj addSample:0.2f];
    [obj addSample:0.3f];
    
    NSUInteger count;
    Float32* p = [obj valuesStartingAt:0 count:&count];
    STAssertEquals(count, 3u, @"");
    STAssertEquals(0.1f, *p++, @"");
    STAssertEquals(0.2f, *p++, @"");
    STAssertEquals(0.3f, *p++, @"");
    
    p = [obj valuesStartingAt:3 count:&count];
    STAssertEquals(count, 0u, @"");
    STAssertEquals(p, (Float32*)0, @"");
    
    [obj addSample:0.4f];
    p = [obj valuesStartingAt:0 count:&count];
    STAssertEquals(count, 2u, @"");
    STAssertEquals(0.2f, *p++, @"");
    STAssertEquals(0.3f, *p++, @"");
    
    p = [obj valuesStartingAt:2 count:&count];
    STAssertEquals(count, 1u, @"");
    STAssertEquals(0.4f, *p++, @"");
    
    p = [obj valuesStartingAt:3 count:&count];
    STAssertEquals(count, 0u, @"");
    STAssertEquals(p, (Float32*)0, @"");
    
    [obj addSample:0.5f];
    p = [obj valuesStartingAt:0 count:&count];
    STAssertEquals(count, 1u, @"");
    STAssertEquals(0.3f, *p++, @"");
    
    p = [obj valuesStartingAt:1 count:&count];
    STAssertEquals(count, 2u, @"");
    STAssertEquals(0.4f, *p++, @"");
    STAssertEquals(0.5f, *p++, @"");
    
    p = [obj valuesStartingAt:3 count:&count];
    STAssertEquals(count, 0u, @"");
    STAssertEquals(p, (Float32*)0, @"");
}

- (void)testThree
{
    SampleCircularBuffer* obj = [SampleCircularBuffer bufferWithCapacity:3 initialValue:1.0f];
    NSArray* spans = [obj valueSpans];
    STAssertEquals(1u, [spans count], @"");
    
    [obj addSample:0.1f];
    spans = [obj valueSpans];
    STAssertEquals(2u, [spans count], @"");
    
    [obj addSample:0.2f];
    spans = [obj valueSpans];
    STAssertEquals(2u, [spans count], @"");
    
    [obj addSample:0.3f];
    spans = [obj valueSpans];
    STAssertEquals(1u, [spans count], @"");
}

@end
