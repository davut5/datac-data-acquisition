// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "AppDelegate.h"
#import "DropboxSDK.h"
#import "Dropbox.keys"
#import "DropboxUploader.h"
#import "IASKSpecifier.h"
#import "IndicatorButton.h"
#import "RecordingInfo.h"
#import "RecordingsViewController.h"
#import "RpmViewController.h"
#import "SampleRecorder.h"
#import "SignalDetector.h"
#import "SignalViewController.h"
#import "SettingsViewController.h"
#import "UserSettings.h"
#import "VertexBufferManager.h"

@interface AppDelegate ()

- (void)updateDropboxUploader;
- (void)updateSignalStats:(NSNotification*)notification;
- (void)updateDropboxCell:(UITableViewCell*)cell;
- (void)sessionDidReceiveAuthorizationFailure:(DBSession*)session;

@end

@implementation AppDelegate

@synthesize window, tabBarController, signalViewController, appSettingsViewController, recordingsViewController;
@synthesize rpmViewController, dropboxSession, fetchedResultsController;
@synthesize dataCapture, signalDetector, switchDetector, vertexBufferManager, points, newest, uploader;

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSLog(@"AppDelegate.application:didFinishLaunchingWithOptions:");

    NSUserDefaults* settings = [UserSettings registerDefaults];
    NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];

    managedObjectModel = nil;
    managedObjectContext = nil;
    persistentStoreCoordinator = nil;

    //
    // Dropbox SDK initialization
    //
    NSString* consumerKey = DROPBOX_KEY;
    NSString* consumerSecret = DROPBOX_SECRET;
    dropboxSession = [[[DBSession alloc] initWithConsumerKey:consumerKey consumerSecret:consumerSecret] autorelease];
    [DBSession setSharedSession:dropboxSession];
    dropboxSession.delegate = self;

    [application setStatusBarStyle:UIStatusBarStyleBlackTranslucent];

    xScale = [settings floatForKey:kSettingsSignalDetectorUpdateRateKey];
    Float32 duration = [settings floatForKey:kSettingsRpmViewDurationKey];
    UInt32 count = duration / xScale + 0.5;
    self.points = [NSMutableArray arrayWithCapacity:count];
    while ([points count] < count) {
	[points addObject:[NSNumber numberWithFloat:0.0]];
    }

    newest = 0;

    self.dataCapture = [DataCapture create];
    self.signalDetector = [SignalDetector create];
    self.switchDetector = [SwitchDetector createWithSampleRate:dataCapture.sampleRate];
    self.vertexBufferManager = [VertexBufferManager createForDuration:1.0 sampleRate:dataCapture.sampleRate];

    dataCapture.signalDetector = signalDetector;
    dataCapture.switchDetector = switchDetector;
    dataCapture.vertexBufferManager = vertexBufferManager;
    
    application.idleTimerDisabled = YES;

    [notificationCenter addObserver:self 
			   selector:@selector(updateSignalStats:)
			       name:kSignalDetectorCounterUpdateNotification
			     object:signalDetector];

    NSError* error;
    if (![self.fetchedResultsController performFetch:&error]) {
	NSLog(@"unresolved error %@, %@", error, [error userInfo]);
    }

    [self.window addSubview:tabBarController.view];
    [self.window makeKeyAndVisible];
	
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    NSLog(@"applicationWillResignActive");
    [self stop];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    NSLog(@"applicationDidBecomeActive");
    [self start];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    NSLog(@"applicationWillTerminate");
    [self stop];
}

- (void)start
{
    [dataCapture start];
    [signalDetector start];
    [self updateDropboxUploader];
}

- (void)stop
{
    [self stopRecording];
    [signalDetector stop];
    [dataCapture stop];
    self.uploader = nil;

    NSError* error;
    if (managedObjectContext != nil && [managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
	NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
}

#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
    NSLog(@"applicationDidReceiveMemoryWarning");
}

- (void)dealloc {
    [window release];
    self.dataCapture = nil;
    self.signalDetector = nil;
    self.switchDetector = nil;
    self.vertexBufferManager = nil;
    self.uploader = nil;
    [super dealloc];
}

#pragma mark -
#pragma mark IASKAppSettingsViewControllerDelegate protocol

- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController*)sender
{
    [settingsController synchronizeSettings];
    [rpmViewController updateFromSettings];
    [signalDetector updateFromSettings];
    [signalViewController updateFromSettings];
    [switchDetector updateFromSettings];
    [settingsController synchronizeSettings];

    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    xScale = [settings floatForKey:kSettingsSignalDetectorUpdateRateKey];
    Float32 duration = [settings floatForKey:kSettingsRpmViewDurationKey];
    UInt32 count = duration / xScale + 0.5;
    if (count != [points count]) {
	self.points = [NSMutableArray arrayWithCapacity:count];
	while ([points count] < count) {
	    [points addObject:[NSNumber numberWithFloat:0.0]];
	}
	newest = 0;
	[rpmViewController update];
    }

    [self updateDropboxUploader];
}

#pragma mark -
#pragma mark Periodic Updates

- (void)updateSignalStats:(NSNotification*)notification
{
    if (newest == 0) newest = [points count];
    newest -= 1;
    NSDictionary* userInfo = [notification userInfo];
    NSNumber* rpmValue = [userInfo objectForKey:kSignalDetectorRPMKey];
    [points replaceObjectAtIndex:newest withObject:rpmValue];
    [rpmViewController update];
	
    if (uploader != nil && fetchedResultsController != nil && ! [self isRecording]) {
	NSArray* recordings = [fetchedResultsController fetchedObjects];
	UInt32 count = [recordings count];
	for (int index = 0; index < count; ++index) {
	    RecordingInfo* recording = [recordings objectAtIndex:index];
	    if (recording.uploaded == NO) {
		uploader.uploadingFile = recording;
		break;
	    }
	}
    }
}

#pragma mark -
#pragma mark UITabBarControllerDelegate protocol

- (BOOL)tabBarController:(UITabBarController*)sender shouldSelectViewController:(UIViewController*)viewController
{
    UIViewController* current = [sender selectedViewController];
    if (current != viewController) {
	if (sender.selectedIndex == 3) {
	    [settingsController dismiss:self];
	}
    }
	
    return YES;
}

#pragma mark -
#pragma mark Plot Data Source Methods

- (NSUInteger)numberOfRecordsForPlot:(CPPlot*)plot
{
    return [points count];
}

- (NSNumber*)numberForPlot:(CPPlot*)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    switch (fieldEnum) {
    case CPScatterPlotFieldX:
	// Generate X values based on the index of the point we are working with
	return [NSNumber numberWithFloat:(index * xScale)];
	break;
    case CPScatterPlotFieldY:
	// Points are stored in a circular buffer, starting at newest.
	index = ( newest + index ) % [points count];
	return [points objectAtIndex:index];
	break;
    default:
	// Anything else is ignored.
	return [NSDecimalNumber zero];
    }
}

#pragma mark -
#pragma mark Dropbox Management and Settings Display

- (void)updateDropboxCell:(UITableViewCell*)cell
{
    cell.textLabel.text = @"Dropbox";
    if ([dropboxSession isLinked]) {
	cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else {
	cell.accessoryType = UITableViewCellAccessoryNone;
    }
    [cell setNeedsDisplay];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == [actionSheet destructiveButtonIndex]) {
        [dropboxSession unlink];
	[self updateDropboxCell:settingsController.dropboxCell];
    }
}

- (void)setupDropbox
{
    if (![dropboxSession isLinked]) {
        DBLoginController* controller = [[DBLoginController new] autorelease];
        controller.delegate = self;
        [controller presentFromController:settingsController];
    }
    else {
	NSString* cancel = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone ? @"No" : nil;
	UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:@"Really unlink Dropbox account? Doing so will disable automatic uploading of recordings."
								 delegate:self 
							cancelButtonTitle:nil
						   destructiveButtonTitle:@"Unlink"
							otherButtonTitles:nil];
			
	[actionSheet setDelegate:self];
	[actionSheet showFromTabBar:[tabBarController tabBar]];
    }
}

- (void)updateDropboxUploader
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kSettingsCloudStorageEnableKey] == YES &&
	[dropboxSession isLinked] == YES) {
	if (uploader == nil) {
	    self.uploader = [DropboxUploader createWithSession:dropboxSession];
	}
    }
    else {
	if (uploader != nil) {
	    self.uploader = nil;
	}
    }
}

- (void)sessionDidReceiveAuthorizationFailure:(DBSession*)session
{
    self.uploader = nil;
    NSLog(@"failed to receive authorization");
    [[[[UIAlertView alloc] 
	   initWithTitle:@"Dropbox Authorization" 
		 message:@"Failed to access configured Dropbox account." 
		delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]
	 autorelease]
	show];
}

- (void)loginControllerDidLogin:(DBLoginController *)controller
{
    [self updateDropboxCell:settingsController.dropboxCell];
}

- (void)loginControllerDidCancel:(DBLoginController *)controller
{
    ;
}

- (CGFloat)tableView:(UITableView*)tableView heightForSpecifier:(IASKSpecifier*)specifier {
    return 44;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForSpecifier:(IASKSpecifier*)specifier {
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:specifier.key];
    if (!cell) {
	cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:specifier.key] autorelease];
    }
    [self updateDropboxCell:cell];
    return cell;
}

#pragma mark -
#pragma mark Recording Control

- (void)startRecording
{
    RecordingInfo* recording = [NSEntityDescription insertNewObjectForEntityForName:@"RecordingInfo"
							     inManagedObjectContext:self.managedObjectContext];
    [recording initialize];
    dataCapture.sampleRecorder = [SampleRecorder createRecording:recording];
}

- (void)stopRecording
{
    signalViewController.recordIndicator.on = NO;
    dataCapture.sampleRecorder = nil;
    NSError* error;
    if ([self.managedObjectContext save:&error] != YES) {
	NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
}

- (BOOL)isRecording
{
    dataCapture != nil && dataCapture.sampleRecorder != nil;
}

- (BOOL)isRecordingInto:(RecordingInfo*)recording
{
    return [self isRecording] && dataCapture.sampleRecorder.recording == recording;
}

- (void)removeRecordingAt:(NSIndexPath *)indexPath
{
    RecordingInfo* recordingInfo = [fetchedResultsController objectAtIndexPath:indexPath];
    NSLog(@"deleting file '%@'", recordingInfo.filePath);
	
    if ([self isRecordingInto:recordingInfo]) {
	[self stopRecording];
    }
	
    if (uploader != nil && uploader.uploadingFile == recordingInfo) {
	[self.uploader cancelUploads];
    }
    NSError* error;
    if ([[NSFileManager defaultManager] removeItemAtPath:recordingInfo.filePath error:&error] == NO) {
	NSLog(@"failed to remove file at '%@' - %@, %@", recordingInfo.filePath, error, [error userInfo]);
    }
	
    [managedObjectContext deleteObject:recordingInfo];
    if (![managedObjectContext save:&error]) {
	// Update to handle the error appropriately.
	NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
}

#pragma mark -
#pragma mark CoreData

- (NSString*)applicationDocumentsDirectory
{
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

- (NSManagedObjectModel*)managedObjectModel
{
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }

    managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];
    return managedObjectModel;
}

- (NSPersistentStoreCoordinator*)persistentStoreCoordinator
{
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }

    NSString* storePath = [self.applicationDocumentsDirectory stringByAppendingPathComponent: @"Recordings.sqlite"];
    NSURL* storeUrl = [NSURL fileURLWithPath:storePath];
    NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:
					      [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
					      [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
					  nil];
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
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
    if (managedObjectContext != nil) {
        return managedObjectContext;
    }

    NSPersistentStoreCoordinator* coordinator = self.persistentStoreCoordinator;
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    }

    return managedObjectContext;
}

- (NSFetchedResultsController*)fetchedResultsController
{
    if (fetchedResultsController != nil) {
        return fetchedResultsController;
    }

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
    fetchedResultsController.delegate = recordingsViewController;

    return fetchedResultsController;
}

@end
