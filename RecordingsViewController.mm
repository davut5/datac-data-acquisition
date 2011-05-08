// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "AppDelegate.h"
#import "RecordingInfo.h"
#import "RecordingsViewController.h"

@interface RecordingsViewController ()

- (void)configureCell:(UITableViewCell*)cell withRecordingInfo:(RecordingInfo*)recordingInfo;

@end

@implementation RecordingsViewController

@synthesize uploadingFilePath;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    NSLog(@"RecordingsViewController.viewDidLoad");
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Recordings", @"Recordings view title");
    self.tableView.allowsSelection = NO;
}

- (void)viewDidUnload
{
    NSLog(@"RecordingsViewController.viewDidUnload");
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

- (void)controllerWillChangeContent:(NSFetchedResultsController*)controller
{
    NSLog(@"controllerWillChangeContent");
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController*)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath*)indexPath 
     forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath*)newIndexPath 
{
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
    NSLog(@"controllerDidChangeContent");
    [self.tableView endUpdates];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[appDelegate.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [[appDelegate.fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    static NSString* kCellIdentifier = @"RecordingInfoCell";
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
				       reuseIdentifier:kCellIdentifier] autorelease];
    }

    RecordingInfo* recording = [appDelegate.fetchedResultsController objectAtIndexPath:indexPath];
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
    else if ([appDelegate isRecordingInto:recording]) {
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
	    accessoryView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
	    CGRect bounds = accessoryView.bounds;
	    bounds.size.width = 100;
	    accessoryView.bounds = bounds;
	    [cell setAccessoryView:accessoryView];
	    // [accessoryView release];
	}
	[accessoryView setProgress:recording.progress];
    }
    else {
	[cell setAccessoryView:nil];
    }
}

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath 
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
	[appDelegate removeRecordingAt:indexPath];
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
#pragma mark Memory management

- (void)dealloc
{
    self.uploadingFilePath = nil;
    [super dealloc];
}

@end

