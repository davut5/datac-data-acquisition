// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "PulseWidthDetector.h"
#import "PulseWidthDetectorController.h"
#import "UserSettings.h"

@implementation PulseWidthDetectorController

enum GestureKind {
    kAdjustLowLevel,
    kAdjustHighLevel,
    kAdjustMinAmplitude,
    kAdjustUnknown,
};

+ (NSString**)levelNames
{
    static NSString* levelNames[] = {
        [NSLocalizedString(@"Low", "Name of low level") retain],
        [NSLocalizedString(@"High", "Name of high level") retain],
        [NSLocalizedString(@"Amp", "Name of amplitude level") retain],
        nil
    };
    
    return levelNames;
}

+ (NSString**)keyNames
{
    static NSString* keyNames[] = {
        kSettingsPulseWidthDetectorLowLevelKey,
        kSettingsPulseWidthDetectorHighLevelKey,
        kSettingsPulseWidthDetectorMinHighAmplitudeKey,
        nil
    };
    
    return keyNames;
}

+ (id)createWithDetector:(PulseWidthDetector*)theDetector
{
    return [[[PulseWidthDetectorController alloc] initWithDetector:theDetector] autorelease];
}

- (id)initWithDetector:(PulseWidthDetector*)theDetector
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

- (Float32)distanceFromLevel:(Float32)value
{
    HitInfo a(kAdjustLowLevel, detector.lowLevel, value);
    HitInfo b(kAdjustHighLevel, detector.highLevel, value);
    HitInfo c(kAdjustMinAmplitude, detector.minHighPulseAmplitude, value);
    if (b < a) std::swap(b, a);
    if (c < b) std::swap(c, b);
    if (b < a) std::swap(b, a);
    return a.delta;
}

- (void)handlePanGesture:(UIPanGestureRecognizer*)recognizer viewPoint:(CGPoint)pos
{
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
        [settings setObject:[NSNumber numberWithFloat:gestureLevel]
                     forKey:[PulseWidthDetectorController keyNames][gestureKind]];
        [[NSUserDefaults standardUserDefaults] synchronize];
        gestureKind = kAdjustUnknown;
    }
    else {
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
            gestureLevel += (pos.y - gestureStart);
            gestureStart = pos.y;
            if (gestureLevel > 1.0) gestureLevel = 1.0;
            if (gestureLevel < -1.0) gestureLevel = -1.0;
            if (gestureKind == kAdjustLowLevel) {
                detector.lowLevel = gestureLevel;
            }
            else if (gestureKind == kAdjustHighLevel) {
                detector.highLevel = gestureLevel;
            }
            else {
                detector.minHighPulseAmplitude = gestureLevel;
            }
        }
        [self showLevelOverlay:[PulseWidthDetectorController levelNames][gestureKind] withValue:gestureLevel];
    }
}

- (BOOL)showInfoOverlay
{
    return YES;
}

- (void)updateInfoOverlay:(NSTimer*)timer
{
    NSString* content = [NSString stringWithFormat:
                         @"Pulse Width Detector\n"
                         "Low Level: %f\n"
                         "High Level: %f\n"
                         "Min Amplitude: %f\n"
                         "Max Pulse-Pulse Width: %d\n"
                         "Smoother Values: %@",
                         detector.lowLevel,
                         detector.highLevel,
                         detector.minHighPulseAmplitude,
                         detector.maxPulseToPulseWidth,
                         detector.smootherValues
                         ];
    self.infoOverlay.text = content;
}

@end
