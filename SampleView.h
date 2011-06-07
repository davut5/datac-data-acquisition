// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

@class SampleView;

/** Protocol definition for an SampleView delegate.
    Implementers of this protocol must define a drawView: method
    that will be invoked by an SampleView object when rendering in
    its drawView method.
*/
@protocol SampleViewDelegate
@required
- (void)drawView:(SampleView*)sender;
@end

/** Derivation of UIView that uses OpenGL for rendering. Rendering
    occurs within the drawView method, which must be invoked by an
    external entity such as an NSTimer. It does not use the usual
    drawRect: way of updating the view.
 
    The startAnimation and stopAnimation methods start and stop an
    NSTimer task that will periodically invoke the drawView method.
    The update interval resides in the animationInterval property.
 
    The code is adapted from that found in Apple sample code.
*/
@interface SampleView : UIView
{
@private
    EAGLContext* context;
    GLuint viewRenderbuffer, viewFramebuffer;
    id <SampleViewDelegate> delegate;
    NSTimer* animationTimer;
    NSTimeInterval animationInterval;
}

- (void)startAnimation;
- (void)stopAnimation;
- (BOOL)isAnimating;

@property (nonatomic, retain) NSTimer* animationTimer;
@property (nonatomic, assign) NSTimeInterval animationInterval;
@property (nonatomic, assign) id <SampleViewDelegate> delegate;

@end
