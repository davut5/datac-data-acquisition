// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/ES1/gl.h>

@class SampleView;

@interface DetectorController : NSObject
{
    SampleView* sampleView;
}

@property (nonatomic, retain) SampleView* sampleView;

- (void)drawOnSampleView:(GLfloat*)vertices;

- (void)handlePanGesture:(UIPanGestureRecognizer*)recognizer;

@end
