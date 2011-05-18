// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <UIKit/UIKit.h>

@class AppDelegate;
@class DropboxUploader;
@class RecordingInfo;

@interface RecordingsViewController : UITableViewController <NSFetchedResultsControllerDelegate> {
@private
    AppDelegate* appDelegate;
    NSManagedObjectModel* managedObjectModel;
    NSManagedObjectContext* managedObjectContext;
    NSPersistentStoreCoordinator* persistentStoreCoordinator;
    NSFetchedResultsController* fetchedResultsController;
    DropboxUploader* uploader;
    NSTimer* uploadChecker;
    RecordingInfo* activeRecording;
}

@property (nonatomic, retain, readonly) NSManagedObjectModel* managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext* managedObjectContext;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator* persistentStoreCoordinator;
@property (nonatomic, retain, readonly) NSFetchedResultsController* fetchedResultsController;

- (void)updateFromSettings;

- (RecordingInfo*)makeRecording;

- (void)saveContext;

@end
