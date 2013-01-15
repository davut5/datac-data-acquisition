// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "AppDelegate.h"
#import "BitDetector.h"
#import "BitFrameDecoder.h"
#import "BitStreamFrameDetector.h"
#import "DetectionsViewController.h"
#import "Dropbox.keys"
#import "DropboxUploader.h"
#import "FrequencyDetector.h"
#import "IASKSpecifier.h"
#import "IndicatorButton.h"
#import "RecordingInfo.h"
#import "RecordingsViewController.h"
#import "SampleRecorder.h"
#import "PeakDetector.h"
#import "PulseWidthDetector.h"
#import "SampleViewController.h"
#import "SettingsViewController.h"
#import "UserSettings.h"
#import "VertexBufferManager.h"
#import "WaveCycleDetector.h"

@interface AppDelegate (Private)

- (void)makeSignalDetector;

@end

@implementation AppDelegate

@synthesize window, tabBarController, sampleViewController, settingsViewController, recordingsViewController;
@synthesize detectionsViewController, dropboxSession;
@synthesize dataCapture, signalDetector, switchDetector, vertexBufferManager;

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    LOG(@"AppDelegate.application:didFinishLaunchingWithOptions:");
    
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    
    //
    // Dropbox SDK initialization
    //
    NSString* consumerKey = DROPBOX_KEY;
    NSString* consumerSecret = DROPBOX_SECRET;
    dropboxSession = [[[DBSession alloc] initWithAppKey:consumerKey appSecret:consumerSecret root:kDBRootDropbox] autorelease];
    dropboxSession.delegate = self;
    [DBSession setSharedSession:dropboxSession];
    
    [application setStatusBarStyle:UIStatusBarStyleBlackOpaque];
    
    self.dataCapture = [DataCapture create];
    [self makeSignalDetector];
    self.switchDetector = [MicSwitchDetector createWithSampleRate:dataCapture.sampleRate];
    self.vertexBufferManager = [VertexBufferManager createForDuration:1.0 sampleRate:dataCapture.sampleRate bufferSize:512 * 4];

    dataCapture.invertSignal = [settings boolForKey:kSettingsSignalProcessingInvertSignalKey];
    dataCapture.switchDetector = switchDetector;
    dataCapture.vertexBufferManager = vertexBufferManager;
    
    application.idleTimerDisabled = YES;
    
    self.window.rootViewController = tabBarController;
    [self.window addSubview:tabBarController.view];
    [self.window makeKeyAndVisible];
    
    [NSTimer scheduledTimerWithTimeInterval:0.0 target:self selector:@selector(start) userInfo:nil repeats:NO];
    
    LOG(@"AppDelegate.application:didFinishLaunchingWithOptions: - END");
    return YES;
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    if ([[DBSession sharedSession] handleOpenURL:url]) {
        if ([[DBSession sharedSession] isLinked]) {
            LOG(@"App linked successfully!");
            // At this point you can start making API calls
            if (settingsViewController != nil) {
                [settingsViewController updateDropboxCell];
            }
        }
        return YES;
    }
    // Add whatever other url handling code your app requires here
    return NO;
}

- (void)makeSignalDetector
{
    NSString* detectorClass = [[NSUserDefaults standardUserDefaults]
                               stringForKey:kSettingsSignalProcessingActiveDetectorKey];
    NSBundle* bundle = [NSBundle mainBundle];
    Class cls = [bundle classNamed:detectorClass];
    
    self.signalDetector = [[[cls alloc] init] autorelease];
    self.detectionsViewController.detector = self.signalDetector;
    self.dataCapture.sampleProcessor = [self.signalDetector sampleProcessor];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    LOG(@"applicationWillResignActive");
    [self stop];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    LOG(@"applicationDidBecomeActive");
    vertexBufferManager.sampleView = sampleViewController.sampleView;
    [dataCapture start];
    [self start];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    LOG(@"applicationWillTerminate");
    [dataCapture stop];
    [self stop];
}

- (void)start
{
    LOG(@"AppDelegate.start");
    [signalDetector reset];
    [sampleViewController start];
}

- (void)stop
{
    LOG(@"AppDelegate.stop");
    [self stopRecording];
    [recordingsViewController saveContext];
}

#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
    LOG(@"applicationDidReceiveMemoryWarning");
}

- (void)dealloc {
    [window release];
    self.dataCapture = nil;
    self.signalDetector = nil;
    self.switchDetector = nil;
    self.vertexBufferManager = nil;
    [super dealloc];
}

#pragma mark -
#pragma mark DBSession Delegate Protocol

- (void)sessionDidReceiveAuthorizationFailure:(DBSession *)session userId:(NSString *)userId;
{
    LOG(@"failed to receive authorization");
    [[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Dropbox Authorization",
                                                           @"Dropbox authorization failure alert title.")
                                 message:NSLocalizedString(@"Failed to access configured Dropbox account.",
                                                           @"Dropbox authorization failure alert text.")
                                delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease] show];
}

#pragma mark -
#pragma mark UITabBarControllerDelegate protocol

- (BOOL)tabBarController:(UITabBarController*)sender shouldSelectViewController:(UIViewController*)viewController
{
    LOG(@"AppDelegate.tabBarController:shouldSelectViewController: %@", viewController);
    UIViewController* current = [sender selectedViewController];
    if (current == viewController) {
        if (sender.selectedIndex == 0) {
            [sampleViewController toggleInfoOverlay];
        }
    }
    else {
        if (sender.selectedIndex == 3) {
            [settingsViewController dismiss:self];
        }
    }
    
    return YES;
}

#pragma mark -
#pragma mark Recording Management

- (void)startRecording
{
    RecordingInfo* recording = [recordingsViewController startRecording];
    dataCapture.sampleRecorder = [SampleRecorder createRecording:recording withFormat:dataCapture.streamFormat];
    UITabBarItem* item = [tabBarController.tabBar.items objectAtIndex:0];
    item.badgeValue = @"REC";
}

- (void)stopRecording
{
    sampleViewController.recordIndicator.on = NO;
    dataCapture.sampleRecorder = nil;
    [recordingsViewController stopRecording];
    UITabBarItem* item = [tabBarController.tabBar.items objectAtIndex:0];
    item.badgeValue = nil;
}

- (BOOL)isRecording
{
    return dataCapture != nil && dataCapture.sampleRecorder != nil;
}

- (BOOL)isRecordingInto:(RecordingInfo*)recording
{
    return [self isRecording] && dataCapture.sampleRecorder.recording == recording;
}

- (void)recordingDeleted:(RecordingInfo*)recording
{
    if ([self isRecordingInto:recording]) [self stopRecording];
}

- (void)updateFromSettings
{
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    NSString* detectorClassName = [settings stringForKey:kSettingsSignalProcessingActiveDetectorKey];
    NSString* currentClassName = NSStringFromClass([signalDetector class]);
    if ([detectorClassName isEqualToString:currentClassName] == NO) {
        [self makeSignalDetector];
    }
    
    dataCapture.invertSignal = [settings boolForKey:kSettingsSignalProcessingInvertSignalKey];
    
    [sampleViewController updateFromSettings];
    [detectionsViewController updateFromSettings];
    [recordingsViewController updateFromSettings];
    [signalDetector updateFromSettings];
    [switchDetector updateFromSettings];
}

@end
