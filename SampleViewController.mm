// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "AppDelegate.h"
#import "BitDetector.h"
#import "DataCapture.h"
#import "IndicatorButton.h"
#import "IndicatorLight.h"
#import "LevelSettingView.h"
#import "PeakDetector.h"
#import "SampleRecorder.h"
#import "SignalProcessorController.h"
#import "SampleViewController.h"
#import "UserSettings.h"
#import "VertexBuffer.h"
#import "VertexBufferManager.h"

@interface SampleViewController(Private)

- (void)handleSingleTapGesture:(UITapGestureRecognizer*)recognizer;
- (void)handlePanGesture:(UIPanGestureRecognizer *)recognizer;
- (void)handlePinchGesture:(UIPinchGestureRecognizer *)recognizer;
- (void)switchStateChanged:(MicSwitchDetector*)sender;
- (void)dismissInfoOverlay:(UITapGestureRecognizer*)recognizer;
- (void)updateLabels;
- (void)updateKineticPan;

@end

@implementation SampleViewController

@synthesize sampleView, powerIndicator, connectedIndicator, recordIndicator, infoOverlay, levelOverlay;
@synthesize xMinLabel, xMaxLabel, yMaxLabel, yPos05Label, yZeroLabel, yNeg05Label, signalProcessorController;
@synthesize xMin, yMin, scale, vertexBuffer;

static const CGFloat kScaleMin = 0.0001;
static const CGFloat kScaleMax = 1.0;
static const CGFloat kXMin =  0.0;
static const CGFloat kXMax =  1.0;
static const CGFloat kYMin = -1.0;
static const CGFloat kYMax =  1.0;

enum GestureType {
    kGestureUnknown,
    kGestureScale,
    kGesturePan,
    kGestureSignalProcessor,
};

- (id)initWithCoder:(NSCoder*)decoder
{
    LOG(@"SampleViewController.initWithCoder");
    if (self = [super initWithCoder:decoder]) {
        appDelegate = nil;
    }
    
    return self;
}

- (void)dealloc
{
    self.vertexBuffer = nil;

    if (signalProcessorController) {
        [signalProcessorController release];
        signalProcessorController = nil;
    }
    [super dealloc];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

-(void)viewDidLoad
{
    LOG(@"SampleViewController.viewDidLoad");
    appDelegate = static_cast<AppDelegate*>([[UIApplication sharedApplication] delegate]);
    
    signalProcessorController = nil;
    sampleView.delegate = self;
    self.view.autoresizesSubviews = YES;
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    kineticPanActive = NO;
    
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
    connectedIndicator.on = NO;
    
    recordIndicator.light.onState = kRed;
    recordIndicator.light.blankedState = kDimRed;
    recordIndicator.light.blinkingInterval = 0.25;
    recordIndicator.on = NO;
    
    powerIndicator.light.onState = kYellow;
    powerIndicator.light.blankedState = kDimYellow;
    powerIndicator.on = NO;
    
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
    pgr.delegate = self;
    [sampleView addGestureRecognizer:pgr];
    
    //
    // Install a pinch gester to change xScale
    //
    UIPinchGestureRecognizer* pigr = [[[UIPinchGestureRecognizer alloc]
                                       initWithTarget:self action:@selector(handlePinchGesture:)]
                                      autorelease];
    pigr.delegate = self;
    [sampleView addGestureRecognizer:pigr];
    
    //
    // Install tap gesture to dismiss the info overlay
    //
    stgr = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissInfoOverlay:)] autorelease];
    [infoOverlay addGestureRecognizer:stgr];

    scale = kScaleMax;
    xMin = kXMin;
    xSpan = kXMax - kXMin;
    yMin = kYMin;
    ySpan = kYMax - kYMin;

    viewChanged = YES;
    vertexBuffer = nil;

    [self updateFromSettings];
    [super viewDidLoad];
}

- (SignalProcessorController*)signalProcessorController
{
    if (signalProcessorController == nil) {
        signalProcessorController = [[appDelegate.signalDetector controller] retain];
        signalProcessorController.levelOverlay = levelOverlay;
    }
    
    return signalProcessorController;
}

- (void)viewWillLayoutSubviews
{
    LOG(@"SampleViewController.viewWillLayoutSubviews: width: %f height: %f", self.view.bounds.size.width, self.view.bounds.size.height);
    viewChanged = YES;
}

- (void)setScale:(CGFloat)value
{
    if (value < kScaleMin) value = kScaleMin;
    if (value > kScaleMax) value = kScaleMax;

    if (scale != value) {
        viewChanged = YES;

        CGFloat yc = yMin + ySpan / 2.0f;
        scale = value;
        xSpan = scale * (kXMax - kXMin);
        ySpan = scale * (kYMax - kYMin);

        //
        // Move xMin back if the new scale would make xMax too large.
        //
        CGFloat xMax = xMin + xSpan;
        if (xMax > kXMax) {
            xMin = kXMax - xSpan;
        }

        self.yMin = yc - ySpan / 2.0f;
    }
}

- (void)setXMin:(CGFloat)value
{
    if (value < kXMin) value = kXMin;
    if (value != xMin) {
        viewChanged = YES;

        //
        // Reduce value if it would make xMax too large.
        //
        CGFloat xMax = value + xSpan;
        if (xMax > kXMax) value = kXMax - xSpan;

        xMin = value;
    }
}


- (void)setYMin:(CGFloat)value
{
    if (value < kYMin) value = kYMin;
    if (value != yMin) {
        viewChanged = YES;

        //
        // Reduce value if it would make yMax too large.
        //
        CGFloat diff = (value + ySpan) - kYMax;
        if (diff > 0.0f) value -= diff;
        yMin = value;
    }
}

- (void)viewDidUnload
{
    LOG(@"SampleViewController.viewDidUnload");
    [self stop];
    if (signalProcessorController) {
        [signalProcessorController release];
        signalProcessorController = nil;
    }
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    LOG(@"SampleViewController.viewWillAppear");
    [self start];
    sampleView.hidden = NO;
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    LOG(@"SampleViewController.viewWillDisappear");
//    [self stop];
    infoOverlay.hidden = YES;
    sampleView.hidden = YES;
    if (signalProcessorController) {
        [signalProcessorController release];
        signalProcessorController = nil;
    }
    [super viewWillDisappear:animated];
}

- (void)start
{
    if (! [sampleView isAnimating]) {
        LOG(@"SampleViewController.start");
        [sampleView startAnimation];
    }
}

- (void)stop
{
    if ([sampleView isAnimating]) {
        LOG(@"SampleViewController.stop");
        [sampleView stopAnimation];
    }
}

- (void)updateFromSettings
{
    self.scale = kScaleMax - [[NSUserDefaults standardUserDefaults] floatForKey:kSettingsInputViewScaleKey] + kScaleMin;
    int rate = [[NSUserDefaults standardUserDefaults] integerForKey:kSettingsInputViewUpdateRateKey];
    if (rate != sampleView.animationInterval) {
        sampleView.animationInterval = rate;
        if ([sampleView isAnimating]) {
            [sampleView stopAnimation];
            [sampleView startAnimation];
        }
    }
}

- (IBAction)togglePower {
    LOG(@"togglePower");
    powerIndicator.on = ! powerIndicator.on;
    [appDelegate.dataCapture setEmittingPowerSignal: powerIndicator.on];
}

- (IBAction)toggleRecord {
    LOG(@"toggleRecord");
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
    LOG(@"Memory Warning");
    [super didReceiveMemoryWarning];
}

- (void)switchStateChanged:(MicSwitchDetector *)sender
{
    if (appDelegate.dataCapture.pluggedIn == YES) {
        [self toggleRecord];
    }
}

- (void)drawView:(SampleView*)sender
{
    if (kineticPanActive) {
        [self updateKineticPan];
    }

    glClear(GL_COLOR_BUFFER_BIT);
    
    if (viewChanged) {
        viewChanged = NO;

        vertexBufferManager.xMin = xMin;
        vertexBufferManager.xMax = xMin + xSpan;
        vertexBufferManager.yMin = yMin;
        vertexBufferManager.yMax = yMin + ySpan;
        
        //
        // Set scaling for the floating-point samples
        //
        glMatrixMode(GL_PROJECTION);
        glLoadIdentity();

        glMatrixMode(GL_MODELVIEW);
        glLoadIdentity();
        glOrthof(xMin, xMin + xSpan, yMin, yMin + ySpan, -1.0f, 1.0f);

        [self updateLabels];
    }

    glColor4f(0., 1., 0., 1.);
    glLineWidth(1.25);
    [vertexBufferManager drawVertices];
    
    glBindBuffer(GL_ARRAY_BUFFER, 0);

    glVertexPointer(2, GL_FLOAT, 0, axis);
    GLfloat xMax = xMin + xSpan;

    //
    // Draw three horizontal values at Y = -0.5, 0.0, and +0.5
    //
    axis[0] = xMin;
    axis[1] = yAxes[0];
    axis[2] = xMax;
    axis[3] = yAxes[0];
    
    axis[4] = xMin;
    axis[5] = yAxes[1];
    axis[6] = xMax;
    axis[7] = yAxes[1];
    
    axis[8] = xMin;
    axis[9] = yAxes[2];
    axis[10] = xMax;
    axis[11] = yAxes[2];
    
    axis[12] = xMin;
    axis[13] = yAxes[3];
    axis[14] = xMax;
    axis[15] = yAxes[3];

    glColor4f(.5, .5, .5, 0.5);
    glLineWidth(0.5);
    glDrawArrays(GL_LINES, 0, 8);

    [self.signalProcessorController drawOnSampleView:axis];
}

- (void)handleSingleTapGesture:(UITapGestureRecognizer*)recognizer
{
    if (kineticPanActive) {
        kineticPanActive = NO;
    }
    else {
        vertexBufferManager.frozen = ! vertexBufferManager.frozen;
    }
}

- (void)dismissInfoOverlay:(UITapGestureRecognizer *)recognizer
{
    [self toggleInfoOverlay];
}

- (void)handlePanGesture:(UIPanGestureRecognizer*)recognizer
{
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
            gestureType = kGestureUnknown;

            //
            // If we have a signal processor, give it a chance to grab a setting line.
            //
            if (self.signalProcessorController != nil && recognizer.numberOfTouches == 2) {
                CGFloat height = sampleView.bounds.size.height;
                for (NSUInteger touchIndex = 0; touchIndex < recognizer.numberOfTouches; ++touchIndex) {
                    CGPoint pos = [recognizer locationOfTouch:touchIndex inView:sampleView];
                    CGFloat y = (1.0 - pos.y / height) * ySpan + yMin;
                    Float32 distance = [signalProcessorController distanceFromLevel:y] / ySpan;
                    if (distance < 0.05) {

                        //
                        // Touch is on the setting line. Let the signal processor adjust it.
                        //
                        gestureType = kGestureSignalProcessor;
                        CGFloat width = sampleView.bounds.size.width;
                        pos.x = pos.x / width * xSpan + xMin;
                        pos.y = y;
                        [signalProcessorController handlePanGesture:recognizer viewPoint:pos];
                        break;
                    }
                }
            }

            if (gestureType == kGestureUnknown) {
                CGPoint pos = [recognizer locationInView:sampleView];
            
                //
                // Initiate a pan.
                //
                gestureType = kGesturePan;
                gesturePoint = pos;
                gestureXMin = xMin;
                gestureYMin = yMin;
                [levelOverlay hide];
            }
            break;

        case UIGestureRecognizerStateChanged:
        case UIGestureRecognizerStateEnded:
            CGPoint pos = [recognizer locationInView:sampleView];
            CGFloat width = sampleView.bounds.size.width;
            CGFloat height = sampleView.bounds.size.height;
            switch (gestureType) {
                case kGestureSignalProcessor:
                    if (self.signalProcessorController) {
                        pos.x = pos.x / width * xSpan + xMin;
                        pos.y = (1.0 - pos.y / height) * ySpan + yMin;
                        [signalProcessorController handlePanGesture:recognizer viewPoint:pos];
                    }
                    break;

                case kGesturePan:
                    CGFloat dx = (gesturePoint.x - pos.x) / width;
                    CGFloat dy = (pos.y - gesturePoint.y) / height;
                    if (dx != 0.0 || dy != 0.0) {
                        self.xMin = gestureXMin + dx * xSpan;
                        self.yMin = gestureYMin + dy * ySpan;
                    }
                    break;
            }
            break;
    }

    if (recognizer.state == UIGestureRecognizerStateEnded) {
        gestureType = kUnknownType;
    }
}

- (void)updateKineticPan
{
    CGFloat width = sampleView.bounds.size.width;
    CGFloat height = sampleView.bounds.size.height;
    CGFloat dx = kineticPanVelocity.x * xSpan / width;
    CGFloat dy = kineticPanVelocity.y * ySpan / height;
    if (dx) {
        self.xMin = xMin - dx;
        if (kineticPanVelocity.x > 0) kineticPanVelocity.x -= 1;
        else if (kineticPanVelocity.x <0) kineticPanVelocity.x += 1;
    }
    
    if (dy) {
        self.yMin = yMin + dy;
        if (kineticPanVelocity.y > 0) kineticPanVelocity.y -= 1;
        else if (kineticPanVelocity.y <0) kineticPanVelocity.y += 1;
    }
    
    kineticPanActive = kineticPanVelocity.x != 0 || kineticPanVelocity.y != 0;
}

- (void)handlePinchGesture:(UIPinchGestureRecognizer*)recognizer
{
    [levelOverlay hide];
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
            [[NSUserDefaults standardUserDefaults] setFloat:(kScaleMax - scale + kScaleMin)
                                                     forKey:kSettingsInputViewScaleKey];
        }
    }
}

- (void)updateLabels
{
    // LOG(@"SampleViewController.updateLabels");

    CGFloat value = round(xMin * 10000.0) / 10000.0;
    xMinLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%5.4gs", @"Format string for X label"), value];
    
    value = round((xMin + xSpan) * 10000.0) / 10000.0;
    xMaxLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%5.4gs", @"Format string for X label"), value];

    SInt32 offset = sampleView.frame.origin.y;
    SInt32 height = sampleView.frame.size.height;
    int index = 0;

    //
    // Calculate parameterized value [0, 1] of label within the view.
    //
    CGFloat t = (0.0 - yMin) / ySpan;
    if (t <= 0.0) {
        t += (int((0.0 - t) / 0.25) + 1) * 0.25;
    }
    
    while (t <= 1.0) {
        yAxes[index++] = t;
        t+= 0.25;
    }

    t = (0.0 - yMin) / ySpan - 0.25;
    if (t > 1.0) {
        t -= (int((t - 1.0) / 0.25) + 1) * 0.25;
    }
    
    while (t > 0.0) {
        yAxes[index++] = t;
        t -= 0.25;
    }
    
    NSString* format = NSLocalizedString(@"%5.4g", @"Format string for Y labels");
    
    yNeg05Label.center = CGPointMake(yNeg05Label.center.x, offset + height * (1 - yAxes[0]) +
                                     yNeg05Label.bounds.size.height * 0.5 + 1);
    CGFloat y = yMin + yAxes[0] * ySpan;
    yAxes[0] = y;
    value = round(y * 10000.0) / 10000.0;
    yNeg05Label.text = [NSString stringWithFormat:format, value];
    
    yZeroLabel.center = CGPointMake(yZeroLabel.center.x, offset + height * (1 - yAxes[1])+
                                    yZeroLabel.bounds.size.height * 0.5 + 1);
    y = yMin + yAxes[1] * ySpan;
    yAxes[1] = y;
    value = round(y * 10000.0) / 10000.0;
    yZeroLabel.text = [NSString stringWithFormat:format, value];
    
    yPos05Label.center = CGPointMake(yPos05Label.center.x, offset + height * (1 - yAxes[2]) +
                                     yPos05Label.bounds.size.height * 0.5 + 1);
    y = yMin + yAxes[2] * ySpan;
    yAxes[2] = y;
    value = round(y * 10000.0) / 10000.0;
    yPos05Label.text = [NSString stringWithFormat:format, value];
    
    yMaxLabel.center = CGPointMake(yMaxLabel.center.x, offset + height * (1 - yAxes[3]) +
                                   yMaxLabel.bounds.size.height * 0.5 + 1);
    y = yMin + yAxes[3] * ySpan;
    yAxes[3] = y;
    value = round(y * 10000.0) / 10000.0;
    yMaxLabel.text = [NSString stringWithFormat:format, value];
}

- (void)hideInfoOverlayDone:(NSString*)animationId finished:(NSNumber*)finished context:(void*)context
{
    infoOverlay.hidden = YES;
}

- (void)toggleInfoOverlay
{
    if ([self.signalProcessorController showInfoOverlay] == NO) return;
    
    if (infoOverlay.hidden) {
        infoOverlay.hidden = NO;
        
        //
        // Add the view managed by the infoOverlayController to our infoOverlay view and make them visible.
        //
        [self.signalProcessorController infoOverlayWillAppear: infoOverlay];
        
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
        [self.signalProcessorController infoOverlayWillDisappear];
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
