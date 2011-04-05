// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IndicatorLight.h"

/** A UIControl that contains an on/off indicator and a text label.
    The on property controls the state of the indicator.
*/
@interface IndicatorButton : UIControl {
@private
    IBOutlet IndicatorLight* light;
    IBOutlet UILabel* label;
}

@property (retain) IBOutlet IndicatorLight* light;
@property (retain) IBOutlet UILabel* label;
@property (nonatomic, assign) BOOL on;
@property (nonatomic, assign) NSTimeInterval blinkingInterval;

@end
