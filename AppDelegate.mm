// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "AppDelegate.h"
#import "BitDetector.h"
#import "BitFrameDecoder.h"
#import "BitStreamFrameDetector.h"
#import "DropboxSDK.h"
#import "Dropbox.keys"
#import "DropboxUploader.h"
#import "FrequencyDetector.h"
#import "IASKSpecifier.h"
#import "IndicatorButton.h"
#import "RecordingInfo.h"
#import "RecordingsViewController.h"
#import "RpmViewController.h"
#import "SampleRecorder.h"
#import "LevelDetector.h"
#import "LevelDetectorController.h"
#import "SignalViewController.h"
#import "SettingsViewController.h"
#import "UserSettings.h"
#import "VertexBufferManager.h"
#import "WaveCycleDetector.h"

@interface AppDelegate ()

- (void)uploaderCheck:(NSNotification*)notification;
- (void)updateDropboxUploader;
- (void)updateDropboxCell:(UITableViewCell*)cell;
- (void)sessionDidReceiveAuthorizationFailure:(DBSession*)session;

@end

@implementation AppDelegate

@synthesize window, tabBarController, signalViewController, appSettingsViewController, recordingsViewController;
@synthesize rpmViewController, dropboxSession, fetchedResultsController;
@synthesize dataCapture, signalDetector, switchDetector, vertexBufferManager, uploader, uploadChecker;

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

    self.dataCapture = [DataCapture create];
    self.signalDetector = [LevelDetector create];
    self.switchDetector = [MicSwitchDetector createWithSampleRate:dataCapture.sampleRate];
    self.vertexBufferManager = [VertexBufferManager createForDuration:1.0 sampleRate:dataCapture.sampleRate];

    dataCapture.sampleProcessor = [self.signalDetector sampleProcessor];
    dataCapture.switchDetector = switchDetector;
    dataCapture.vertexBufferManager = vertexBufferManager;
    
    application.idleTimerDisabled = YES;

    NSError* error;
    if (![self.fetchedResultsController performFetch:&error]) {
	NSLog(@"unresolved error %@, %@", error, [error userInfo]);
    }

    [self.window addSubview:tabBarController.view];
    [self.window makeKeyAndVisible];

    self.uploadChecker = [NSTimer scheduledTimerWithTimeInterval:1.0 
                                                            target:self
                                                          selector:@selector(uploaderCheck:)
                                                          userInfo:nil 
                                                           repeats:YES];

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
    [self updateDropboxUploader];
}

#pragma mark -
#pragma mark Periodic Updates

- (void)uploaderCheck:(NSNotification*)notification
{
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
    NSLog(@"AppDelegate.tabBarController:shouldSelectViewController: %@", viewController);
    UIViewController* current = [sender selectedViewController];
    if (current == viewController) {
        if (sender.selectedIndex == 0) {
            [signalViewController toggleInfoOverlay];
        }
    }
    else {
	if (sender.selectedIndex == 3) {
	    [settingsController dismiss:self];
	}
        else if (viewController == rpmViewController) {
            [rpmViewController.view sizeToFit];
        }
    }
	
    return YES;
}

#pragma mark -
#pragma mark Dropbox Management and Settings Display

- (void)updateDropboxCell:(UITableViewCell*)cell
{
    cell.textLabel.text = NSLocalizedString(@"Dropbox", @"Name of the Dropbox button shown in the Settings Display");
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
	UIActionSheet* actionSheet = [[UIActionSheet alloc] 
                                      initWithTitle:NSLocalizedString(@"Really unlink Dropbox account?",
                                                                      @"Prompt to show before unlinking account")
                                            delegate:self cancelButtonTitle:nil
                                      destructiveButtonTitle:NSLocalizedString(@"Unlink", @"Unlink button title")
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
	   initWithTitle:NSLocalizedString(@"Dropbox Authorization", @"Dropbox authorization failure alert title.")
		 message:NSLocalizedString(@"Failed to access configured Dropbox account.",
                                           @"Dropbox authorization failure alert text.")
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
