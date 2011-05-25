// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "PulseFrequencyDetector.h"
#import "PulseFrequencyDetectorController.h"
#import "SampleView.h"
#import "UserSettings.h"

@implementation PulseFrequencyDetectorController

+ (id)createWithDetector:(PulseFrequencyDetector*)theDetector
{
    return [[[PulseFrequencyDetectorController alloc] initWithDetector:theDetector] autorelease];
}

- (id)initWithDetector:(PulseFrequencyDetector*)theDetector
{
    if (self = [super init]) {
        detector = theDetector;
    }
    
    return self;
}

- (void)dealloc
{
    detector = nil;
    [super dealloc];
}

- (void)drawOnSampleView:(GLfloat*)vertices
{
    vertices[1] = detector.lowLevel;
    vertices[3] = detector.lowLevel;
    glLineWidth(2.0);
    glColor4f(.3, .3, 1., 1.0);
    glDrawArrays(GL_LINES, 0, 2);

    vertices[1] = detector.highLevel;
    vertices[3] = detector.highLevel;
    glLineWidth(2.0);
    glColor4f(1., 0., 0., 1.0);
    glDrawArrays(GL_LINES, 0, 2);
}

- (void)handlePanGesture:(UIPanGestureRecognizer*)recognizer
{
#if 0
    CGFloat height = sampleView.bounds.size.height;
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint location = [recognizer locationInView:sampleView];
        CGFloat y = 1.0 - location.y * 2 / height;
        CGFloat level = levelDetector.level;
        gestureStart = level;
    }
    else {
        CGPoint translate = [recognizer translationInView:sampleView];
        Float32 newLevel = gestureStart - translate.y * 2 / height;
	if (newLevel > 1.0) newLevel = 1.0;
	if (newLevel < -1.0) newLevel = -1.0;
        levelDetector.level = newLevel;
        if (recognizer.state == UIGestureRecognizerStateEnded) {
            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithFloat:newLevel]
                                                      forKey:kSettingsLevelDetectorLevelKey];
        }
    }
#endif
}

#if 0

- (BOOL)showInfoOverlay
{
    return NO;
}

- (void)updateInfoOverlay:(NSTimer*)timer
{
    NSLog(@"LevelDetectorInfoOverlayController.updateInfo");
    NSString* counterHistory = [levelDetector counterHistoryAsString];
    NSString* filterValues = [levelDetector.counterDecayFilter description];
    NSString* content = [NSString stringWithFormat:
                         @"Counter scale: %f\nDetection scale: %f\nCounters: %@\nDecay filter: %@",
                         levelDetector.counterScale,
                         levelDetector.detectionScale,
                         counterHistory,
                         filterValues];
    infoOverlay.text = content;
}

#endif

@end
