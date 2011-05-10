// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BitStreamFrameDetectorObserver.h"
#import "BitFrameDecoderObserver.h"

/** The BitFrameDecoder accepts a string of bit values ("1" and "0") from a BitStreamFrameDetector and decodes the 
 payload values, emitting them to a registered observer via the BitFrameDecoderObserver protocol.
 */
@interface BitFrameDecoder : NSObject <BitStreamFrameDetectorObserver> {
@private
    NSInteger buttonState;
    NSInteger frequency;
    NSObject<BitFrameDecoderObserver>* observer;
}

@property (nonatomic, assign, readonly) NSInteger buttonState;
@property (nonatomic, assign, readonly) NSInteger frequency;
@property (nonatomic, retain) NSObject<BitFrameDecoderObserver>* observer;

/** Tranlate a string containing 10 '0' and '1' characters into an equivalent integer value, treating the first and last
 bits as start and stop bits (ignoring them). The ordering of the bits is LSB->MSB.
 \param bits a string of length 10 containgin '0' and '1' characters
 \result integer value in the range [-128 - 127).
 */
+ (NSInteger)integerFromBits:(NSString*)bits;

/** Factory method to create an initialize a new BitFrameDecoder object.
 */
+ (id)create;

/** Initialize a new BitFrameDecoder object.
 */
- (id)init;

@end
