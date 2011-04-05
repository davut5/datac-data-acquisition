// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <UIKit/UIKit.h>

@class AppDelegate;

@interface RecordingsViewController : UITableViewController <NSFetchedResultsControllerDelegate> {
@private
    IBOutlet AppDelegate* appDelegate;
    NSString* uploadingFilePath;
}

@property (nonatomic, retain) NSString* uploadingFilePath;

@end
