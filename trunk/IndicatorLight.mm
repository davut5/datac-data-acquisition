// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "IndicatorLight.h"

@implementation IndicatorLight

@synthesize state, blinker, blinkingInterval, onState, blankedState;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        onState = kGreen;
        blankedState = kOff;
        blinker = nil;
        blanked = NO;
        blinkingInterval = 0.0;
        // self.userInteractionEnabled = YES;
        [self setState:kOff];
    }
    return self;
}

- (id)initWithCoder:(NSCoder*)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        onState = kGreen;
        blankedState = kOff;
        blinker = nil;
        blanked = NO;
        blinkingInterval = 0.0;
        // self.userInteractionEnabled = YES;
        [self setState:kOff];
    }
    return self;
}

- (BOOL)illuminated
{
    return state != kOff;
}

- (void)blink:(NSTimer*)timer
{
    blanked = ! blanked;
    [self setState:state];
}

- (void)setIlluminated:(BOOL)value
{
    if (state != value) {
        blanked = NO;
        self.state = (value == YES) ? onState : kOff;
        if (state == kOff) {
            [self.blinker invalidate];
            self.blinker = nil;
        }
        else if (blinkingInterval > 0.0) {
            self.blinker = [NSTimer scheduledTimerWithTimeInterval:blinkingInterval
                                                            target:self
                                                          selector:@selector(blink:)
                                                          userInfo:nil
                                                           repeats:YES];
        }
    }
}

- (void)setState:(IndicatorState)value
{
    state = value;
    if (blanked == YES) value = blankedState;
    switch (value) {
        case kGreen:
            [self setImage:[UIImage imageNamed:@"GreenButton.png"]];
            break;
        case kDimGreen:
            [self setImage:[UIImage imageNamed:@"DimGreenButton.png"]];
            break;
        case kYellow:
        case kDimYellow:
            [self setImage:[UIImage imageNamed:@"YellowButton.png"]];
            break;
        case kRed:
            [self setImage:[UIImage imageNamed:@"RedButton.png"]];
            break;
        case kDimRed:
            [self setImage:[UIImage imageNamed:@"DimRedButton.png"]];
            break;
        default:
            [self setImage:[UIImage imageNamed:@"OffButton.png"]];
            break;
    }
}

@end
