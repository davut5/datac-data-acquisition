// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DBLoginController.h"
#import "DBSession.h"
#import "IASKAppSettingsViewController.h"

@class AppDelegate;

@interface SettingsViewController : IASKAppSettingsViewController <IASKSettingsDelegate, DBLoginControllerDelegate, 
                                                                    UIActionSheetDelegate> {
@private
    AppDelegate* appDelegate;
    UITableViewCell* dropboxCell;
    DBSession* dropboxSession;
}

@property (nonatomic, retain) UITableViewCell* dropboxCell;

@end
