//
//  HiLowSignalProcessor.h
//  Datac
//
//  Created by Brad Howes on 5/9/11.
//  Copyright 2011 Brad Howes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SignalProcessorProtocol.h"
#import "BitFrameDecoderOBserver.h"

@class BitDetector;
@class BitFrameDecoder;
@class BitStreamFrameDetector;

@interface HiLowSignalProcessor : NSObject<SignalProcessorProtocol, BitFrameDecoderObserver> {
@private
    BitDetector* bitDetector;
    BitStreamFrameDetector* bitStreamFrameDetector;
    BitFrameDecoder* bitFrameDecoder;
}

@property (nonatomic, retain) BitDetector* bitDetector;
@property (nonatomic, retain) BitStreamFrameDetector* bitStreamFrameDetector;
@property (nonatomic, retain) BitFrameDecoder* bitFrameDecoder;

+ (HiLowSignalProcessor*)create;

- (id)init;

@end
