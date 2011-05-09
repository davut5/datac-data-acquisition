// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "AFSK.h"

@implementation AFSK

+ (AFSK*)create
{
    return nil;
}

- (id)init
{
    if (self = [super init]) {
    }
    
    return self;
}

- (void)reset
{
}

- (void)start
{
}

- (void)stop
{
}

- (void)updateFromSettings
{
}

- (NSObject<SampleProcessorProtocol>*)sampleProcessor
{
    return nil;
}

- (SignalProcessorController*)controller
{
    return nil;
}

- (UIViewController*)infoOverlayController
{
    return nil;
}

@end
