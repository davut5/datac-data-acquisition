// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "SignalProcessorController.h"

@implementation SignalProcessorController

@synthesize sampleView, infoOverlay, infoOverlayUpdateTimerInterval, infoOverlayUpdateTimer;

- (id)init
{
    if (self = [super init]) {
        sampleView = nil;
        infoOverlay = nil;
        infoOverlayUpdateTimerInterval = 1.0;
        infoOverlayUpdateTimer = nil;
    }

    return self;
}

- (void)dealloc
{
    self.sampleView = nil;
    self.infoOverlay = nil;
    [self.infoOverlayUpdateTimer invalidate];
    self.infoOverlayUpdateTimer = nil;
    [super dealloc];
}

- (void)drawOnSampleView:(GLfloat*)vertices
{
}

- (void)handlePanGesture:(UIPanGestureRecognizer*)recognizer
{
}

- (void)infoOverlayWillAppear
{
    self.infoOverlayUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:infoOverlayUpdateTimerInterval 
                                                                   target:self
                                                                 selector:@selector(updateInfoOverlay:)
                                                                 userInfo:nil
                                                                  repeats:YES];
    [self updateInfoOverlay:nil];
}

- (void)infoOverlayWillDisappear
{
    [infoOverlayUpdateTimer invalidate];
    self.infoOverlayUpdateTimer = nil;
}

- (void)updateInfoOverlay:(NSTimer*)timer
{
}

- (BOOL)showInfoOverlay
{
    return NO;
}

@end
