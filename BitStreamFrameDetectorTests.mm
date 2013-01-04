// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "BitDetector.h"
#import "BitStreamFrameDetector.h"

@interface BitStreamFrameDetectorTests : SenTestCase {
    
}

@end

@implementation BitStreamFrameDetectorTests

- (void)testOne
{
    BitStreamFrameDetector* bsd = [BitStreamFrameDetector create];
    bsd.prefix = @"0010101011";
    bsd.suffix = @"0101010101";
    bsd.contentSize = 30;
    
    STAssertTrue(bsd.frameContents == nil, @"");
    
    [bsd nextBitValue:kBitDetectorLowBit];
    STAssertTrue([bsd.bits isEqualToString:@"0"], @"");
    
    [bsd nextBitValue:kBitDetectorLowBit];
    STAssertTrue([bsd.bits isEqualToString:@"00"], @"");
    
    [bsd nextBitValue:kBitDetectorHighBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorHighBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorHighBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorHighBit];
    [bsd nextBitValue:kBitDetectorHighBit];
    STAssertTrue([bsd.bits isEqualToString:@"0010101011"], @"");
    
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    STAssertTrue([bsd.bits isEqualToString:@"00101010110000000000"], @"");
    
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    STAssertTrue([bsd.bits isEqualToString:@"001010101100000000000000000000"], @"");
    
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    STAssertTrue([bsd.bits isEqualToString:@"0010101011000000000000000000000000000000"], @"");
    
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorHighBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorHighBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorHighBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorHighBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorHighBit];
    STAssertTrue([bsd.frameContents isEqualToString:@"000000000000000000000000000000"], @"");
    
    STAssertEquals([bsd.bits length], 0u, @"");
}

- (void)testTwo
{
    BitStreamFrameDetector* bsd = [BitStreamFrameDetector create];
    bsd.contentSize = 30;
    bsd.prefix = @"0010101011";
    bsd.suffix = @"0101010101";
    
    STAssertTrue(bsd.frameContents == nil, @"");
    
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorHighBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorHighBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorHighBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorHighBit];
    [bsd nextBitValue:kBitDetectorHighBit];
    STAssertTrue([bsd.bits isEqualToString:@"00010101011"], @"");
    
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    STAssertTrue([bsd.bits isEqualToString:@"000101010110000000000"], @"");
    
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    STAssertTrue([bsd.bits isEqualToString:@"0001010101100000000000000000000"], @"");
    
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    STAssertTrue([bsd.bits isEqualToString:@"00010101011000000000000000000000000000000"], @"");
    
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorHighBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorHighBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorHighBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorHighBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorHighBit];
    STAssertTrue([bsd.frameContents isEqualToString:@"000000000000000000000000000000"], @"");
    
    STAssertEquals([bsd.bits length], 0u, @"");
}

- (void)testThree
{
    BitStreamFrameDetector* bsd = [BitStreamFrameDetector create];
    bsd.contentSize = 1;
    bsd.prefix = @"01010101";
    bsd.suffix = @"10101010";
    
    STAssertTrue(bsd.frameContents == nil, @"");
    
    // 0x55
    [bsd nextBitValue:kBitDetectorLowBit]; // 1
    [bsd nextBitValue:kBitDetectorHighBit];// 2
    [bsd nextBitValue:kBitDetectorLowBit]; // 3
    [bsd nextBitValue:kBitDetectorHighBit];// 4
    [bsd nextBitValue:kBitDetectorLowBit]; // 5
    [bsd nextBitValue:kBitDetectorHighBit];// 6
    [bsd nextBitValue:kBitDetectorLowBit]; // 7
    [bsd nextBitValue:kBitDetectorHighBit];// 8
    
    // 0 bit
    [bsd nextBitValue:kBitDetectorLowBit]; // 9
    
    // 0x55
    [bsd nextBitValue:kBitDetectorLowBit]; // 10
    [bsd nextBitValue:kBitDetectorHighBit];// 11
    [bsd nextBitValue:kBitDetectorLowBit]; // 12
    [bsd nextBitValue:kBitDetectorHighBit];// 13
    [bsd nextBitValue:kBitDetectorLowBit]; // 14
    [bsd nextBitValue:kBitDetectorHighBit];// 15
    [bsd nextBitValue:kBitDetectorLowBit]; // 16
    [bsd nextBitValue:kBitDetectorHighBit];// 17
    STAssertTrue([bsd.bits isEqualToString:@"01010101"], @"");
    
    // 1 bit
    [bsd nextBitValue:kBitDetectorHighBit];
    
    // 0x55
    [bsd nextBitValue:kBitDetectorHighBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorHighBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorHighBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    [bsd nextBitValue:kBitDetectorHighBit];
    [bsd nextBitValue:kBitDetectorLowBit];
    
    STAssertTrue([bsd.frameContents isEqualToString:@"1"], @"");
    STAssertEquals([bsd.bits length], 0u, @"");
}
@end
