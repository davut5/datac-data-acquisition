// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "BitFrameDecoder.h"

@implementation BitFrameDecoder

@synthesize buttonState, frequency, observer;

+ (NSInteger)integerFromBits:(NSString*)bits
{
    //
    // Given bits are in least-significant first ordering. Ignore the first and last ones since they represent the
    // start and stop bits.
    //
    NSInteger value = 0;
    for (NSInteger index = [bits length] - 2; index >= 1; --index) {
        value <<= 1;
        if ([bits characterAtIndex:index] == 49)
            value |= 1;
    }
    return value;
}

+ (id)create
{
    return [[[BitFrameDecoder alloc] init] autorelease];
}

- (id)init
{
    if (self = [super init]) {
        buttonState = 0;
        frequency = 0;
        observer = nil;
    }

    return self;
}

- (void)frameContentBitStream:(NSString*)bits
{
    //
    // First 10 bits make up the button state
    //
    buttonState = [BitFrameDecoder integerFromBits:[bits substringWithRange:NSMakeRange(0, 10)]];
    NSInteger msb = [BitFrameDecoder integerFromBits:[bits substringWithRange:NSMakeRange(10, 10)]];
    NSInteger lsb = [BitFrameDecoder integerFromBits:[bits substringWithRange:NSMakeRange(20, 10)]];
    frequency = msb * 256 + lsb;
    if (observer != nil) {
        [observer frameButtonState:buttonState frequency:frequency];
    }
}

@end
