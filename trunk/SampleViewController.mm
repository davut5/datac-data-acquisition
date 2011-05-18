// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "AppDelegate.h"
#import "BitDetector.h"
#import "DataCapture.h"
#import "IndicatorButton.h"
#import "IndicatorLight.h"
#import "LevelDetector.h"
#import "SampleRecorder.h"
#import "LevelDetector.h"
#import "SignalProcessorController.h"
#import "SampleViewController.h"
#import "UserSettings.h"
#import "VertexBufferManager.h"

@interface SampleViewController(Private)

- (void)handleSingleTapGesture:(UITapGestureRecognizer*)recognizer;
- (void)handlePanGesture:(UIPanGestureRecognizer *)recognizer;
- (void)handlePinchGesture:(UIPinchGestureRecognizer *)recognizer;
- (void)switchStateChanged:(MicSwitchDetector*)sender;
- (void)adaptViewToOrientation:(NSTimeInterval)duration;
- (void)dismissInfoOverlay:(UITapGestureRecognizer*)recognizer;

@end

@implementation SampleViewController

@synthesize sampleView, powerIndicator, connectedIndicator, recordIndicator, infoOverlay;
@synthesize xMinLabel, xMaxLabel, yPos05Label, yZeroLabel, yNeg05Label, signalProcessorController;
@synthesize infoOverlayController;

//
// Maximum age of audio samples we can show at one go. Since we capture at 44.1kHz, that means 44.1k
// OpenGL vertices or 2 88.2k floats.
//
static const CGFloat kXMaxMin = 0.0001;
static const CGFloat kXMaxMax = 1.0;

- (id)initWithCoder:(NSCoder*)decoder
{
    NSLog(@"SampleViewController.initWithCoder");
    if (self = [super initWithCoder:decoder]) {
        appDelegate = nil;
    }
    
    return self;
}

- (void)dealloc {
    self.signalProcessorController = nil;
    self.infoOverlayController = nil;
    [super dealloc];
}

-(void)viewDidLoad 
{
    NSLog(@"SampleViewController.viewDidLoad");
    appDelegate = static_cast<AppDelegate*>([[UIApplication sharedApplication] delegate]);

    signalProcessorController = nil;
    sampleView.delegate = self;
    self.view.autoresizesSubviews = YES;
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    //
    // Register for notification when the DataCapture properties emittingPowerSignal and pluggedIn
    // change so we can update our display appropriately.
    //
    vertexBufferManager = appDelegate.vertexBufferManager;
    
    [appDelegate.dataCapture addObserver:self forKeyPath:NSStringFromSelector(@selector(emittingPowerSignal)) 
                                 options:0 context:nil];
    [appDelegate.dataCapture addObserver:self forKeyPath:NSStringFromSelector(@selector(pluggedIn)) 
                                 options:0 context:nil];
    
    appDelegate.switchDetector.delegate = self;
    
    //
    // Set widgets so that they will appear behind the graph view when we rotate to the landscape view.
    //
    powerIndicator.layer.zPosition = -1;
    connectedIndicator.layer.zPosition = -1;
    recordIndicator.layer.zPosition = -1;
    
    recordIndicator.light.onState = kRed;
    recordIndicator.light.blankedState = kDimRed;
    recordIndicator.light.blinkingInterval = 0.20;
    
    powerIndicator.on = NO;
    connectedIndicator.on = NO;
    recordIndicator.on = NO;

    //
    // Install single-tap gesture to freeze the display.
    //
    UITapGestureRecognizer* stgr = [[[UITapGestureRecognizer alloc]
                                     initWithTarget:self action:@selector(handleSingleTapGesture:)] 
                                    autorelease];
    [sampleView addGestureRecognizer:stgr];

    //
    // Install a 1 finger pan guesture to change the pulse detector levels
    //
    UIPanGestureRecognizer* pgr = [[[UIPanGestureRecognizer alloc] 
                                    initWithTarget:self action:@selector(handlePanGesture:)]
                                   autorelease];
    pgr.minimumNumberOfTouches = 1;
    pgr.maximumNumberOfTouches = 2;
    [sampleView addGestureRecognizer:pgr];

    //
    // Install a pinch gester to change xScale
    //
    UIPinchGestureRecognizer* pigr = [[[UIPinchGestureRecognizer alloc]
                                       initWithTarget:self action:@selector(handlePinchGesture:)]
                                      autorelease];
    [sampleView addGestureRecognizer:pigr];

    //
    // Install tap gesture to dismiss the info overlay
    //
    stgr = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissInfoOverlay:)] autorelease];
    [infoOverlay addGestureRecognizer:stgr];

    [self setXMax:[[NSUserDefaults standardUserDefaults] floatForKey:kSettingsInputViewXMaxKey]];
    
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    NSLog(@"SampleViewController.viewDidUnload");
    [self stop];
    self.signalProcessorController = nil;
    self.infoOverlayController = nil;
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    NSLog(@"SampleViewController.viewWillAppear");
    [self adaptViewToOrientation:0];
    [self start];
    self.signalProcessorController = [appDelegate.signalDetector controller];
    self.signalProcessorController.sampleView = sampleView;
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    NSLog(@"SampleViewController.viewWillDisappear");
    [self stop];
    self.signalProcessorController = nil;
    [super viewWillDisappear:animated];
}

- (void)start
{
    if (! [sampleView isAnimating]) {
	[self updateFromSettings];
	[sampleView startAnimation];
    }
}

- (void)stop
{
    if ([sampleView isAnimating]) {
	[sampleView stopAnimation];
    }
}

- (void)updateFromSettings
{
    Float32 rate = 1.0 / [[NSUserDefaults standardUserDefaults] floatForKey:kSettingsInputViewUpdateRateKey];
    if (rate != sampleView.animationInterval) {
	sampleView.animationInterval = rate;
	if (sampleView.animationTimer != nil) {
	    [sampleView stopAnimation];
	    [sampleView startAnimation];
	}
    }
}

- (IBAction)togglePower {
    NSLog(@"togglePower");
    powerIndicator.on = ! powerIndicator.on;
    [appDelegate.dataCapture setEmittingPowerSignal: powerIndicator.on];
}

- (IBAction)toggleRecord {
    NSLog(@"toggleRecord");
    recordIndicator.on = ! recordIndicator.on;
    if (recordIndicator.on == YES) {
	[appDelegate startRecording];
    }
    else {
	[appDelegate stopRecording];
    }
}

- (void)setXMax:(GLfloat)value
{
    xMax = value;
    xMaxLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%5.4gs", @"Format string for xMax label"), value];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change 
                       context:(void *)context
{
    //
    // !!! Be careful - this may be running in a thread other than the main one.
    //
    if ([keyPath isEqual:@"emittingPowerSignal"]) {
	powerIndicator.on = appDelegate.dataCapture.emittingPowerSignal;
    }
    else if ([keyPath isEqual:@"pluggedIn"]) {
	connectedIndicator.on = appDelegate.dataCapture.pluggedIn;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)didReceiveMemoryWarning {
    NSLog(@"Memory Warning");
    [super didReceiveMemoryWarning];
}

- (void)switchStateChanged:(MicSwitchDetector *)sender
{
    [self toggleRecord];
}

- (void)drawView:(SampleView*)sender
{
    glClear(GL_COLOR_BUFFER_BIT);
    
    //
    // Set scaling for the floating-point samples
    //
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrthof(0.0f, xMax, -1.0f, 1.0, -1.0f, 1.0f);
    
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    
    glColor4f(0., 1., 0., 1.);
    glLineWidth(1.25);
    glPushMatrix();
    [vertexBufferManager drawVerticesStartingAt:xMin forSpan:xMax];
    glPopMatrix();

    //
    // Draw three horizontal values at Y = -0.5, 0.0, and +0.5
    //
    GLfloat vertices[ 12 ];
    glVertexPointer(2, GL_FLOAT, 0, vertices);

    vertices[0] = 0.0;
    vertices[1] = -0.5;
    vertices[2] = xMax;
    vertices[3] = -0.5;

    vertices[4] = 0.0;
    vertices[5] = 0.0;
    vertices[6] = xMax;
    vertices[7] = 0.0;

    vertices[8] = 0.0;
    vertices[9] = 0.5;
    vertices[10] = xMax;
    vertices[11] = 0.5;

    glColor4f(.5, .5, .5, 1.0);
    glLineWidth(0.5);
    glDrawArrays(GL_LINES, 0, 6);

    if (signalProcessorController) {
        [signalProcessorController drawOnSampleView:vertices];
    }
}

- (void)handleSingleTapGesture:(UITapGestureRecognizer*)recognizer
{
    vertexBufferManager.frozen = ! vertexBufferManager.frozen;
}

- (void)dismissInfoOverlay:(UITapGestureRecognizer *)recognizer
{
    [self toggleInfoOverlay];
}

enum GestureType {
    kGestureUnknown,
    kGestureScaleXMax,
    kGestureSetMinHighLevel,
    kGestureSetMaxLowLevel
};

- (void)handlePanGesture:(UIPanGestureRecognizer*)recognizer
{
    if (signalProcessorController) {
        [signalProcessorController handlePanGesture:recognizer];
    }
}

#if 0
    CGFloat height = sampleView.bounds.size.height;

    if (recognizer.state == UIGestureRecognizerStateBegan) {
        gestureType = kGestureUnknown;
        CGPoint location = [recognizer locationInView:sampleView];
        CGFloat y = 1.0 - location.y * 2 / height;
        CGFloat minHighLevel = appDelegate.bitDetector.minHighLevel;
        CGFloat maxLowLevel = appDelegate.bitDetector.maxLowLevel;
        CGFloat dMin = fabs(y - minHighLevel);
        CGFloat dMax = fabs(y - maxLowLevel);
        if (dMin < dMax) {
            if (dMin < 0.10) {
                gestureType = kGestureSetMinHighLevel;
                gestureStart = minHighLevel;
            }
        }
        else {
            if (dMax < 0.10) {
                gestureType = kGestureSetMaxLowLevel;
                gestureStart = maxLowLevel;
            }
        }
    }
    else if (gestureType != kGestureUnknown) {
        CGPoint translate = [recognizer translationInView:sampleView];
        Float32 newLevel = gestureStart - translate.y * 2 / height;
	if (newLevel > 1.0) newLevel = 1.0;
	if (newLevel < -1.0) newLevel = -1.0;
        if (gestureType == kGestureSetMinHighLevel) {
            appDelegate.bitDetector.minHighLevel = newLevel;
            if (recognizer.state == UIGestureRecognizerStateEnded) {
                [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithFloat:newLevel]
                                                          forKey:kSettingsPulseDecoderMinHighLevelKey];
            }
        }
        else if (gestureType == kGestureSetMaxLowLevel) {
            appDelegate.bitDetector.maxLowLevel = newLevel;
            if (recognizer.state == UIGestureRecognizerStateEnded) {
                [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithFloat:newLevel]
                                                          forKey:kSettingsPulseDecoderMaxLowLevelKey];
            }
        }
    }
}
#endif

- (void)handlePinchGesture:(UIPinchGestureRecognizer*)recognizer
{
    CGFloat width = sampleView.bounds.size.width;
    CGFloat height = sampleView.bounds.size.height;
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        gestureType = kGestureScaleXMax;
        gestureStart = xMax;
    }
    else if (gestureType == kGestureScaleXMax && recognizer.scale != 0.0) {
        CGFloat newXMax = gestureStart / recognizer.scale;
        if (newXMax > kXMaxMax) newXMax = kXMaxMax;
        if (newXMax < kXMaxMin) newXMax = kXMaxMin;
        [self setXMax:newXMax];
        if (recognizer.state == UIGestureRecognizerStateEnded) {
            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithFloat:newXMax] 
                                                      forKey:kSettingsInputViewXMaxKey];
        }
    }
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
                                         duration:(NSTimeInterval)duration
{
    [self adaptViewToOrientation:duration];
}

- (void)adaptViewToOrientation:(NSTimeInterval)duration
{
    //
    // Place the grid labels in the appropriate location after a rotation event.
    //
    SInt32 offset = sampleView.frame.origin.y;
    SInt32 height = sampleView.frame.size.height;
    [UIView beginAnimations:@"" context:nil];
    [UIView setAnimationDuration:duration];
    yPos05Label.center = CGPointMake(yPos05Label.center.x, offset + 0.25 * height + 
                                     yPos05Label.bounds.size.height * 0.5 + 1);
    yZeroLabel.center = CGPointMake(yZeroLabel.center.x, offset + 0.5 * height + 
                                    yZeroLabel.bounds.size.height * 0.5 + 1);
    yNeg05Label.center = CGPointMake(yNeg05Label.center.x, offset + 0.75 * height + 
                                     yNeg05Label.bounds.size.height * 0.5 + 1);
    [UIView commitAnimations];
}

- (void)hideInfoOverlayDone:(NSString*)animationId finished:(NSNumber*)finished context:(void*)context
{
    infoOverlayController = nil;
    [infoOverlayController.view removeFromSuperview];
    infoOverlay.hidden = YES;
}

- (void)toggleInfoOverlay
{
    if (infoOverlay.hidden) {
        infoOverlayController = [appDelegate.signalDetector infoOverlayController];
        if (infoOverlayController) {
            
            //
            // Add the view managed by the infoOverlayController to our infoOverlay view and make them visible.
            //
            [infoOverlay addSubview:infoOverlayController.view];
            infoOverlay.hidden = NO;

            //
            // Reveal the infoOverlay view by popping it up from the tab bar at the bottom of the screen. End when
            // it is centered over the sampleView display.
            //
            CGPoint toPoint = sampleView.center;
            CGPoint fromPoint = toPoint;
            fromPoint.y = infoOverlay.bounds.size.height / 2 + self.view.window.bounds.size.height;
            infoOverlay.center = fromPoint;
            [UIView beginAnimations:@"" context:nil];
            infoOverlay.center = toPoint;
            [UIView commitAnimations];
        }
    }
    else {
        if (infoOverlayController) {

            //
            // Hide the infoOverlay view by dropping it into the tab bar at the bottom of the screen. When the 
            // animation is done, invoke hideInfoOverlayDone to remove the custom view from our infoOverlay view.
            //
            [UIView beginAnimations:@"" context:nil];
            [UIView setAnimationDelegate:self];
            [UIView setAnimationDidStopSelector:@selector(hideInfoOverlayDone:finished:context:)];
            CGPoint toPoint = infoOverlay.center;
            toPoint.y = infoOverlay.bounds.size.height / 2 + self.view.window.bounds.size.height;
            infoOverlay.center = toPoint;
            [UIView commitAnimations];
        }
    }
}

@end
