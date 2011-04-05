//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>

#import "SampleView.h"

@interface SampleView (Private)

- (void)setupView;
- (BOOL)createFramebuffer;
- (void)destroyFramebuffer;

@end

@implementation SampleView

@synthesize animationTimer, animationInterval, applicationResignedActive, delegate;

+ (Class) layerClass
{
    return [CAEAGLLayer class];
}

- (id)initWithCoder:(NSCoder*)coder
{
    if((self = [super initWithCoder:coder])) {
	CAEAGLLayer *eaglLayer = (CAEAGLLayer*) self.layer;
	eaglLayer.opaque = YES;
	eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
							 [NSNumber numberWithBool:FALSE], 
						     kEAGLDrawablePropertyRetainedBacking, 
						     kEAGLColorFormatRGBA8, 
						     kEAGLDrawablePropertyColorFormat, 
						     nil];
	context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
	if (!context || ![EAGLContext setCurrentContext:context] || ![self createFramebuffer]) {
	    [self release];
	    return nil;
	}

	[self setupView];
	[self drawView];
    }

    return self;
}

-(void)layoutSubviews
{
    [EAGLContext setCurrentContext:context];
    [self destroyFramebuffer];
    [self createFramebuffer];
    [self setupView];
    [self drawView];
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
	NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
	return NO;
    }
	
    return YES;
}

- (void)destroyFramebuffer
{
    glDeleteFramebuffersOES(1, &viewFramebuffer);
    viewFramebuffer = 0;
    glDeleteRenderbuffersOES(1, &viewRenderbuffer);
    viewRenderbuffer = 0;
}

- (void)startAnimation
{
    self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:animationInterval
							   target:self selector:@selector(drawView) 
							 userInfo:nil
							  repeats:YES];
}

- (void)stopAnimation
{
    [animationTimer invalidate];
    self.animationTimer = nil;
}

- (void)setupView
{
    // Sets up matrices and transforms for OpenGL ES
    glViewport(0, 0, self.bounds.size.width, self.bounds.size.height);
    glClearColor(0.f, 0.f, 0.f, 1.0f);
    glEnableClientState(GL_VERTEX_ARRAY);
}

- (void)drawView
{
    if (animationTimer == nil) return;
    if (applicationResignedActive) return;
    [EAGLContext setCurrentContext:context];
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
    [delegate drawView:self];
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
    [context presentRenderbuffer:GL_RENDERBUFFER_OES];
}

- (BOOL)isAnimating
{
    return animationTimer != nil ? YES : NO;
}

- (void)dealloc
{
    [self stopAnimation];
	
    if([EAGLContext currentContext] == context) {
	[EAGLContext setCurrentContext:nil];
    }
	
    [context release];
    context = nil;
	
    [super dealloc];
}

@end
