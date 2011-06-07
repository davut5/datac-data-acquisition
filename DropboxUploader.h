// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DBRestClient.h"
#import "Reachability.h"

@class NetworkActivityIndicator;
@class RecordingInfo;

@protocol DropboxUploaderMonitor
@required

/**
 * Notification that the DropboxUploader is ready to upload a file.
 */
- (void)readyToUpload;

@end

@interface DropboxUploader : NSObject <DBRestClientDelegate> {
@private
    Reachability* serverReachability;
    DBSession* session;
    DBRestClient* restClient;
    RecordingInfo* uploadingFile;
    BOOL warnedUser;
    UIAlertView* postedAlert;
    NSObject<DropboxUploaderMonitor>* monitor;
    NetworkActivityIndicator* networkActivityIndicator;
}

@property (nonatomic, retain) RecordingInfo* uploadingFile;
@property (nonatomic, retain) UIAlertView* postedAlert;
@property (nonatomic, retain) NSObject<DropboxUploaderMonitor>* monitor;
@property (nonatomic, retain) NetworkActivityIndicator* networkActivityIndicator;

+ (id)createWithSession:(DBSession*)session;

- (id)initWithSession:(DBSession*)session;

- (void)cancelUploads;

@end
