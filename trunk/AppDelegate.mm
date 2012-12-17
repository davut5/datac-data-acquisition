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

@synthesize window, tabBarController, samplesViewController, appSettingsViewController, recordingsViewController;
@synthesize detectionsViewController, dropboxSession;
@synthesize dataCapture, signalDetector, switchDetector, vertexBufferManager;

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSLog(@"AppDelegate.application:didFinishLaunchingWithOptions:");

    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];

    //
    // Dropbox SDK initialization
    //
    NSString* consumerKey = DROPBOX_KEY;
    NSString* consumerSecret = DROPBOX_SECRET;
    dropboxSession = [[[DBSession alloc] initWithAppKey:consumerKey appSecret:consumerSecret root:kDBRootDropbox] autorelease];
    dropboxSession.delegate = self;
    [DBSession setSharedSession:dropboxSession];

    [application setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
    
    self.dataCapture = [DataCapture create];
    [self makeSignalDetector];
    self.switchDetector = [MicSwitchDetector createWithSampleRate:dataCapture.sampleRate];
    self.vertexBufferManager = [VertexBufferManager createForDuration:1.0 sampleRate:dataCapture.sampleRate];

    dataCapture.invertSignal = [settings boolForKey:kSettingsSignalProcessingInvertSignalKey];
    dataCapture.switchDetector = switchDetector;
    dataCapture.vertexBufferManager = vertexBufferManager;
    
    application.idleTimerDisabled = YES;

    [self.window addSubview:tabBarController.view];
    [self.window makeKeyAndVisible];

    [NSTimer scheduledTimerWithTimeInterval:0.0 target:self selector:@selector(start) userInfo:nil repeats:NO];

    NSLog(@"AppDelegate.application:didFinishLaunchingWithOptions: - END");
    return YES;
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    if ([[DBSession sharedSession] handleOpenURL:url]) {
        if ([[DBSession sharedSession] isLinked]) {
            NSLog(@"App linked successfully!");
            // At this point you can start making API calls
            if (settingsController != nil) {
                [settingsController updateDropboxCell];
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
    NSLog(@"applicationWillResignActive");
    [self stop];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    NSLog(@"applicationDidBecomeActive");
    [dataCapture start];
    [self start];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    NSLog(@"applicationWillTerminate");
    [dataCapture stop];
    [self stop];
}

- (void)start
{
    NSLog(@"AppDelegate.start");
    [signalDetector reset];
}

- (void)stop
{
    NSLog(@"AppDelegate.stop");
    [self stopRecording];
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

- (void)sessionDidReceiveAuthorizationFailure:(DBSession *)session userId:(NSString *)userId;
{
    NSLog(@"failed to receive authorization");
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
    RecordingInfo* recording = [recordingsViewController startRecording];
    dataCapture.sampleRecorder = [SampleRecorder createRecording:recording withFormat:dataCapture.streamFormat];
}

- (void)stopRecording
{
    samplesViewController.recordIndicator.on = NO;
    dataCapture.sampleRecorder = nil;
    [recordingsViewController stopRecording];
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

    [samplesViewController updateFromSettings];
    [detectionsViewController updateFromSettings];
    [recordingsViewController updateFromSettings];
    [signalDetector updateFromSettings];
    [switchDetector updateFromSettings];
}

@end
