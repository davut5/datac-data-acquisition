// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "LowPassFilter.h"

@interface LowPassFilterTests : SenTestCase {
    
}

@end

@implementation LowPassFilterTests

- (void)testOne
{
    //
    // Test as a running average filter. All taps have the same weight.
    //
    NSNumber* weight = [NSNumber numberWithFloat:0.25];
    LowPassFilter* wavg = [LowPassFilter createFromArray:[NSArray arrayWithObjects:weight, weight, weight, weight, nil]];
    Float32 avg = [wavg filter:1000.0];
    STAssertEquals(avg, 250.0f, @"");
    avg = [wavg filter:900.0];
    STAssertEquals(avg, 475.0f, @"");
    avg = [wavg filter:800.0];
    STAssertEquals(avg, 675.0f, @"");
    avg = [wavg filter:700.0];
    STAssertEquals(avg, 850.0f, @"");
    avg = [wavg filter:600.0];
    STAssertEquals(avg, 750.0f, @"");
    avg = [wavg filter:500.0];
    STAssertEquals(avg, 650.0f, @"");
    avg = [wavg filter:500.0];
    STAssertEquals(avg, 575.0f, @"");
    avg = [wavg filter:500.0];
    STAssertEquals(avg, 525.0f, @"");
    avg = [wavg filter:500.0];
    STAssertEquals(avg, 500.0f, @"");
    avg = [wavg filter:0.0];
    STAssertEquals(avg, 375.0f, @"");
}

@end
