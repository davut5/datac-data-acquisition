// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IASKAppSettingsViewController.h"

@class AppDelegate;

@interface SettingsViewController : IASKAppSettingsViewController <IASKSettingsDelegate, UIActionSheetDelegate> {
@private
    AppDelegate* appDelegate;
    UITableViewCell* dropboxCell;
}

@property (nonatomic, retain) UITableViewCell* dropboxCell;

@end
