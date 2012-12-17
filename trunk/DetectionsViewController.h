// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CorePlot-CocoaTouch.h"
#import "SignalProcessorProtocol.h"

@class AppDelegate;

@interface DetectionsViewController : UIViewController<CPTPlotDataSource> {
@private
    NSTimer* updateTimer;
    NSMutableArray* points;
    UInt32 newest;
    Float32 xScale;
    CPTXYGraph* graph;
    NSObject<SignalProcessorProtocol>* detector;
}

@property (nonatomic, retain) NSMutableArray* points;
@property (nonatomic, retain) CPTXYGraph* graph;
@property (nonatomic, retain) NSObject<SignalProcessorProtocol>* detector;

- (void)updateFromSettings;

@end
