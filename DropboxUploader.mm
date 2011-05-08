// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "DropboxUploader.h"
#import "RecordingInfo.h"

@interface DropboxUploader ()

- (void)networkReachabilityChanged:(NSNotification*)notification;
- (void)startRestClient;
- (void)warnNetworkAvailable;
- (void)stopRestClient;
- (void)warnNetworkUnavailable;
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;

@end

@implementation DropboxUploader

@synthesize uploadingFile, postedAlert;

+ (id)createWithSession:(DBSession*)session
{
    return [[[DropboxUploader alloc] initWithSession:session] autorelease];
}

- (id)initWithSession:(DBSession *)theSession
{
    if (self = [super init]) {
	session = [theSession retain];
	hasFolder = NO;
	warnedUser = NO;
	postedAlert = nil;
	self.uploadingFile = nil;
	serverReachability = [Reachability reachabilityWithHostName:@"dropbox.com"];
	[serverReachability retain];
	[[NSNotificationCenter defaultCenter] addObserver:self
						 selector:@selector(networkReachabilityChanged:) 
						     name:kReachabilityChangedNotification
						   object:serverReachability];
	[serverReachability startNotifier];
        [self networkReachabilityChanged: nil];
    }

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self 
						    name:kReachabilityChangedNotification
						  object:serverReachability];
    [self stopRestClient];

    self.postedAlert = nil;

    [serverReachability stopNotifier];
    [serverReachability release];
    serverReachability = nil;

    [session release];
    session = nil;

    [super dealloc];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [postedAlert autorelease];
    postedAlert = nil;
}

- (void)cancelUploads
{
    if (restClient) {
	[restClient cancelAllUploads];
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }
}

- (void)startRestClient
{
    restClient = [[DBRestClient alloc] initWithSession:session];
    restClient.delegate = self;
    if (hasFolder == NO) {
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	[restClient createFolder:@"/Datac"];
    }
}

- (void)stopRestClient
{
    if (restClient) {
	[restClient cancelAllUploads];
	[restClient release];
	restClient = nil;
    }

    self.uploadingFile = nil;
}

- (void)setPostedAlert:(UIAlertView *)alert
{
    if (postedAlert) {
	[postedAlert dismissWithClickedButtonIndex:0 animated:NO];
	[postedAlert autorelease];
	postedAlert = nil;
    }
	
    postedAlert = alert;
    [postedAlert show];
}

- (void)warnNetworkAvailable
{
    if (warnedUser == YES) {
	self.postedAlert = [[UIAlertView alloc] initWithTitle:@"Network Available" 
						      message:@"Uploading files to Dropbox account." 
						     delegate:self
					    cancelButtonTitle:@"OK"
					    otherButtonTitles:nil];
	warnedUser = NO;
    }
}

- (void)networkReachabilityChanged:(NSNotification *)notification
{
    ReachabilityState state = [serverReachability currentReachabilityState];
    NSLog(@"DropboxUploader.networkReachabilityChanged: %d", state);
    if (state == kNotReachable) {
        if (restClient != nil) {
            [self stopRestClient];
            [self warnNetworkUnavailable];
        }
    }
    else {
        if (restClient == nil) {
            [self startRestClient];
            [self warnNetworkAvailable];
        }
    }
}

- (void)warnNetworkUnavailable
{
    if (warnedUser == NO) {
	self.postedAlert = [[UIAlertView alloc] initWithTitle:@"Network Unavailable" 
						      message:@"Unable to upload files to Dropbox account." 
						     delegate:nil
					    cancelButtonTitle:@"OK" 
					    otherButtonTitles:nil];
	warnedUser = YES;
    }
}

- (void)setUploadingFile:(RecordingInfo*)recording
{
    if (recording == nil) {
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	if (uploadingFile != nil) {
	    uploadingFile.uploading = NO;
	    uploadingFile.progress = 0.0;
	    [uploadingFile release];
	    uploadingFile = nil;
	}
	return;
    }
	
    if (restClient == nil) {
	return;
    }

    if (hasFolder == NO || uploadingFile != nil) {
	return;
    }

    uploadingFile = [recording retain];
    uploadingFile.uploading = YES;

    NSLog(@"DropboxUploader - uploading file: %@", uploadingFile.filePath);

    [restClient uploadFile:uploadingFile.name
		    toPath:@"/Datac"
		  fromPath:uploadingFile.filePath];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

- (void)restClientDidLogin:(DBRestClient*)client
{
    NSLog(@"DropboxUploader.restClientDidLogin");
}

- (void)restClient:(DBRestClient*)client createdFolder:(DBMetadata*)folder
{
    NSLog(@"DropboxUploader.restClient:createdFolder:");
    hasFolder = YES;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void)restClient:(DBRestClient*)client createFolderFailedWithError:(NSError*)error
{
    NSLog(@"DropboxUploader.restClient:createFolderFailedWithError: %@, %@", error, [error userInfo]);
    if ([[error domain] isEqualToString:@"dropbox.com"] && [error code] == 403) {
	hasFolder = YES;
    }
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void)restClient:(DBRestClient*)client uploadProgress:(CGFloat)progress 
	   forFile:(NSString*)destPath from:(NSString*)srcPath;
{
    NSLog(@"DropboxUploader.restClient:uploadProgress");
    uploadingFile.progress = progress;
}

- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath from:(NSString*)srcPath
{
    NSLog(@"DropboxUploader.restClient:uploadedFile");
    uploadingFile.uploaded = YES;
    self.uploadingFile = nil;
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error
{
    NSLog(@"DropboxUploader.restClient:uploadFileFailedWithError: - %@, %@", error, [error userInfo]);
    self.uploadingFile = nil;
}

@end
