// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "LevelSettingView.h"
#import "SignalProcessorController.h"

@implementation SignalProcessorController

@synthesize infoOverlay, infoOverlayUpdateTimerInterval, infoOverlayUpdateTimer, levelOverlay;

- (id)init
{
    if (self = [super init]) {
        infoOverlay = nil;
        infoOverlayUpdateTimerInterval = 1.0;
        infoOverlayUpdateTimer = nil;
        levelOverlay = nil;
    }

    return self;
}

- (void)dealloc
{
    [infoOverlay release];
    [infoOverlayUpdateTimer invalidate];
    self.infoOverlayUpdateTimer = nil;
    self.levelOverlay = nil;
    [super dealloc];
}

- (void)drawOnSampleView:(GLfloat*)vertices
{
}

- (Float32)distanceFromLevel:(Float32)value
{
    return 10000.0;
}

- (void)handlePanGesture:(UIPanGestureRecognizer*)recognizer viewPoint:(CGPoint)pos
{
}

- (void)infoOverlayWillAppear:(UITextView*)theInfoOverlay
{
    infoOverlay = [theInfoOverlay retain];
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
    [infoOverlay autorelease];
    infoOverlay = nil;
}

- (void)updateInfoOverlay:(NSTimer*)timer
{
}

- (BOOL)showInfoOverlay
{
    return NO;
}

- (void)showLevelOverlay:(NSString*)name withValue:(Float32)value
{
    [levelOverlay setName:name value:value];
}

@end
