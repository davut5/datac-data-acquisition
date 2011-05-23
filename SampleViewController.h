// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "SampleView.h"
#import "MicSwitchDetector.h"

@class AppDelegate;
@class IndicatorButton;
@class InfoOverlayViewController;
@class SignalProcessorController;
@class VertexBufferManager;

/** Controller for the view that contains engineering data for the data capture interface.
 */
@interface SampleViewController : UIViewController <SampleViewDelegate, MicSwitchDetectorDelegate> {
@private
    AppDelegate* appDelegate;
    IBOutlet SampleView* sampleView;
    IBOutlet IndicatorButton* powerIndicator;
    IBOutlet IndicatorButton* connectedIndicator;
    IBOutlet IndicatorButton* recordIndicator;
    IBOutlet UILabel* xMinLabel;
    IBOutlet UILabel* xMaxLabel;
    IBOutlet UILabel* yMaxLabel;
    IBOutlet UILabel* yPos05Label;
    IBOutlet UILabel* yZeroLabel;
    IBOutlet UILabel* yNeg05Label;
    IBOutlet UITextView* infoOverlay;
    VertexBufferManager* vertexBufferManager;
    SignalProcessorController* signalProcessorController;
    
    GLfloat xMin;
    GLfloat xSpan;
    GLfloat yMin;
    GLfloat ySpan;
    GLfloat scale;

    CGFloat gestureStart;
    CGPoint gesturePoint;
    int gestureType;
}

@property (nonatomic, retain) IBOutlet SampleView* sampleView;
@property (nonatomic, retain) IBOutlet IndicatorButton* powerIndicator;
@property (nonatomic, retain) IBOutlet IndicatorButton* connectedIndicator;
@property (nonatomic, retain) IBOutlet IndicatorButton* recordIndicator;
@property (nonatomic, retain) IBOutlet UILabel* xMinLabel;
@property (nonatomic, retain) IBOutlet UILabel* xMaxLabel;
@property (nonatomic, retain) IBOutlet UILabel* yMaxLabel;
@property (nonatomic, retain) IBOutlet UILabel* yPos05Label;
@property (nonatomic, retain) IBOutlet UILabel* yZeroLabel;
@property (nonatomic, retain) IBOutlet UILabel* yNeg05Label;
@property (nonatomic, retain) IBOutlet UIView* infoOverlay;
@property (nonatomic, retain) SignalProcessorController* signalProcessorController;
@property (nonatomic, assign) GLfloat xMin;
@property (nonatomic, assign) GLfloat yMin;
@property (nonatomic, assign) GLfloat scale;

- (IBAction)togglePower;
- (IBAction)toggleRecord;

- (void)start;
- (void)stop;
- (void)updateFromSettings;
- (void)toggleInfoOverlay;

@end

