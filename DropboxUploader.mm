// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "DropboxUploader.h"
#import "NetworkActivityIndicator.h"
#import "RecordingInfo.h"

@interface DropboxUploader ()

- (void)startReachabilityService;
- (void)networkReachabilityChanged:(NSNotification*)notification;
- (void)startRestClient;
- (void)warnNetworkAvailable;
- (void)stopRestClient;
- (void)warnNetworkUnavailable;
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
- (void)readyToUpload;

@end

@implementation DropboxUploader

@synthesize uploadingFile, postedAlert, monitor, networkActivityIndicator;

+ (id)createWithSession:(DBSession*)session
{
    return [[[DropboxUploader alloc] initWithSession:session] autorelease];
}

- (id)initWithSession:(DBSession *)theSession
{
    if (self = [super init]) {
	session = [theSession retain];
	warnedUser = NO;
	postedAlert = nil;
        monitor = nil;
	uploadingFile = nil;
        networkActivityIndicator = nil;
        [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(startReachabilityService)
                                       userInfo:nil repeats:NO];
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
    self.networkActivityIndicator = nil;

    [serverReachability stopNotifier];
    [serverReachability release];
    serverReachability = nil;

    [session release];
    session = nil;

    [super dealloc];
}

- (void)startReachabilityService
{
    serverReachability = [Reachability reachabilityWithHostName:@"dropbox.com"];
    [serverReachability retain];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(networkReachabilityChanged:) 
                                                 name:kReachabilityChangedNotification
                                               object:serverReachability];
    [serverReachability startNotifier];
    [self networkReachabilityChanged: nil];
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
        self.networkActivityIndicator = nil;
    }
}

- (void)startRestClient
{
    restClient = [[DBRestClient alloc] initWithSession:session];
    restClient.delegate = self;
    [restClient loadAccountInfo];
}

- (void)stopRestClient
{
    if (restClient) {
	[restClient cancelAllUploads];
	[restClient release];
	restClient = nil;
    }

    if (uploadingFile != nil) {
        uploadingFile.uploading = NO;
        uploadingFile.progress = 0.0;
        [uploadingFile release];
        uploadingFile = nil;
    }

    self.networkActivityIndicator = nil;
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

- (void)setUploadingFile:(RecordingInfo*)recording
{
    if (restClient == nil) return;
    if (uploadingFile != nil) return;

    uploadingFile = [recording retain];
    uploadingFile.uploading = YES;

    NSLog(@"DropboxUploader - uploading file: %@", uploadingFile.filePath);

    [restClient uploadFile:[uploadingFile.filePath lastPathComponent]
		    toPath:@"/Datac"
		  fromPath:uploadingFile.filePath];

    self.networkActivityIndicator = [NetworkActivityIndicator create];
}

- (void)restClient:(DBRestClient*)client loadedAccountInfo:(DBAccountInfo*)info
{
    NSLog(@"DropboxUploader.restClient:loadedAccountInfo:");
    self.networkActivityIndicator = [NetworkActivityIndicator create];
    [restClient createFolder:@"/Datac"];
}

- (void)restClient:(DBRestClient*)client loadAccountInfoFailedWithError:(NSError*)error
{
    NSLog(@"DropboxUploader.restClient:loadAccountInfoFailedWithError: %@, %@", error, [error userInfo]);

    //
    // Hmmm. Retry later.
    //
    [NSTimer scheduledTimerWithTimeInterval:10.0 target:restClient selector:@selector(loadAccountInfo) userInfo:nil 
                                    repeats:NO];
}

- (void)restClient:(DBRestClient*)client createdFolder:(DBMetadata*)folder
{
    NSLog(@"DropboxUploader.restClient:createdFolder:");
    [self readyToUpload];
}

- (void)restClient:(DBRestClient*)client createFolderFailedWithError:(NSError*)error
{
    NSLog(@"DropboxUploader.restClient:createFolderFailedWithError: %@, %@", error, [error userInfo]);
    if ([error code] == 403) {
        [self readyToUpload];
    }
}

- (void)restClient:(DBRestClient*)client uploadProgress:(CGFloat)progress 
	   forFile:(NSString*)destPath from:(NSString*)srcPath;
{
    // NSLog(@"DropboxUploader.restClient:uploadProgress");
    uploadingFile.progress = progress;
}

- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath from:(NSString*)srcPath
{
    NSLog(@"DropboxUploader.restClient:uploadedFile");
    uploadingFile.uploaded = YES;
    [self readyToUpload];
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error
{
    NSLog(@"DropboxUploader.restClient:uploadFileFailedWithError: - %@, %@", error, [error userInfo]);
    [self readyToUpload];
}

- (void)readyToUpload
{
    if (uploadingFile != nil) {
        uploadingFile.uploading = NO;
        uploadingFile.progress = 0.0;
        [uploadingFile release];
        uploadingFile = nil;
    }

    self.networkActivityIndicator = nil;

    [monitor readyToUpload];
}

@end
