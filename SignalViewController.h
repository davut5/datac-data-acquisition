// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#import "SampleView.h"
#import "MicSwitchDetector.h"

@class AppDelegate;
@class DetectorController;
@class IndicatorButton;
@class LevelDetector;
@class VertexBufferManager;

/** Controller for the view that contains engineering data for the data capture interface.
 */
@interface SignalViewController : UIViewController <SampleViewDelegate, MicSwitchDetectorDelegate> {
@private
    IBOutlet AppDelegate* appDelegate;
    IBOutlet SampleView* sampleView;
    IBOutlet IndicatorButton* powerIndicator;
    IBOutlet IndicatorButton* connectedIndicator;
    IBOutlet IndicatorButton* recordIndicator;
    IBOutlet UILabel* xMinLabel;
    IBOutlet UILabel* xMaxLabel;
    IBOutlet UILabel* yPos05Label;
    IBOutlet UILabel* yZeroLabel;
    IBOutlet UILabel* yNeg05Label;
    VertexBufferManager* vertexBufferManager;
    DetectorController* detectorController;
    GLfloat xMin;
    GLfloat xMax;
    CGFloat gestureStart;
    int gestureType;
}

@property (nonatomic, retain) IBOutlet AppDelegate* appDelegate;
@property (nonatomic, retain) IBOutlet SampleView* sampleView;
@property (nonatomic, retain) IBOutlet IndicatorButton* powerIndicator;
@property (nonatomic, retain) IBOutlet IndicatorButton* connectedIndicator;
@property (nonatomic, retain) IBOutlet IndicatorButton* recordIndicator;
@property (nonatomic, retain) IBOutlet UILabel* xMinLabel;
@property (nonatomic, retain) IBOutlet UILabel* xMaxLabel;
@property (nonatomic, retain) IBOutlet UILabel* yPos05Label;
@property (nonatomic, retain) IBOutlet UILabel* yZeroLabel;
@property (nonatomic, retain) IBOutlet UILabel* yNeg05Label;
@property (nonatomic, retain) DetectorController* detectorController;

- (IBAction)togglePower;
- (IBAction)toggleRecord;

- (void)setXMax:(CGFloat)value;
- (void)start;
- (void)stop;
- (void)updateFromSettings;

@end

