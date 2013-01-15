// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>

#import "SampleView.h"

@interface SampleView (Private)

- (void)setupView;
- (void)drawView:(NSTimer*)timer;
- (BOOL)createFramebuffer;
- (void)destroyFramebuffer;

@end

@implementation SampleView

@synthesize animationInterval, delegate;

+ (Class) layerClass
{
    return [CAEAGLLayer class];
}

- (id)initWithCoder:(NSCoder*)coder
{
    if((self = [super initWithCoder:coder])) {
        CAEAGLLayer* eaglLayer = (CAEAGLLayer*) self.layer;
        eaglLayer.opaque = YES;
        eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithBool:FALSE],
                                        kEAGLDrawablePropertyRetainedBacking,
                                        kEAGLColorFormatRGBA8,
                                        kEAGLDrawablePropertyColorFormat,
                                        nil];
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
        viewFramebuffer = 0;
        displayLink = nil;
    }

    return self;
}

-(void)setContext
{
    [EAGLContext setCurrentContext:context];
}

-(void)layoutSubviews
{
    [EAGLContext setCurrentContext:context];
    [self destroyFramebuffer];
    [self createFramebuffer];
    [self setupView];
    [self drawView:nil];
}

-(BOOL)createFramebuffer
{
    glGenFramebuffersOES(1, &viewFramebuffer);
    glGenRenderbuffersOES(1, &viewRenderbuffer);
    
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
    
    [context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(id<EAGLDrawable>)self.layer];
    glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, viewRenderbuffer);
    
    if(glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES) {
        LOG(@"failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
        return NO;
    }
	
    return YES;
}

- (void)destroyFramebuffer
{
    if (viewFramebuffer != 0) {
        glDeleteFramebuffersOES(1, &viewFramebuffer);
        viewFramebuffer = 0;
        glDeleteRenderbuffersOES(1, &viewRenderbuffer);
        viewRenderbuffer = 0;
    }
}

- (void)startAnimation
{
    LOG(@"SampleView.startAnimation");
    if (! displayLink) {
        displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(drawView:)];
        int interval = int(60 / animationInterval);
        if (interval < 1) interval = 1;
        if (interval > 10) interval = 10;
        [displayLink setFrameInterval:interval];
        LOG(@"interval: %d", interval);
        [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    }
}

- (void)stopAnimation
{
    LOG(@"SampleView.stopAnimation");
    if (displayLink) {
        [displayLink invalidate];
        displayLink = nil;
    }
}

- (void)setupView
{
    // Sets up matrices and transforms for OpenGL ES
    glDisable(GL_DITHER);
    glDisable(GL_ALPHA_TEST);
    glDisable(GL_BLEND);
    glDisable(GL_STENCIL_TEST);
    glDisable(GL_FOG);
    glDisable(GL_TEXTURE_2D);
    glDisable(GL_DEPTH_TEST);

    glViewport(0, 0, self.bounds.size.width, self.bounds.size.height);
    glClearColor(0.f, 0.f, 0.f, 1.0f);

    glEnableClientState(GL_VERTEX_ARRAY);
}

- (void)drawView:(id)sender
{
    if (self.hidden == NO) {
        [EAGLContext setCurrentContext:context];
        glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
        [delegate drawView:self];
        glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
        [context presentRenderbuffer:GL_RENDERBUFFER_OES];
    }
}

- (BOOL)isAnimating
{
    return displayLink != nil ? YES : NO;
}

- (void)dealloc
{
    [self stopAnimation];
    [self destroyFramebuffer];
    if ([EAGLContext currentContext] == context) {
        [EAGLContext setCurrentContext:nil];
    }
    
    [context release];
    context = nil;
	
    [super dealloc];
}

@end
