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
- (void)attemptLoadAccountInfo:(NSTimer*)timer;
- (void)attemptCreateRemoteFolder:(NSTimer*)timer;

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

- (void)cancelUpload
{
    if (restClient != nil && uploadingFile != nil) {
        [restClient cancelFileUpload:@"/Datac"];
        [restClient cancelFileUpload:uploadingFile.filePath];
        self.networkActivityIndicator = nil;
    }
}

- (void)startRestClient
{
    restClient = [[DBRestClient alloc] initWithSession:session];
    restClient.delegate = self;
    [self attemptLoadAccountInfo:nil];
}

- (void)attemptLoadAccountInfo:(NSTimer*)timer
{
    [restClient loadAccountInfo];
}

- (void)restClient:(DBRestClient*)client loadedAccountInfo:(DBAccountInfo*)info
{
    LOG(@"DropboxUploader.restClient:loadedAccountInfo:");
    self.networkActivityIndicator = [NetworkActivityIndicator create];
    [self attemptCreateRemoteFolder:nil];
}

- (void)restClient:(DBRestClient*)client loadAccountInfoFailedWithError:(NSError*)error
{
    LOG(@"DropboxUploader.restClient:loadAccountInfoFailedWithError: %@, %@", error, [error userInfo]);
    [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(attemptLoadAccountInfo:) userInfo:nil
                                    repeats:NO];
}

- (void)attemptCreateRemoteFolder:(NSTimer*)timer
{
    [restClient createFolder:@"/Datac"];
}

- (void)restClient:(DBRestClient*)client createdFolder:(DBMetadata*)folder
{
    LOG(@"DropboxUploader.restClient:createdFolder:");
    [self readyToUpload];
}

- (void)restClient:(DBRestClient*)client createFolderFailedWithError:(NSError*)error
{
    LOG(@"DropboxUploader.restClient:createFolderFailedWithError: %@, %@", error, [error userInfo]);
    if (error.code == 403) {
        [self readyToUpload];
    }
    else {
        [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(attemptCreateRemoteFolder:) userInfo:nil
                                        repeats:NO];
    }
}

- (void)stopRestClient
{
    if (restClient) {
        [self cancelUpload];
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
        self.postedAlert = [[[UIAlertView alloc] initWithTitle:@"Network Available"
                                                       message:@"Uploading files to Dropbox account."
                                                      delegate:self
                                             cancelButtonTitle:@"OK"
                                             otherButtonTitles:nil] autorelease];
        warnedUser = NO;
    }
}

- (void)warnNetworkUnavailable
{
    if (warnedUser == NO) {
        self.postedAlert = [[[UIAlertView alloc] initWithTitle:@"Network Unavailable"
                                                       message:@"Unable to upload files to Dropbox account."
                                                      delegate:nil
                                             cancelButtonTitle:@"OK"
                                             otherButtonTitles:nil] autorelease];
        warnedUser = YES;
    }
}

- (void)networkReachabilityChanged:(NSNotification *)notification
{
    ReachabilityState state = [serverReachability currentReachabilityState];
    LOG(@"DropboxUploader.networkReachabilityChanged: %d", state);
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

    LOG(@"DropboxUploader - uploading file: %@", uploadingFile.filePath);
    
    [restClient uploadFile:[uploadingFile.filePath lastPathComponent]
                    toPath:@"/Datac" withParentRev:nil fromPath:uploadingFile.filePath];
    
    self.networkActivityIndicator = [NetworkActivityIndicator create];
}

- (void)restClient:(DBRestClient*)client uploadProgress:(CGFloat)progress
           forFile:(NSString*)destPath from:(NSString*)srcPath;
{
    // LOG(@"DropboxUploader.restClient:uploadProgress");
    uploadingFile.progress = progress;
}

- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath from:(NSString*)srcPath
{
    LOG(@"DropboxUploader.restClient:uploadedFile");
    uploadingFile.uploaded = YES;
    uploadingFile.progress = 0.0;
    [self readyToUpload];
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error
{
    LOG(@"DropboxUploader.restClient:uploadFileFailedWithError: - %@, %@", error, [error userInfo]);
    uploadingFile.progress = error.code * -1.0;
    [self readyToUpload];
}

- (void)readyToUpload
{
    if (uploadingFile != nil) {
        uploadingFile.uploading = NO;
        [uploadingFile release];
        uploadingFile = nil;
    }
    
    self.networkActivityIndicator = nil;
    
    [monitor readyToUpload];
}

@end
