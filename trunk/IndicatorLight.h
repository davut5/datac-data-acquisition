// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <UIKit/UIKit.h>

enum IndicatorState {
    kOff,
    kGreen,
    kDimGreen,
    kYellow,
    kDimYellow,
    kRed,
    kDimRed
};

/** A simple on/off indicator light.
    The illuminated property controls whether the light is on or off.
*/
@interface IndicatorLight : UIImageView {
@private
    IndicatorState state;
    IndicatorState onState;
    IndicatorState blankedState;
    NSTimer* blinker;
    NSTimeInterval blinkingInterval;
    BOOL blanked;
}

@property (nonatomic, assign) IndicatorState state;
@property (nonatomic, assign) BOOL illuminated;
@property (nonatomic, retain) NSTimer* blinker;
@property (nonatomic, assign) IndicatorState onState;
@property (nonatomic, assign) IndicatorState blankedState;
@property (nonatomic, assign) NSTimeInterval blinkingInterval;

@end
