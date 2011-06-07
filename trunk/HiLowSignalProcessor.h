// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SignalProcessorProtocol.h"
#import "BitFrameDecoderOBserver.h"

@class BitDetector;
@class BitFrameDecoder;
@class BitStreamFrameDetector;
@class HiLowSignalProcessorController;

@interface HiLowSignalProcessor : NSObject<SignalProcessorProtocol, BitFrameDecoderObserver> {
@private
    BitDetector* bitDetector;
    BitStreamFrameDetector* bitStreamFrameDetector;
    BitFrameDecoder* bitFrameDecoder;
    HiLowSignalProcessorController* controller;
    Float32 frequency;
}

@property (nonatomic, retain) BitDetector* bitDetector;
@property (nonatomic, retain) BitStreamFrameDetector* bitStreamFrameDetector;
@property (nonatomic, retain) BitFrameDecoder* bitFrameDecoder;
@property (nonatomic, assign) Float32 maxLowLevel;
@property (nonatomic, assign) Float32 minHighLevel;

+ (HiLowSignalProcessor*)create;

- (id)init;

@end
