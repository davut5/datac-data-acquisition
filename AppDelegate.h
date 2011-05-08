// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <UIKit/UIKit.h>

#import "CorePlot-CocoaTouch.h"
#import "DBSession.h"
#import "DBLoginController.h"
#import "IASKAppSettingsViewController.h"
#import "SampleProcessorProtocol.h"

@class DataCapture;
@class DropboxUploader;
@class BitDetector;
@class RecordingInfo;
@class RecordingsViewController;
@class RpmViewController;
@class SettingsViewController;
@class LevelDetector;
@class SignalViewController;
@class MicSwitchDetector;
@class VertexBufferManager;
@class WaveCycleDetector;

/** Application delegate that manages the various view controllers of the application, and the application-wide
 services such as data capture and signal detection.
 */
@interface AppDelegate : NSObject <UIApplicationDelegate, IASKSettingsDelegate, UITabBarControllerDelegate, 
                                   DBSessionDelegate, DBLoginControllerDelegate, 
                                   UIActionSheetDelegate> {
@private
    IBOutlet UIWindow *window;
    IBOutlet UITabBarController* tabBarController;
    IBOutlet SignalViewController* signalViewController;
    IBOutlet RpmViewController* rpmViewController;
    IBOutlet RecordingsViewController* recordingsViewController;
    IBOutlet SettingsViewController* settingsController;

    DBSession* dropboxSession;
    DataCapture* dataCapture;
    NSObject<SampleProcessorProtocol>* signalDetector;
    MicSwitchDetector* switchDetector;
    VertexBufferManager* vertexBufferManager;
    DropboxUploader* uploader;
    NSTimer* uploadChecker;
                                       
    // CoreData stuff
    NSManagedObjectModel* managedObjectModel;
    NSManagedObjectContext* managedObjectContext;
    NSPersistentStoreCoordinator* persistentStoreCoordinator;
    NSFetchedResultsController* fetchedResultsController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UITabBarController* tabBarController;
@property (nonatomic, retain) IBOutlet SignalViewController* signalViewController;
@property (nonatomic, retain) IBOutlet RpmViewController* rpmViewController;
@property (nonatomic, retain) IBOutlet RecordingsViewController* recordingsViewController;
@property (nonatomic, retain) IBOutlet SettingsViewController* appSettingsViewController;
@property (nonatomic, retain) DBSession* dropboxSession;
@property (nonatomic, retain) DataCapture* dataCapture;
@property (nonatomic, retain) NSObject<SampleProcessorProtocol>* signalDetector;
@property (nonatomic, retain) MicSwitchDetector* switchDetector;
@property (nonatomic, retain) VertexBufferManager* vertexBufferManager;
@property (nonatomic, retain) DropboxUploader* uploader;
@property (nonatomic, retain) NSTimer* uploadChecker;

@property (nonatomic, retain, readonly) NSManagedObjectModel* managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext* managedObjectContext;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator* persistentStoreCoordinator;
@property (nonatomic, retain, readonly) NSFetchedResultsController* fetchedResultsController;
@property (nonatomic, readonly) NSString* applicationDocumentsDirectory;

/** Start the data capturing and signal processing components.
 */
- (void)start;

/** Stop any active recording and the data capturing and signal processing
    components.
*/
- (void)stop;

/** Setup the Dropbox SDK components in order to support automatic uploads of
    recorded data.
*/
- (void)setupDropbox;

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
- (void)removeRecordingAt:(NSIndexPath*)indexPath;

@end
