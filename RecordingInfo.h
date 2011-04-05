// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface RecordingInfo : NSManagedObject {
}

@property (nonatomic, retain) NSString* filePath;
@property (nonatomic, retain) NSString* name;
@property (nonatomic, assign) float progress;
@property (nonatomic, retain) NSString* size;
@property (nonatomic, assign) BOOL uploaded;
@property (nonatomic, assign) BOOL uploading;

+ (NSString*)generateRecordingPath;

+ (NSString*)niceSizeOfFileString:(int)bytes;

- (void)initialize;

- (void)updateSizeWith:(UInt32)size;

- (void)finalizeSize;

@end
