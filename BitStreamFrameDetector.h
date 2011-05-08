// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BitDetector.h"

/** A protocol for obervers interested in new bit frame detections.
 */
@protocol BitStreamFrameDetectorObserver
@required

/** Notifcation sent out when the BitStreamFrameDetector finds a new valid frame.
 \param bits the stream of bits that define the frame.
 */
- (void)frameContentBitStream:(NSString*)bits;

@end

/** The BitStreamFrameDetector attemps to find sequences of bit values ('0' and '1') with length frameSize, where the 
 start of the frame consists of a predefined prefix (0xAA or '10101010') and ends with a predefined suffix 
 (0x55 or b01010101). The approach taken is quite simple: accumulate bits from a BitDetector and when there are 
 frameSize bits, check if the string starts with a given prefix value and ends with a given suffix value. If so, fire a
 frameContentBitStream: message to the registered observer with the frame contents, and clear the bits accumulator.
 Otherwise, remove the oldest bit and wait for another one.
 
 The matching algorithm is a bit brute-force, but it is extremely simple. With more complexity, one could detect invalid
 frames earlier, but without any improvement in response times, and the memory requirements for the detector are only
 frameSize characters.
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

@property (nonatomic, assign, readonly) NSMutableString* bits;
@property (nonatomic, assign, readonly) NSUInteger frameSize;
@property (nonatomic, assign, readonly) NSUInteger contentSize;
@property (nonatomic, retain, readonly) NSString* frameContents;
@property (nonatomic, retain) NSObject<BitStreamFrameDetectorObserver>* observer;

/** Factory method to create and initialize a new BitStreamFrameDetector object.
 \param size the number of bits found in a valid frame (frameSize)
 \param prefix the bit pattern that defines the start of a valid frame
 \param suffix the bit pattern that defines the end of a valid frame
 */
+ (id)createWithFrameSize:(NSUInteger)size framePrefix:(NSString*)prefix frameSuffix:(NSString*)suffix;

/** Initialize a new BitStreamFrameDetector object.
 */
- (id)initWithFrameSize:(NSUInteger)size framePrefix:(NSString*)prefix frameSuffix:(NSString*)suffix;

@end
