//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "RecordingInfo.h"

NSString* kFileSuffix = @"raw";

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
    NSLog(@"setProgress: %f", value);
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
	return [NSString stringWithFormat: @"%d bytes", bytes];
    else if (bytes<1048576)
	return [NSString stringWithFormat: @"%dKB", (bytes/1024)];
    else
	return [NSString stringWithFormat: @"%.2fMB", ((float)bytes/1048576)];
}

+ (NSString*)generateRecordingPath
{
    NSDateFormatter* dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString* path = [dateFormatter stringFromDate:[NSDate date]];
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsDirectory = [paths objectAtIndex:0];
    path = [NSString stringWithFormat:@"%@/%@.%@", documentsDirectory, path, kFileSuffix];
    NSLog(@"path: %@", path);
    return path;
}

- (void)awakeFromFetch
{
    [super awakeFromFetch];
    self.uploading = NO;
    self.progress = 0.0;
}

- (void)awakeFromInsert
{
    [super awakeFromFetch];
    self.uploading = NO;
    self.progress = 0.0;
}

- (void)initialize
{
    self.filePath = [RecordingInfo generateRecordingPath];
    NSURL* fileUrl = [NSURL fileURLWithPath:self.filePath];
    NSString* name = [fileUrl lastPathComponent];
    NSArray* bits = [name componentsSeparatedByString:@"."];
    self.name = [bits objectAtIndex:0];
    self.size = @"0 bytes";
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
