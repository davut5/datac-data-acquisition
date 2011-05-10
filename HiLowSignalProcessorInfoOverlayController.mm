// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "HiLowSignalProcessorInfoOverlayController.h"

@interface HiLowSignalProcessorInfoOverlayController(Private)

@end

@implementation HiLowSignalProcessorInfoOverlayController

- (void)viewDidLoad
{
#if 0
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(updateSignalStats:)
                                                 name:kLevelDetectorCounterUpdateNotification
                                               object:nil];
#endif
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

@implementation HiLowSignalProcessorInfoOverlayController(Private)

#if 0

- (void)updateSignalStats:(NSNotification *)notification
{
    NSDictionary* userInfo = [notification userInfo];
    NSNumber* peaksValue = [userInfo objectForKey:kLevelDetectorCounterKey];
    peaks.text = [peaksValue stringValue];
    NSNumber* rpmValue = [userInfo objectForKey:kLevelDetectorRPMKey];
    rpms.text = [rpmValue stringValue];
}

#endif
@end
