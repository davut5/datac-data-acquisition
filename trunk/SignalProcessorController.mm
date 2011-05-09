// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "SignalProcessorController.h"

@implementation SignalProcessorController

@synthesize sampleView, infoOverlay;

- (id)init
{
    if (self = [super init]) {
        sampleView = nil;
        infoOverlay = nil;
    }

    return self;
}

- (void)dealloc
{
    self.sampleView = nil;
    self.infoOverlay = nil;
    [super dealloc];
}

- (void)drawOnSampleView:(GLfloat*)vertices
{
}

- (void)handlePanGesture:(UIPanGestureRecognizer*)recognizer
{
}

@end
