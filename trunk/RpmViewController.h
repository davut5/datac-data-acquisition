// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CorePlot-CocoaTouch.h"

@class AppDelegate;

@interface RpmViewController : UIViewController {
@private
    IBOutlet AppDelegate* appDelegate;
    CPXYGraph* graph;
    BOOL visible;
}

@property (nonatomic, retain) IBOutlet AppDelegate* appDelegate;
@property (nonatomic, retain) CPXYGraph* graph;
@property (nonatomic, assign) BOOL visible;

- (void)update;
- (void)updateFromSettings;

@end
