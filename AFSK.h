// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SampleProcessorProtocol.h"
#import "SignalProcessorProtocol.h"

@class AFSKController;
@class AFSKInfoOverlayController;

@interface AFSK : NSObject<SignalProcessorProtocol> {
@private
    AFSKController* controller;
    AFSKInfoOverlayController* infoOverlayController;
    NSTimer* intervalTimer;
}

+ (AFSK*)create;

- (id)init;

@end
