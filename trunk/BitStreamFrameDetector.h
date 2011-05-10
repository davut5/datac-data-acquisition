// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BitDetectorObserver.h"
#import "BitStreamFrameDetectorObserver.h"

/** The BitStreamFrameDetector attemps to find sequences of bit values ('0' and '1') with length frameSize, where the 
 start of the frame consists of a predefined prefix (such as 0xAA or '10101010') and ends with a predefined suffix 
 (such as 0x55 or b01010101). The approach taken is quite simple: accumulate bits from a BitDetector and when there are 
 frameSize bits, check if the string starts with a given prefix value and ends with a given suffix value. If so, fire a
 frameContentBitStream: message to the registered observer with the frame contents, and clear the bits accumulator.
 */
@interface BitStreamFrameDetector : NSObject <BitDetectorObserver> {
@private
    NSMutableString* bits;      // Bit accumulator
    NSString* prefix;           // Prefix that signals the start of a valid frame
    NSString* suffix;           // Suffix that signals the end of a valid frame
    NSUInteger frameSize;       // The number of bits that make up a valid frame
    NSUInteger contentSize;     // frameSize - [prefix length] - [suffix length]
    NSString* frameContents;    // The contents from the last valid frame found
    NSObject<BitStreamFrameDetectorObserver>* observer;
}

@property (nonatomic, retain, readonly) NSMutableString* bits;
@property (nonatomic, assign) NSUInteger contentSize;
@property (nonatomic, retain) NSString* prefix;
@property (nonatomic, retain) NSString* suffix;
@property (nonatomic, retain, readonly) NSString* frameContents;
@property (nonatomic, retain) NSObject<BitStreamFrameDetectorObserver>* observer;

/** Factory method to create and initialize a new BitStreamFrameDetector object.
 */
+ (id)create;

/** Initialize a new BitStreamFrameDetector object.
 */
- (id)init;

@end
