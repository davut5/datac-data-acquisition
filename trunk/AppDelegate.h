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

@class DataCapture;
@class DropboxUploader;
@class RecordingInfo;
@class RecordingsViewController;
@class RpmViewController;
@class SettingsViewController;
@class SignalDetector;
@class SignalViewController;
@class SwitchDetector;
@class VertexBufferManager;

/** Application delegate that manages the various controllers of the
 * application.
 */
@interface AppDelegate : NSObject <UIApplicationDelegate, IASKSettingsDelegate, UITabBarControllerDelegate, CPPlotDataSource, DBSessionDelegate, DBLoginControllerDelegate, UIActionSheetDelegate> {
@private
    IBOutlet UIWindow *window;
    IBOutlet UITabBarController* tabBarController;
    IBOutlet SignalViewController* signalViewController;
    IBOutlet RpmViewController* rpmViewController;
    IBOutlet RecordingsViewController* recordingsViewController;
    IBOutlet SettingsViewController* settingsController;

    DBSession* dropboxSession;
    DataCapture* dataCapture;
    SignalDetector* signalDetector;
    SwitchDetector* switchDetector;
    VertexBufferManager* vertexBufferManager;
    NSMutableArray* points;
    UInt32 newest;
    Float32 xScale;
    DropboxUploader* uploader;

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
@property (nonatomic, retain) SignalDetector* signalDetector;
@property (nonatomic, retain) SwitchDetector* switchDetector;
@property (nonatomic, retain) VertexBufferManager* vertexBufferManager;
@property (nonatomic, retain) NSMutableArray* points;
@property (nonatomic, assign) UInt32 newest;
@property (nonatomic, retain) DropboxUploader* uploader;
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

/** Determine if application is currently recording.
 */
- (BOOL)isRecording;

- (BOOL)isRecordingInto:(RecordingInfo*)recording;

/** Remove the indicated recording file and meta data.
    \param indexPath the location of the recording data in our managed object
    model.
*/
- (void)removeRecordingAt:(NSIndexPath*)indexPath;

@end
