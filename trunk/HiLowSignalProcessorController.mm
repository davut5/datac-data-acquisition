// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "HiLowSignalProcessor.h"
#import "HiLowSignalProcessorController.h"
#import "SampleView.h"
#import "UserSettings.h"

@implementation HiLowSignalProcessorController

+ (id)createWithSignalProcessor:(HiLowSignalProcessor*)signalProcessor
{
    return [[[HiLowSignalProcessorController alloc] initWithSignalProcessor:signalProcessor] autorelease];
}

- (id)initWithSignalProcessor:(HiLowSignalProcessor*)theSignalProcessor
{
    if (self = [super init]) {
        signalProcessor = theSignalProcessor;
    }

    return self;
}

- (void)dealloc
{
    signalProcessor = nil;
    [super dealloc];
}

- (void)drawOnSampleView:(GLfloat*)vertices
{
#if 0
    vertices[1] = bitDetector.maxLowLevel;
    vertices[3] = bitDetector.maxLowLevel;
    glLineWidth(2.0);
    glColor4f(1., 1., 0., 1.0);
    glDrawArrays(GL_LINES, 0, 2);
    vertices[1] = bitDetector.minHighLevel;
    vertices[3] = bitDetector.minHighLevel;
    glColor4f(1., 0., 1., 1.0);
    glDrawArrays(GL_LINES, 0, 2);
#endif
}

enum GestureType {
    kGestureUnknown,
    kGestureSetMinHighLevel,
    kGestureSetMaxLowLevel
};

- (void)handlePanGesture:(UIPanGestureRecognizer*)recognizer
{
#if 0
    CGFloat height = sampleView.bounds.size.height;
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        gestureType = kGestureUnknown;
        CGPoint location = [recognizer locationInView:sampleView];
        CGFloat y = 1.0 - location.y * 2 / height;
        CGFloat minHighLevel = bitDetector.minHighLevel;
        CGFloat maxLowLevel = bitDetector.maxLowLevel;
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
            bitDetector.minHighLevel = newLevel;
            if (recognizer.state == UIGestureRecognizerStateEnded) {
                [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithFloat:newLevel]
                                                          forKey:kSettingsPulseDecoderMinHighLevelKey];
            }
        }
        else if (gestureType == kGestureSetMaxLowLevel) {
            bitDetector.maxLowLevel = newLevel;
            if (recognizer.state == UIGestureRecognizerStateEnded) {
                [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithFloat:newLevel]
                                                          forKey:kSettingsPulseDecoderMaxLowLevelKey];
            }
        }
    }
#endif
}

@end
