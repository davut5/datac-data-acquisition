// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "DetectorController.h"

@implementation DetectorController

@synthesize sampleView;

- (id)init
{
    if (self = [super init]) {
        sampleView = nil;
    }
    
    return self;
}

- (void)dealloc
{
    self.sampleView = nil;
    [super dealloc];
}

- (void)drawOnSampleView:(GLfloat*)vertices
{
}

- (void)handlePanGesture:(UIPanGestureRecognizer*)recognizer
{
}

@end
