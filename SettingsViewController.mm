// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "AppDelegate.h"
#import "IASKSpecifier.h"
#import "IASKSettingsReader.h"
#import "SettingsViewController.h"

@interface SettingsViewController ()

- (void)showAbout:(id)sender;

@end

@implementation SettingsViewController

@synthesize dropboxCell;

- (void)viewDidLoad
{
    NSLog(@"SettingsViewController.viewDidLoad");
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    NSLog(@"SettingsViewController.viewDidUnload");
    [super viewDidUnload];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    IASKSpecifier *specifier  = [self.settingsReader specifierForIndexPath:indexPath];
    self.dropboxCell = nil;
    if ([[specifier type] isEqualToString:kIASKCustomViewSpecifier]) {
	self.dropboxCell = [tableView cellForRowAtIndexPath:indexPath];
	[appDelegate setupDropbox];
    }
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.dropboxCell = nil;
}

- (void)dealloc
{
    self.dropboxCell = nil;
    [super dealloc];
}

- (void)showAbout:(id)sender
{
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

@end
