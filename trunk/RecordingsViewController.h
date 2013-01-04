// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <UIKit/UIKit.h>

#import "DropboxUploader.h"

@class AppDelegate;
@class RecordingInfo;

@interface RecordingsViewController : UITableViewController <NSFetchedResultsControllerDelegate, DropboxUploaderMonitor> {
@private
    AppDelegate* appDelegate;
    IBOutlet UITabBarItem* tabItem;
    NSManagedObjectModel* managedObjectModel;
    NSManagedObjectContext* managedObjectContext;
    NSPersistentStoreCoordinator* persistentStoreCoordinator;
    NSFetchedResultsController* fetchedResultsController;
    DropboxUploader* uploader;
    RecordingInfo* activeRecording;
}

@property (nonatomic, retain, readonly) NSManagedObjectModel* managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext* managedObjectContext;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator* persistentStoreCoordinator;
@property (nonatomic, retain, readonly) NSFetchedResultsController* fetchedResultsController;

- (void)updateFromSettings;

- (RecordingInfo*)startRecording;

- (void)stopRecording;

- (void)saveContext;

@end
