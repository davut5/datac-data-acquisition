// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "IndicatorButton.h"
#import "IndicatorLight.h"

@implementation IndicatorButton

@synthesize light, label;

- (void)setOn:(BOOL)value
{
    self.light.illuminated = value;
}

- (BOOL)on
{
    return self.light.illuminated;
}

- (void)dealloc {
    [light release];
    [label release];
    [super dealloc];
}

- (NSTimeInterval)blinkingInterval
{
    return light.blinkingInterval;
}

- (void)setBlinkingInterval:(NSTimeInterval)interval
{
    light.blinkingInterval = interval;
}

@end
