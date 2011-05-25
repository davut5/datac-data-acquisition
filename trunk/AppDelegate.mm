// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "AppDelegate.h"
#import "BitDetector.h"
#import "BitFrameDecoder.h"
#import "BitStreamFrameDetector.h"
#import "DetectionsViewController.h"
#import "DropboxSDK.h"
#import "Dropbox.keys"
#import "DropboxUploader.h"
#import "FrequencyDetector.h"
#import "IASKSpecifier.h"
#import "IndicatorButton.h"
#import "RecordingInfo.h"
#import "RecordingsViewController.h"
#import "SampleRecorder.h"
#import "LevelDetector.h"
#import "LevelDetectorController.h"
#import "SampleViewController.h"
#import "SettingsViewController.h"
#import "UserSettings.h"
#import "VertexBufferManager.h"
#import "WaveCycleDetector.h"

@implementation AppDelegate

@synthesize window, tabBarController, samplesViewController, appSettingsViewController, recordingsViewController;
@synthesize detectionsViewController, dropboxSession;
@synthesize dataCapture, signalDetector, switchDetector, vertexBufferManager;

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSLog(@"AppDelegate.application:didFinishLaunchingWithOptions:");

    //
    // Dropbox SDK initialization
    //
    NSString* consumerKey = DROPBOX_KEY;
    NSString* consumerSecret = DROPBOX_SECRET;
    dropboxSession = [[[DBSession alloc] initWithConsumerKey:consumerKey consumerSecret:consumerSecret] autorelease];
    dropboxSession.delegate = self;
    [DBSession setSharedSession:dropboxSession];

    [application setStatusBarStyle:UIStatusBarStyleBlackTranslucent];

    self.dataCapture = [DataCapture create];
    self.signalDetector = [LevelDetector create];
    self.switchDetector = [MicSwitchDetector createWithSampleRate:dataCapture.sampleRate];
    self.vertexBufferManager = [VertexBufferManager createForDuration:1.0 sampleRate:dataCapture.sampleRate];

    dataCapture.sampleProcessor = [self.signalDetector sampleProcessor];
    dataCapture.switchDetector = switchDetector;
    dataCapture.vertexBufferManager = vertexBufferManager;
    
    self.detectionsViewController.detector = self.signalDetector;

    application.idleTimerDisabled = YES;

    [self.window addSubview:tabBarController.view];
    [self.window makeKeyAndVisible];

    NSLog(@"AppDelegate.application:didFinishLaunchingWithOptions: - END");
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    NSLog(@"applicationWillResignActive");
    [self stop];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    NSLog(@"applicationDidBecomeActive");
    // [self start];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    NSLog(@"applicationWillTerminate");
    [self stop];
}

- (void)start
{
    NSLog(@"AppDelegate.start");
    if (dataCapture.audioUnitRunning == NO) {
        [dataCapture start];
        [signalDetector reset];
    }
}

- (void)stop
{
    NSLog(@"AppDelegate.stop");
    [self stopRecording];
    [dataCapture stop];
    [recordingsViewController saveContext];
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
    [super dealloc];
}

#pragma mark -
#pragma mark DBSession Delegate Protocol

- (void)sessionDidReceiveAuthorizationFailure:(DBSession*)session
{
    NSLog(@"failed to receive authorization");
    [[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Dropbox Authorization", @"Dropbox authorization failure alert title.")
                                 message:NSLocalizedString(@"Failed to access configured Dropbox account.",
                                                           @"Dropbox authorization failure alert text.")
                                delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease] show];
}

#pragma mark -
#pragma mark UITabBarControllerDelegate protocol

- (BOOL)tabBarController:(UITabBarController*)sender shouldSelectViewController:(UIViewController*)viewController
{
    NSLog(@"AppDelegate.tabBarController:shouldSelectViewController: %@", viewController);
    UIViewController* current = [sender selectedViewController];
    if (current == viewController) {
        if (sender.selectedIndex == 0) {
            [samplesViewController toggleInfoOverlay];
        }
    }
    else {
	if (sender.selectedIndex == 3) {
	    [settingsController dismiss:self];
	}
    }

    return YES;
}

#pragma mark -
#pragma mark Recording Management

- (void)startRecording
{
    RecordingInfo* recording = [recordingsViewController makeRecording];
    dataCapture.sampleRecorder = [SampleRecorder createRecording:recording withFormat:dataCapture.streamFormat];
}

- (void)stopRecording
{
    samplesViewController.recordIndicator.on = NO;
    dataCapture.sampleRecorder = nil;
    [recordingsViewController saveContext];
}

- (BOOL)isRecording
{
    dataCapture != nil && dataCapture.sampleRecorder != nil;
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
    dataCapture.invertSignal = [settings boolForKey:kSettingsInputViewInvertKey];

    [samplesViewController updateFromSettings];
    [detectionsViewController updateFromSettings];
    [recordingsViewController updateFromSettings];
    [signalDetector updateFromSettings];
    [switchDetector updateFromSettings];
}

@end
