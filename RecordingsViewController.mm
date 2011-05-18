// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "AppDelegate.h"
#import "DropboxUploader.h"
#import "RecordingInfo.h"
#import "RecordingsViewController.h"
#import "UserSettings.h"

@interface RecordingsViewController ()

- (void)configureCell:(UITableViewCell*)cell withRecordingInfo:(RecordingInfo*)recordingInfo;
- (void)uploaderCheck:(NSNotification*)notification;
- (void)updateDropboxUploader;
- (RecordingInfo*)nextToUpload;

@end

@implementation RecordingsViewController

#pragma mark -
#pragma mark View lifecycle

- (id)initWithCoder:(NSCoder*)decoder
{
    NSLog(@"RecordingsViewController.initWithCoder");
    if (self = [super initWithCoder:decoder]) {
        appDelegate = nil;
        managedObjectModel = nil;
        managedObjectContext = nil;
        persistentStoreCoordinator = nil;
        fetchedResultsController = nil;
        activeRecording = nil;
        uploadChecker = [[NSTimer scheduledTimerWithTimeInterval:5.0 
                                                          target:self
                                                        selector:@selector(uploaderCheck:)
                                                        userInfo:nil 
                                                         repeats:YES] retain];
    }

    return self;
}

#pragma mark -
#pragma mark Memory management

- (void)dealloc
{
    [uploadChecker invalidate];
    [uploadChecker release];
    [super dealloc];
}

- (void)viewDidLoad {
    NSLog(@"RecordingsViewController.viewDidLoad");
    appDelegate = static_cast<AppDelegate*>([[UIApplication sharedApplication] delegate]);

    self.title = NSLocalizedString(@"Recordings", @"Recordings view title");
    self.tableView.allowsSelection = NO;
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    NSLog(@"RecordingsViewController.viewDidUnload");
    appDelegate = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    if ([self.tableView numberOfRowsInSection:0] > 0) {
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
    }
    else {
	self.navigationItem.rightBarButtonItem = nil;
    }

    [super viewWillAppear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)updateFromSettings
{
    [self updateDropboxUploader];
}

- (void)updateDropboxUploader
{
    //
    // Only carry around a DropboxUploader if configured to use Dropbox.
    //
    DBSession* dropboxSession = [DBSession sharedSession];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kSettingsCloudStorageEnableKey] == YES &&
	[dropboxSession isLinked] == YES) {
	if (uploader == nil) {
	    uploader = [[DropboxUploader createWithSession:dropboxSession] retain];
	}
    }
    else {
	if (uploader != nil) {
            [uploader release];
	    uploader = nil;
	}
    }
}

- (void)uploaderCheck:(NSNotification*)notification
{
    [self updateDropboxUploader];
    if (uploader != nil && uploader.uploadingFile == nil) {
        RecordingInfo* recordingInfo = [self nextToUpload];
        if (recordingInfo != nil) {
            uploader.uploadingFile = recordingInfo;
        }
    }
}

- (void)controllerWillChangeContent:(NSFetchedResultsController*)controller
{
    if (appDelegate != nil) {
        [self.tableView beginUpdates];
    }
}

- (void)controller:(NSFetchedResultsController*)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath*)indexPath 
     forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath*)newIndexPath 
{
    if (appDelegate == nil) return;

    UITableView* tableView = self.tableView;
    switch(type) {
    case NSFetchedResultsChangeInsert:
	[tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
			 withRowAnimation:UITableViewRowAnimationNone];
	[self configureCell:[tableView cellForRowAtIndexPath:newIndexPath] withRecordingInfo:anObject];
	break;

    case NSFetchedResultsChangeDelete:
	[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] 
			 withRowAnimation:UITableViewRowAnimationFade];
	break;

    case NSFetchedResultsChangeUpdate:
	if (self.tableView.editing == NO) {
	    [self configureCell:[tableView cellForRowAtIndexPath:indexPath] withRecordingInfo:anObject];
	}
	break;
    }
}

- (void)controller:(NSFetchedResultsController*)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
	   atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type 
{
    if (appDelegate == nil) return;

    switch(type) {
    case NSFetchedResultsChangeInsert:
	[self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
		      withRowAnimation:UITableViewRowAnimationNone];
	break;
    case NSFetchedResultsChangeDelete:
	[self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] 
		      withRowAnimation:UITableViewRowAnimationFade];
	break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController*)controller
{
    if (appDelegate != nil) {
        [self.tableView endUpdates];
    }
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    static NSString* kCellIdentifier = @"RecordingInfoCell";
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
				       reuseIdentifier:kCellIdentifier] autorelease];
    }

    RecordingInfo* recording = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [self configureCell:cell withRecordingInfo:recording];

    return cell;
}

- (void)configureCell:(UITableViewCell*)cell withRecordingInfo:(RecordingInfo*)recording
{
    cell.textLabel.text = recording.name;
    NSString* status;

    if (recording.uploaded == YES) {
	status = NSLocalizedString(@"uploaded", @"Status tag for uploaded files");
    }
    else if (recording.uploading == YES) {
	status = NSLocalizedString(@"uploading", @"Status tag for uploading files");
    }
    else if (recording == activeRecording) {
	status = NSLocalizedString(@"recording", @"Status tag for active recording file");
    }
    else {
	status = NSLocalizedString(@"not uploaded", @"Status tag for files not uploaded");
    }

    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@", recording.size, status];

    //
    // If this RecordingInfo object is being uploaded, show an activity indicator.
    //
    if (recording.uploaded == NO && recording.uploading == YES) {
	UIProgressView* accessoryView = (UIProgressView*)[cell accessoryView];
	if (accessoryView == nil) {
	    accessoryView = [[[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault] autorelease];
	    CGRect bounds = accessoryView.bounds;
	    bounds.size.width = 100;
	    accessoryView.bounds = bounds;
	    [cell setAccessoryView:accessoryView];
	}
	[accessoryView setProgress:recording.progress];
    }
    else {
	[cell setAccessoryView:nil];
    }
}

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle 
forRowAtIndexPath:(NSIndexPath *)indexPath 
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        RecordingInfo* recordingInfo = [fetchedResultsController objectAtIndexPath:indexPath];
        NSLog(@"deleting file '%@'", recordingInfo.filePath);

        [appDelegate recordingDeleted:recordingInfo];
        
        if (uploader != nil && uploader.uploadingFile == recordingInfo)
            [uploader cancelUploads];

        NSError* error;
        if ([[NSFileManager defaultManager] removeItemAtPath:recordingInfo.filePath error:&error] == NO) {
            NSLog(@"failed to remove file at '%@' - %@, %@", recordingInfo.filePath, error, [error userInfo]);
        }
            
        [managedObjectContext deleteObject:recordingInfo];
        if (![managedObjectContext save:&error]) {
            // Update to handle the error appropriately.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        }

	if ([tableView numberOfRowsInSection:0] == 0) {
	    [self setEditing:NO animated:YES];
	    self.navigationItem.rightBarButtonItem = nil;
	}
    }   
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
    NSLog(@"RecordingsViewController.didSelectRow: %d", [indexPath indexAtPosition:1]);
}

#pragma mark -
#pragma mark CoreData

- (NSManagedObjectModel*)managedObjectModel
{
    if (managedObjectModel != nil) return managedObjectModel;
    managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];
    return managedObjectModel;
}

- (NSPersistentStoreCoordinator*)persistentStoreCoordinator
{
    if (persistentStoreCoordinator != nil) return persistentStoreCoordinator;

    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;

    NSString* storePath = [basePath stringByAppendingPathComponent: @"Recordings.sqlite"];
    NSURL* storeUrl = [NSURL fileURLWithPath:storePath];
    NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
                             nil];
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] 
                                  initWithManagedObjectModel:self.managedObjectModel];
    NSError* error;
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType 
						  configuration:nil 
							    URL:storeUrl 
							options:options 
							  error:&error]) {
        // Update to handle the error appropriately.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        exit(-1);  // Fail
    }    
    
    return persistentStoreCoordinator;
}

- (NSManagedObjectContext*)managedObjectContext
{
    if (managedObjectContext != nil) return managedObjectContext;

    NSPersistentStoreCoordinator* coordinator = self.persistentStoreCoordinator;
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    
    return managedObjectContext;
}

- (NSFetchedResultsController*)fetchedResultsController
{
    if (fetchedResultsController != nil) return fetchedResultsController;
    
    NSFetchRequest*fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"RecordingInfo" 
					      inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSSortDescriptor* nameDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:nameDescriptor]];
    
    fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest 
								   managedObjectContext:self.managedObjectContext
								     sectionNameKeyPath:nil 
									      cacheName:@"RecordingInfo"];
    fetchedResultsController.delegate = self;

    NSError* error;
    if (![self.fetchedResultsController performFetch:&error]) {
	NSLog(@"unresolved error %@, %@", error, [error userInfo]);
    }

    return fetchedResultsController;
}

- (RecordingInfo*)makeRecording
{
    RecordingInfo* recording = [NSEntityDescription insertNewObjectForEntityForName:@"RecordingInfo"
							     inManagedObjectContext:self.managedObjectContext];
    [recording initialize];
    activeRecording = recording;
    return recording;
}

- (void)saveContext
{
    NSError* error;
    if (managedObjectContext != nil && [managedObjectContext hasChanges] && [managedObjectContext save:&error] != YES) {
	NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    activeRecording = nil;
}

- (RecordingInfo*)nextToUpload
{
    NSArray* recordings = [self.fetchedResultsController fetchedObjects];
    UInt32 count = [recordings count];
    for (int index = 0; index < count; ++index) {
        RecordingInfo* recording = [recordings objectAtIndex:index];
        if (recording.uploaded == NO && recording != activeRecording) {
            NSLog(@"nextToUpload: %@", recording.name);
            return recording;
        }
    }

    return nil;
}

@end

