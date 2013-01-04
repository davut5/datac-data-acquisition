// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

#import "PeakCounter.h"
#import "WeightedAverager.h"

@interface PeakCounterTests : SenTestCase {
    
}

@end

@implementation PeakCounterTests

- (void)testOne
{
    PeakCounter* alc = [PeakCounter createWithLevel:0.4f];
    STAssertEquals(0.4f, alc.level, @"");
    STAssertEquals(0ul, alc.counter, @"");
    
    Float32 samples[] = { 0.0f, 0.1f, 0.39f, 0.0f, 0.5f, 0.6f, 0.4f, 0.0f, 0.7f, 0.0f};
    [alc addSamples:samples count:10];
    STAssertEquals(2ul, alc.counter, @"");
    STAssertEquals(2ul, [alc counterAndReset], @"");
    STAssertEquals(0ul, [alc counterAndReset], @"");
    
    alc.level = 0.62f;
    [alc addSamples:samples count:10];
    STAssertEquals(1ul, [alc counterAndReset], @"");
    
    alc.level = 0.7f;
    [alc addSamples:samples count:10];
    STAssertEquals(1ul, [alc counterAndReset], @"");
    
    alc.level = 0.8f;
    [alc addSamples:samples count:10];
    STAssertEquals(0ul, [alc counterAndReset], @"");
    
    alc.level = 0.1f;
    [alc addSamples:samples count:10];
    STAssertEquals(3ul, [alc counterAndReset], @"");
    
    alc.lowPassFilter = [WeightedAverager createForSize:3];
    [alc reset];
    
    alc.level = 0.6f;
    [alc addSamples:samples count:10];
    STAssertEquals(0ul, [alc counterAndReset], @"");
    
    alc.level = 0.4f;
    [alc addSamples:samples count:10];
    STAssertEquals(2ul, [alc counterAndReset], @"");
}

@end
