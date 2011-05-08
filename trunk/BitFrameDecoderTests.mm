// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "BitFrameDecoder.h"

@interface BitFrameDecoderTests : SenTestCase {
    
}

@end

@implementation BitFrameDecoderTests

- (void)testOne
{
    NSInteger value;
    value = [BitFrameDecoder integerFromBits:@"0010101011"];
    STAssertEquals(value, 0xAA, @"Failed 0xAA conversion");
    value = [BitFrameDecoder integerFromBits:@"0101010101"];
    STAssertEquals(value, 0x55, @"Failed 0x55 conversion");
    value = [BitFrameDecoder integerFromBits:@"0111111111"];
    STAssertEquals(value, 0xFF, @"Failed 0xFF conversion");
    value = [BitFrameDecoder integerFromBits:@"0000000001"];
    STAssertEquals(value, 0x00, @"Failed 0x00 conversion");
}

@end
