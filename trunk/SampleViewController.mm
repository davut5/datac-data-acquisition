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
@synthesize xMinLabel, xMaxLabel, yMaxLabel, yPos05Label, yZeroLabel, yNeg05Label, signalProcessorController;
@synthesize xMin, yMin, scale;

//
// Maximum age of audio samples we can show at one go. Since we capture at 44.1kHz, that means 44.1k
// OpenGL vertices or 2 88.2k floats.
//
static const CGFloat kScaleMin = 0.0001;
static const CGFloat kScaleMax = 1.0;
static const CGFloat kXMin =  0.0;
static const CGFloat kXMax =  1.0;
static const CGFloat kYMin = -1.0;
static const CGFloat kYMax =  1.0;

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
    // Install a 1 finger pan guesture to pan the display levels
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

    scale = 1.0;
    self.xMin = 0.0;    // Use self.xMin to update xMinLabel
    yMin = -1.0;
    self.scale = 1.0;   // Use self.scale to update xMaxLabel and set xSpan, ySpan

    [super viewDidLoad];
}

- (void)setScale:(CGFloat)value
{
    GLfloat yc = yMin + ySpan / 2.0f;

    if (value < kScaleMin) value = kScaleMin;
    if (value > kScaleMax) value = kScaleMax;

    scale = value;
    xSpan = scale * (kXMax - kXMin);
    ySpan = scale * (kYMax - kYMin);

    //
    // Move xMin back if the new scale would make xMax too large.
    //
    GLfloat xMax = xMin + xSpan;
    if (xMax > kXMax) {
        self.xMin = kXMax - xSpan;
        xMax = kXMax;
    }

    xMaxLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%5.4gs", @"Format string for X label"), xMax];

    self.yMin = yc - ySpan / 2.0f;
}

- (void)setXMin:(CGFloat)value
{
    if (value < kXMin) value = kXMin;

    //
    // Reduce value if it would make xMax too large.
    //
    GLfloat xMax = value + xSpan;
    if (xMax > kXMax) value = kXMax - xSpan;

    xMin = value;

    value = round(xMin * 10000.0) / 10000.0;
    xMinLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%5.4gs", @"Format string for X label"), value];

    value = round((xMin + xSpan) * 10000.0) / 10000.0;
    xMaxLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%5.4gs", @"Format string for X label"), value];
}
    
- (void)setYMin:(CGFloat)value
{
    if (value < kYMin) value = kYMin;

    //
    // Reduce value if it would make yMax too large.
    //
    GLfloat diff = (value + ySpan) - kYMax;
    if (diff > 0.0f) value -= diff;
    yMin = value;
    [self adaptViewToOrientation:0.0f];

    NSString* format = NSLocalizedString(@"%5.4gs", @"Format string for X label");

    value = round((yMin + 1.00 * ySpan) * 10000.0) / 10000.0;
    yMaxLabel.text = [NSString stringWithFormat:format, value];
    value = round((yMin + 0.75 * ySpan) * 10000.0) / 10000.0;
    yPos05Label.text = [NSString stringWithFormat:format, value];
    value = round((yMin + 0.50 * ySpan) * 10000.0) / 10000.0;
    yZeroLabel.text = [NSString stringWithFormat:format, value];
    value = round((yMin + 0.25 * ySpan) * 10000.0) / 10000.0;
    yNeg05Label.text = [NSString stringWithFormat:format, value];
}

- (void)viewDidUnload
{
    NSLog(@"SampleViewController.viewDidUnload");
    [self stop];
    self.signalProcessorController = nil;
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    NSLog(@"SampleViewController.viewWillAppear");
    [self adaptViewToOrientation:0];
    [self start];
    [appDelegate start];
    self.signalProcessorController = [appDelegate.signalDetector controller];
    signalProcessorController.sampleView = sampleView;
    signalProcessorController.infoOverlay = infoOverlay;
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
    glOrthof(xMin, xMin + xSpan, yMin, yMin + ySpan, -1.0f, 1.0f);

    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();

    glColor4f(0., 1., 0., 1.);
    glLineWidth(1.25);
    glPushMatrix();
    [vertexBufferManager drawVerticesStartingAt:xMin forSpan:xSpan];
    glPopMatrix();

    GLfloat xMax = xMin + xSpan;

    //
    // Draw three horizontal values at Y = -0.5, 0.0, and +0.5
    //
    GLfloat vertices[ 12 ];
    glVertexPointer(2, GL_FLOAT, 0, vertices);

    GLfloat y = yMin + 0.25 * ySpan;
    vertices[0] = 0.0;
    vertices[1] = y;
    vertices[2] = xMax;
    vertices[3] = y;

    y = yMin + 0.5 * ySpan;
    vertices[4] = 0.0;
    vertices[5] = y;
    vertices[6] = xMax;
    vertices[7] = y;

    y = yMin + 0.75 * ySpan;
    vertices[8] = 0.0;
    vertices[9] = y;
    vertices[10] = xMax;
    vertices[11] = y;

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
    kGestureScale,
    kGesturePan
};

- (void)handlePanGesture:(UIPanGestureRecognizer*)recognizer
{
    if ([recognizer numberOfTouches] == 2) {
        if (signalProcessorController) {
            [signalProcessorController handlePanGesture:recognizer];
        }
        return;
    }

    if (recognizer.state == UIGestureRecognizerStateBegan) {
        gestureType = kGesturePan;
        gesturePoint = [recognizer translationInView:sampleView];
    }
    else if (gestureType == kGesturePan) {
        CGFloat width = sampleView.bounds.size.width;
        CGFloat height = sampleView.bounds.size.height;
        CGPoint translate = [recognizer translationInView:sampleView];
        CGFloat dx = (gesturePoint.x - translate.x) / width;
        CGFloat dy = (translate.y - gesturePoint.y) / height;
        self.xMin = xMin + dx * xSpan;
        self.yMin = yMin + dy * ySpan;
        gesturePoint = translate;
        if (recognizer.state == UIGestureRecognizerStateEnded) {
            gestureType = kUnknownType;
        }
    }
}

- (void)handlePinchGesture:(UIPinchGestureRecognizer*)recognizer
{
    CGFloat width = sampleView.bounds.size.width;
    CGFloat height = sampleView.bounds.size.height;
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        gestureType = kGestureScale;
        gestureStart = scale;
    }
    else if (gestureType == kGestureScale) {
        if (recognizer.scale != 0.0) {
            CGFloat newScale = gestureStart / recognizer.scale;
            self.scale = newScale;
        }
        if (recognizer.state == UIGestureRecognizerStateEnded) {
            gestureType = kUnknownType;
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

    if (duration > 0.0f) {
        [UIView beginAnimations:@"" context:nil];
        [UIView setAnimationDuration:duration];
    }

    yPos05Label.center = CGPointMake(yPos05Label.center.x, offset + 0.25 * height + 
                                     yPos05Label.bounds.size.height * 0.5 + 1);

    yZeroLabel.center = CGPointMake(yZeroLabel.center.x, offset + 0.5 * height + 
                                    yZeroLabel.bounds.size.height * 0.5 + 1);

    yNeg05Label.center = CGPointMake(yNeg05Label.center.x, offset + 0.75 * height + 
                                     yNeg05Label.bounds.size.height * 0.5 + 1);

    if (duration > 0.0) {
        [UIView commitAnimations];
    }
}

- (void)hideInfoOverlayDone:(NSString*)animationId finished:(NSNumber*)finished context:(void*)context
{
    infoOverlay.hidden = YES;
}

- (void)toggleInfoOverlay
{
    if ([signalProcessorController showInfoOverlay] == NO) return;

    if (infoOverlay.hidden) {
        infoOverlay.hidden = NO;

        //
        // Add the view managed by the infoOverlayController to our infoOverlay view and make them visible.
        //
        [signalProcessorController infoOverlayWillAppear];

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
    else {

        //
        // Hide the infoOverlay view by dropping it into the tab bar at the bottom of the screen. When the 
        // animation is done, invoke hideInfoOverlayDone to remove the custom view from our infoOverlay view.
        //
        [signalProcessorController infoOverlayWillDisappear];
        [UIView beginAnimations:@"" context:nil];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(hideInfoOverlayDone:finished:context:)];
        CGPoint toPoint = infoOverlay.center;
        toPoint.y = infoOverlay.bounds.size.height / 2 + self.view.window.bounds.size.height;
        infoOverlay.center = toPoint;
        [UIView commitAnimations];
    }
}

@end
