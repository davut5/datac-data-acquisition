// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "LevelDetector.h"
#import "LevelDetectorController.h"
#import "SampleView.h"
#import "UserSettings.h"

@implementation LevelDetectorController

+ (id)createWithLevelDetector:(LevelDetector*)theLevelDetector
{
    return [[[LevelDetectorController alloc] initWithLevelDetector:theLevelDetector] autorelease];
}

- (id)initWithLevelDetector:(LevelDetector*)theLevelDetector
{
    if (self = [super init]) {
        levelDetector = theLevelDetector;
    }

    return self;
}

- (void)dealloc
{
    levelDetector = nil;
    [super dealloc];
}

- (void)drawOnSampleView:(GLfloat*)vertices
{
    vertices[1] = levelDetector.level;
    vertices[3] = levelDetector.level;
    glLineWidth(2.0);
    glColor4f(1., 0., 0., 1.0);
    glDrawArrays(GL_LINES, 0, 2);
}

- (void)handlePanGesture:(UIPanGestureRecognizer*)recognizer
{
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
}

@end
