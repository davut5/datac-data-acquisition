// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DBRestClient.h"
#import "Reachability.h"

@class RecordingInfo;

@interface DropboxUploader : NSObject <DBRestClientDelegate> {
@private
    Reachability* serverReachability;
    DBSession* session;
    DBRestClient* restClient;
    RecordingInfo* uploadingFile;
    BOOL hasFolder;
    BOOL warnedUser;
    UIAlertView* postedAlert;
}

@property (nonatomic, retain) RecordingInfo* uploadingFile;
@property (nonatomic, retain) UIAlertView* postedAlert;

+ (id)createWithSession:(DBSession*)session;

- (id)initWithSession:(DBSession*)session;

- (void)cancelUploads;

@end
