// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "RecordingInfo.h"
#import "UserSettings.h"

@interface RecordingInfo (PrimitiveAccessors)

- (NSNumber*)primitiveProgress;
- (void)setPrimitiveProgress:(NSNumber*)value;

- (NSNumber*)primitiveUploaded;
- (void)setPrimitiveUploaded:(NSNumber*)value;

- (NSNumber*)primitiveUploading;
- (void)setPrimitiveUploading:(NSNumber*)value;

@end

@implementation RecordingInfo

@dynamic filePath;
@dynamic name;
@dynamic progress;
@dynamic size;
@dynamic uploaded;
@dynamic uploading;

- (float)progress 
{
    NSNumber* tmpValue;
    [self willAccessValueForKey:@"progress"];
    tmpValue = [self primitiveProgress];
    [self didAccessValueForKey:@"progress"];
    return [tmpValue floatValue];
}

- (void)setProgress:(float)value 
{
    [self willChangeValueForKey:@"progress"];
    [self setPrimitiveProgress:[NSNumber numberWithFloat:value]];
    [self didChangeValueForKey:@"progress"];
}

- (BOOL)uploaded 
{
    NSNumber* tmpValue;
    [self willAccessValueForKey:@"uploaded"];
    tmpValue = [self primitiveUploaded];
    [self didAccessValueForKey:@"uploaded"];
    return [tmpValue boolValue];
}

- (void)setUploaded:(BOOL)value 
{
    [self willChangeValueForKey:@"uploaded"];
    [self setPrimitiveUploaded:[NSNumber numberWithBool:value]];
    [self didChangeValueForKey:@"uploaded"];
}

- (BOOL)uploading 
{
    NSNumber* tmpValue;
    [self willAccessValueForKey:@"uploading"];
    tmpValue = [self primitiveUploading];
    [self didAccessValueForKey:@"uploading"];
    return [tmpValue boolValue];
}

- (void)setUploading:(BOOL)value 
{
    [self willChangeValueForKey:@"uploading"];
    [self setPrimitiveUploading:[NSNumber numberWithBool:value]];
    [self didChangeValueForKey:@"uploading"];
}

+ (NSString*)niceSizeOfFileString:(int)bytes
{
    if (bytes<1024)
	return [NSString stringWithFormat: NSLocalizedString(@"%d bytes", "@Format for size in bytes"), bytes];
    else if (bytes<1048576)
	return [NSString stringWithFormat: NSLocalizedString(@"%dKB", "@Format for size in kilobytes"), (bytes/1024)];
    else
	return [NSString stringWithFormat: NSLocalizedString(@"%.2fMB", @"Format for size in megabytes"),
                ((float)bytes/1048576)];
}

static AudioFileTypeID currentAudioFileType;

+ (NSString*)generateRecordingPath
{
    NSString* suffix = [[NSUserDefaults standardUserDefaults] stringForKey:kSettingsRecordingsFileFormatKey];
    if ([suffix isEqualToString:@"caf"] == YES) {
        currentAudioFileType = kAudioFileCAFType;
    }
    else if ([suffix isEqualToString:@"wav"] == YES) {
        currentAudioFileType = kAudioFileWAVEType;
    }
    else if ([suffix isEqualToString:@"aiff"] == YES) {
        currentAudioFileType = kAudioFileAIFFType;
    }

    NSDateFormatter* dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];

    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsDirectory = [paths objectAtIndex:0];
    NSString* path = [documentsDirectory stringByAppendingPathComponent:NSLocalizedString(@"Recordings",
                                                                                          @"Recordings directory")];
    NSFileManager* fileManager = [[[NSFileManager alloc] init] autorelease];
    if ([fileManager fileExistsAtPath:path] == NO) {
        NSError* err = nil;
        if ([fileManager createDirectoryAtPath:path
                   withIntermediateDirectories:YES
                                    attributes:nil
                                         error:&err] == NO) {;
            NSLog(@"RecordingInfo.generateRecordingPath: failed to create Recordings directory! - %@", err);
            path = [path stringByDeletingLastPathComponent];
        }
    }

    NSString* name = [[dateFormatter stringFromDate:[NSDate date]] stringByAppendingPathExtension:suffix];
    path = [path stringByAppendingPathComponent:name];

    return path;
}

+ (AudioFileTypeID)getCurrentAudioFileType
{
    return currentAudioFileType;
}

- (void)awakeFromFetch
{
    [super awakeFromFetch];
    
    //
    // Uploading state is temporary and is always reset when reloaded.
    //
    if ([[self primitiveUploading] boolValue] == YES) {
        NSLog(@"RecordingInfo.awakeFromFetch: resetting self.uploading");
        self.uploading = NO;
    }
    if ([[self primitiveProgress] floatValue] != 0.0) {
        NSLog(@"RecordingInfo.awakeFromFetch: resetting self.progress");
        self.progress = 0.0;
    }
}

- (void)initialize
{
    NSString* path = [RecordingInfo generateRecordingPath];
    self.filePath = path;
    NSURL* fileUrl = [NSURL fileURLWithPath:path];
    self.name = [[fileUrl lastPathComponent] stringByDeletingPathExtension];
    self.size = [RecordingInfo niceSizeOfFileString:0];
    self.uploaded = NO;
    self.uploading = NO;
    self.progress = 0.0;
}

- (void)updateSizeWith:(UInt32)size
{
    self.size = [RecordingInfo niceSizeOfFileString:size];
}

- (void)finalizeSize
{
    NSString* path = self.filePath;
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSError* err;
    NSDictionary* attr = [fileManager attributesOfItemAtPath:path error:&err];
    self.size = [RecordingInfo niceSizeOfFileString:attr.fileSize];
}

@end
