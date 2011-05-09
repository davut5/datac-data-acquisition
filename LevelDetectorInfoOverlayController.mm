// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "LevelDetector.h"
#import "LevelDetectorInfoOverlayController.h"

@interface LevelDetectorInfoOverlayController(Private)

- (void)updateSignalStats:(NSNotification*)notification;

@end

@implementation LevelDetectorInfoOverlayController

- (void)viewDidLoad
{
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(updateSignalStats:)
                                                 name:kLevelDetectorCounterUpdateNotification
                                               object:nil];
    [super viewDidLoad];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)viewDidUnload
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewDidUnload];
}

- (void)dealloc
{
    [super dealloc];
}

@end

@implementation LevelDetectorInfoOverlayController(Private)

- (void)updateSignalStats:(NSNotification *)notification
{
    NSDictionary* userInfo = [notification userInfo];
    NSNumber* peaksValue = [userInfo objectForKey:kLevelDetectorCounterKey];
    peaks.text = [peaksValue stringValue];
    NSNumber* rpmValue = [userInfo objectForKey:kLevelDetectorRPMKey];
    rpms.text = [rpmValue stringValue];
}

@end
