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

- (Float32)lastDetectionValue
{
    return 0.0;
}

@end
