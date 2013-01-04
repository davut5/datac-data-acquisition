// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//
#import <memory>

#import "HiLowSignalProcessor.h"
#import "HiLowSignalProcessorController.h"
#import "UserSettings.h"

@interface HiLowSignalProcessorController (Private)

+ (NSString**)levelNames;
+ (NSString**)keyNames;

@end

@implementation HiLowSignalProcessorController

enum GestureKind {
    kAdjustMaxLowLevel,
    kAdjustMinHighLevel,
    kAdjustUnknown,
};

+ (NSString**)levelNames
{
    static NSString* levelNames[] = {
        [NSLocalizedString(@"Low Level", "Name of low level") retain],
        [NSLocalizedString(@"High Level", "Name of high level") retain],
        nil
    };
    
    return levelNames;
}

+ (NSString**)keyNames
{
    static NSString* keyNames[] = {
        kSettingsBitDetectorMaxLowLevelKey,
        kSettingsBitDetectorMinHighLevelKey,
        nil
    };
    
    return keyNames;
}

+ (id)createWithDetector:(HiLowSignalProcessor*)detector
{
    return [[[HiLowSignalProcessorController alloc] initWithDetector:detector] autorelease];
}

- (id)initWithDetector:(HiLowSignalProcessor*)theDetector
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
    vertices[1] = detector.maxLowLevel;
    vertices[3] = detector.maxLowLevel;
    glLineWidth(2.0);
    glColor4f(1., 1., 0., 1.0);
    glDrawArrays(GL_LINES, 0, 2);
    vertices[1] = detector.minHighLevel;
    vertices[3] = detector.minHighLevel;
    glColor4f(1., 0., 1., 1.0);
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
    HitInfo a(kAdjustMaxLowLevel, detector.maxLowLevel, value);
    HitInfo b(kAdjustMinHighLevel, detector.minHighLevel, value);
    if (b < a) std::swap(b, a);
    return a.delta;
}

- (void)handlePanGesture:(UIPanGestureRecognizer*)recognizer viewPoint:(CGPoint)pos
{
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithFloat:gestureLevel]
                                                  forKey:[HiLowSignalProcessorController keyNames][gestureKind]];
        [[NSUserDefaults standardUserDefaults] synchronize];
        gestureKind = kAdjustUnknown;
    }
    else {
        if (recognizer.state == UIGestureRecognizerStateBegan) {
            HitInfo a(kAdjustMaxLowLevel, detector.maxLowLevel, pos.y);
            HitInfo b(kAdjustMinHighLevel, detector.minHighLevel, pos.y);
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
            if (gestureKind == kAdjustMaxLowLevel) {
                detector.maxLowLevel = gestureLevel;
            }
            else {
                detector.minHighLevel = gestureLevel;
            }
        }
        
        [self showLevelOverlay:[HiLowSignalProcessorController levelNames][gestureKind] withValue:gestureLevel];
    }
}

@end
