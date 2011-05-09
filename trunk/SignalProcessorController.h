// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/ES1/gl.h>

@class SampleView;

/** Base class for all signal processor controller classes. Provides signal processors with the ability to display
    important level values in a SampleView view, and to adjust the level values via pan gestures.
 */
@interface SignalProcessorController : NSObject
{
    SampleView* sampleView;
    UIView* infoOverlay;
}

@property (nonatomic, retain) SampleView* sampleView;
@property (nonatomic, retain) UIView* infoOverlay;

/** Show signal processor level settings on the held SampleView instance.
    \param vertices an array of GLfloat values that are setup for fast plotting in the OpenGL context.
 */
- (void)drawOnSampleView:(GLfloat*)vertices;

/** Respond to the user's pan gesture.
    \param recognizer the pan gesture recognizer that is currently active
 */
- (void)handlePanGesture:(UIPanGestureRecognizer*)recognizer;

@end
