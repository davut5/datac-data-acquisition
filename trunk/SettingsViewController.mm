// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <DropboxSDK/DropboxSDK.h>
#import "AppDelegate.h"
#import "IASKSpecifier.h"
#import "IASKSettingsReader.h"
#import "SettingsViewController.h"

@interface SettingsViewController ()

- (void)showAbout:(id)sender;
- (void)setupDropbox;

@end

@implementation SettingsViewController

@synthesize dropboxCell;

- (void)viewDidLoad
{
    NSLog(@"SettingsViewController.viewDidLoad");
    appDelegate = static_cast<AppDelegate*>([[UIApplication sharedApplication] delegate]);
    [super setDelegate: self];
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    NSLog(@"SettingsViewController.viewDidUnload");
    appDelegate = nil;
    [super setDelegate:nil];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.dropboxCell = nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    IASKSpecifier *specifier  = [self.settingsReader specifierForIndexPath:indexPath];
    self.dropboxCell = nil;
    if ([[specifier type] isEqualToString:kIASKCustomViewSpecifier]) {
        self.dropboxCell = [tableView cellForRowAtIndexPath:indexPath];
        [self setupDropbox];
    }
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
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

#pragma mark -
#pragma mark Dropbox Management and Settings Display

- (void)updateDropboxCell
{
    if ([[DBSession sharedSession] isLinked]) {
        dropboxCell.textLabel.text = NSLocalizedString(@"Account linked",
                                                       @"Name of the Dropbox button shown in the Settings Display");
        dropboxCell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else {
        dropboxCell.textLabel.text = NSLocalizedString(@"Link account", @"Name of the Dropbox button shown in the Settings Display");
        dropboxCell.accessoryType = UITableViewCellAccessoryNone;
    }
    [dropboxCell setNeedsDisplay];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == [actionSheet destructiveButtonIndex]) {
        [[DBSession sharedSession] unlinkAll];
        [self updateDropboxCell];
    }
}

- (void)setupDropbox
{
    if (![[DBSession sharedSession] isLinked]) {
        [[DBSession sharedSession] linkFromController:self];
    }
    else {

        //
        // Request to unlink Dropbox account. Show an action sheet, but don't show a cancel button per iPad UI
        // guidelines.
        //
        NSString* cancel = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone ? @"No" : nil;
        UIActionSheet* actionSheet = [[UIActionSheet alloc]
                                      initWithTitle:NSLocalizedString(@"Really unlink Dropbox account?",
                                                                      @"Prompt to show before unlinking account")
                                      delegate:self
                                      cancelButtonTitle:cancel
                                      destructiveButtonTitle:NSLocalizedString(@"Unlink", @"Unlink button title")
                                      otherButtonTitles:nil];
        [actionSheet setDelegate:self];
        [actionSheet showFromTabBar:[appDelegate.tabBarController tabBar]];
    }
}

- (CGFloat)tableView:(UITableView*)tableView heightForSpecifier:(IASKSpecifier*)specifier {
    return 44;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForSpecifier:(IASKSpecifier*)specifier {
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:specifier.key];
    if (!cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                       reuseIdentifier:specifier.key] autorelease];
    }
    
    self.dropboxCell = cell;
    [self updateDropboxCell];
    
    return cell;
}

#pragma mark -
#pragma mark IASKAppSettingsViewControllerDelegate protocol

- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController*)sender
{
    [self synchronizeSettings];
    [appDelegate updateFromSettings];
    [self synchronizeSettings];
}

@end
