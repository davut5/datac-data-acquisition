//
//  HiLowSignalProcessor.mm
//  Datac
//
//  Created by Brad Howes on 5/9/11.
//  Copyright 2011 Brad Howes. All rights reserved.
//

#import "BitDetector.h"
#import "BitFrameDecoder.h"
#import "BitStreamFrameDetector.h"
#import "HiLowSignalProcessor.h"

@implementation HiLowSignalProcessor

@synthesize bitDetector, bitFrameDecoder, bitStreamFrameDetector;

+ (HiLowSignalProcessor*)create
{
    return [[[HiLowSignalProcessor alloc] init] autorelease];
}

- (id)init
{
    if (self = [super init]) {
        bitDetector = [[BitDetector create] retain];
        bitFrameDecoder = [[BitFrameDecoder create] retain];
        bitStreamFrameDetector = [[BitStreamFrameDetector create] retain];
        bitDetector.observer = bitStreamFrameDetector;
        bitStreamFrameDetector.observer = bitFrameDecoder;
        bitFrameDecoder.observer = self;
    }

    return self;
}

- (void)start
{
}

- (void)stop
{
}

- (void)reset
{
}

- (void)updateFromSettings
{
}

- (SignalProcessorController*)controller
{
    return nil;
}

- (UIViewController*)infoOverlayController
{
    return nil;
}

- (NSObject<SampleProcessorProtocol>*)sampleProcessor
{
    return bitDetector;
}

- (void)frameButtonState:(NSInteger)buttonState frequency:(NSInteger)frequency
{
}

@end
