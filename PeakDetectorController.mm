// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "PeakDetector.h"
#import "PeakDetectorController.h"
#import "SampleView.h"
#import "UserSettings.h"

@implementation PeakDetectorController

+ (id)createWithPeakDetector:(PeakDetector*)thePeakDetector
{
    return [[[PeakDetectorController alloc] initWithPeakDetector:thePeakDetector] autorelease];
}

- (id)initWithPeakDetector:(PeakDetector*)thePeakDetector
{
    if (self = [super init]) {
        peakDetector = thePeakDetector;
    }
    
    return self;
}

- (void)dealloc
{
    peakDetector = nil;
    [super dealloc];
}

- (void)drawOnSampleView:(GLfloat*)vertices
{
    vertices[1] = peakDetector.level;
    vertices[3] = peakDetector.level;
    glLineWidth(2.0);
    glColor4f(1., 0., 0., 1.0);
    glDrawArrays(GL_LINES, 0, 2);
}

- (Float32)distanceFromLevel:(Float32)value
{
    return fabs(peakDetector.level - value);
}

- (void)handlePanGesture:(UIPanGestureRecognizer*)recognizer viewPoint:(CGPoint)pos
{
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithFloat:peakDetector.level]
                                                  forKey:kSettingsPeakDetectorLevelKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    else {
        if (recognizer.state == UIGestureRecognizerStateBegan) {
            gestureStart = pos.y;
            gestureLevel = peakDetector.level;
        }
        else if (recognizer.state != UIGestureRecognizerStateEnded) {
            gestureLevel += (pos.y - gestureStart);
            gestureStart = pos.y;
            if (gestureLevel > 1.0) gestureLevel = 1.0;
            if (gestureLevel < -1.0) gestureLevel = -1.0;
            peakDetector.level = gestureLevel;
        }
        
        [self showLevelOverlay:NSLocalizedString(@"Level", @"Name of PeakDetector level") withValue:gestureLevel];
    }
}

- (BOOL)showInfoOverlay
{
    return YES;
}

- (void)updateInfoOverlay:(NSTimer*)timer
{
    LOG(@"PeakDetectorInfoOverlayController.updateInfo");
    NSString* counterHistory = [peakDetector counterHistoryAsString];
    NSString* filterValues = [peakDetector.counterDecayFilter description];
    NSString* content = [NSString stringWithFormat:
                         @"Peak Detector\n"
                         "Counter scale: %f\n"
                         "Detection scale: %f\n"
                         "Counters: %@\n"
                         "Decay filter: %@",
                         peakDetector.counterScale,
                         peakDetector.detectionScale,
                         counterHistory,
                         filterValues];
    self.infoOverlay.text = content;
}

@end
