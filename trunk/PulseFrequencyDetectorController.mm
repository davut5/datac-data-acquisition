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
    glColor4f(1., 0., 1., 1.0);
    glDrawArrays(GL_LINES, 0, 2);

    vertices[1] = detector.highLevel;
    vertices[3] = detector.highLevel;
    glLineWidth(2.0);
    glColor4f(1., .5, 0., 1.0);
    glDrawArrays(GL_LINES, 0, 2);

    vertices[1] = detector.minHighPulseAmplitude;
    vertices[3] = detector.minHighPulseAmplitude;
    glLineWidth(2.0);
    glColor4f(1., 0., 0., 1.0);
    glDrawArrays(GL_LINES, 0, 2);
}

enum GestureKind {
    kAdjustLowLevel,
    kAdjustHighLevel,
    kAdjustMinAmplitude,
    kUnknown
};

struct HitInfo
{
    GestureKind kind;
    CGFloat level;
    CGFloat delta;
    HitInfo(GestureKind k, CGFloat l, CGFloat y)
        : kind(k), level(l), delta(fabs(l - y)) 
    {}

    bool operator<(const HitInfo& rhs) const { return delta < rhs.delta; }
};

- (void)handlePanGesture:(UIPanGestureRecognizer*)recognizer viewPoint:(CGPoint)pos
{
    CGFloat height = sampleView.bounds.size.height;
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        HitInfo a(kAdjustLowLevel, detector.lowLevel, pos.y);
        HitInfo b(kAdjustHighLevel, detector.highLevel, pos.y);
        HitInfo c(kAdjustMinAmplitude, detector.minHighPulseAmplitude, pos.y);
        if (b < a) std::swap(b, a);
        if (c < b) std::swap(c, b);
        if (b < a) std::swap(b, a);
        gestureKind = a.kind;
        gestureStart = pos.y;
        gestureLevel = a.level;
    }
    else {
        Float32 newLevel = gestureLevel + (pos.y - gestureStart);
        NSString* key = nil;

	if (newLevel > 1.0) newLevel = 1.0;
	if (newLevel < -1.0) newLevel = -1.0;
        if (gestureKind == kAdjustLowLevel) {
            detector.lowLevel = newLevel;
            key = kSettingsPulseFrequencyDetectorLowLevelKey;
        }
        else if (gestureKind == kAdjustHighLevel) {
            detector.highLevel = newLevel;
            key = kSettingsPulseFrequencyDetectorHighLevelKey;
        }
        else {
            detector.minHighPulseAmplitude = newLevel;
            key = kSettingsPulseFrequencyDetectorMinHighAmplitudeKey;
        }

        if (recognizer.state == UIGestureRecognizerStateEnded) {
            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithFloat:newLevel] forKey:key];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
}

- (BOOL)showInfoOverlay
{
    return YES;
}

- (void)updateInfoOverlay:(NSTimer*)timer
{
    NSString* content = [NSString stringWithFormat:
                         @"Low Level: %f\nHigh Level: %f\nMin Amplitude: %f\nMax Pulse-Pulse Width: %d\nSmoother Values: %@",
                         detector.lowLevel,
                         detector.highLevel,
                         detector.minHighPulseAmplitude,
                         detector.maxPulseToPulseWidth,
                         detector.smootherValues
                         ];
    infoOverlay.text = content;
}

@end
