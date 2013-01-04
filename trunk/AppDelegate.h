// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DropboxSDK/DropboxSDK.h>

#import "IASKAppSettingsViewController.h"
#import "SampleProcessorProtocol.h"
#import "SignalProcessorProtocol.h"

@class DataCapture;
@class BitDetector;
@class DetectionsViewController;
@class PeakDetector;
@class MicSwitchDetector;
@class RecordingInfo;
@class RecordingsViewController;
@class SampleViewController;
@class SettingsViewController;
@class VertexBufferManager;
@class WaveCycleDetector;

/** Application delegate that manages the various view controllers of the application, and the application-wide
 services such as data capture and signal detection.
 */
@interface AppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate, DBSessionDelegate> {
@private
    IBOutlet UIWindow *window;
    IBOutlet UITabBarController* tabBarController;
    IBOutlet SampleViewController* sampleViewController;
    IBOutlet DetectionsViewController* detectionsViewController;
    IBOutlet RecordingsViewController* recordingsViewController;
    IBOutlet SettingsViewController* settingsViewController;
    DBSession* dropboxSession;
    DataCapture* dataCapture;
    NSObject<SignalProcessorProtocol>* signalDetector;
    MicSwitchDetector* switchDetector;
    VertexBufferManager* vertexBufferManager;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UITabBarController* tabBarController;
@property (nonatomic, retain) IBOutlet SampleViewController* sampleViewController;
@property (nonatomic, retain) IBOutlet DetectionsViewController* detectionsViewController;
@property (nonatomic, retain) IBOutlet RecordingsViewController* recordingsViewController;
@property (nonatomic, retain) IBOutlet SettingsViewController* settingsViewController;
@property (nonatomic, retain) DBSession* dropboxSession;
@property (nonatomic, retain) DataCapture* dataCapture;
@property (nonatomic, retain) NSObject<SignalProcessorProtocol>* signalDetector;
@property (nonatomic, retain) MicSwitchDetector* switchDetector;
@property (nonatomic, retain) VertexBufferManager* vertexBufferManager;

// @property (nonatomic, readonly) NSString* applicationDocumentsDirectory;

/** Start the data capturing and signal processing components.
 */
- (void)start;

/** Stop any active recording and the data capturing and signal processing
 components.
 */
- (void)stop;

/** Start recording of incoming sample data.
 */
- (void)startRecording;

/** Stop recording of incoming sample data.
 */
- (void)stopRecording;

/** Determine if the application is currently recording.
 */
- (BOOL)isRecording;

/** Determine if the application is currently recording into a file referenced in the given RecordingInfo instance.
 */
- (BOOL)isRecordingInto:(RecordingInfo*)recording;

/** Remove the indicated recording file and meta data.
 \param indexPath the location of the recording data in our managed object
 model.
 */
- (void)recordingDeleted:(RecordingInfo*)recording;

- (void)updateFromSettings;

@end
