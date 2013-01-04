// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "WeightedAverager.h"

@interface WeightedAveragerTests : SenTestCase {
    
}

@end

@implementation WeightedAveragerTests

- (void)testOne
{
    WeightedAverager* wavg = [WeightedAverager createForSize:0];
    STAssertEquals(wavg.average, 0.0f, @"expected 0.0 initial average");
    STAssertEquals([wavg filter:10.0], 10.0f, @"expected 10.0");
    [wavg reset];
    STAssertEquals([wavg filter:10.0], 10.0f, @"expected 10.0 again");
}

- (void)testTwo
{
    WeightedAverager* wavg = [WeightedAverager createForSize:3];
    STAssertEquals(wavg.average, 0.0f, @"expected 0.0 initial average");
    
    Float32 avg = [wavg filter:10.0];
    STAssertEquals(avg, 5.0f, @"expected 5.0f");
    avg = [wavg filter:9.0];
    STAssertEqualsWithAccuracy(avg, 10.0f/3.0f + 9.0f/2.0f, 0.000001, @"expected 10/3 + 9/2");
    avg = [wavg filter:8.0];
    STAssertEqualsWithAccuracy(avg, 10.0f/6.0f + 9.0f/3.0f + 8.0f/2.0f, 0.000001, @"expected 10/6 + 9/3 + 8/2");
    avg = [wavg filter:8.0];
    STAssertEqualsWithAccuracy(avg, 9.0f/6.0f + 8.0f/3.0f + 8.0f/2.0f, 0.000001, @"expected 9/6 + 8/3 + 8/2");
    avg = [wavg filter:8.0];
    STAssertEqualsWithAccuracy(avg, 8.0f, 0.000001, @"expected 8.0");
    
    [wavg reset];
    STAssertEquals(wavg.average, 0.0f, @"expected 0.0 after reset");
}

@end
