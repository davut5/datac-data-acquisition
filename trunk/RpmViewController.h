// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CorePlot-CocoaTouch.h"

@class AppDelegate;

@interface RpmViewController : UIViewController<CPPlotDataSource> {
@private
    NSMutableArray* points;
    UInt32 newest;
    Float32 xScale;
    CPXYGraph* graph;
}

@property (nonatomic, retain) NSMutableArray* points;
@property (nonatomic, retain) CPXYGraph* graph;

- (void)updateFromSettings;

@end
