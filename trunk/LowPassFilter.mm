// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <iterator>
#import <sstream>

#import "LowPassFilter.h"

@interface LowPassFilter ()

- (void)loadFile:(NSString *)path;

@end

@implementation LowPassFilter

@synthesize fileName;

- (void)setFileName:(NSString *)theFileName
{
    B.clear();
    Z.clear();
    
    if (fileName != nil) {
        [fileName autorelease];
        fileName = nil;
    }
    
    if (theFileName == nil) return;
    
    NSString* extension = [theFileName pathExtension];
    if ([extension length] == 0) {
        extension = @"txt";
    }
    
    NSString* baseName = [theFileName stringByDeletingPathExtension];
    
    //
    // Locate the file to read. First, look in the user directory inside the 'Filters' folder.
    //
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsDirectory = [paths objectAtIndex:0];
    NSString* path = [documentsDirectory stringByAppendingPathComponent:NSLocalizedString(@"Filters",
                                                                                          @"Filters directory")];
    NSFileManager* fileManager = [[[NSFileManager alloc] init] autorelease];
    if ([fileManager fileExistsAtPath:path] == NO) {
        NSError* err = nil;
        if ([fileManager createDirectoryAtPath:path
                   withIntermediateDirectories:YES
                                    attributes:nil
                                         error:&err] == NO) {
            LOG(@"LowPassFilter.setFileName: failed to create Filters directory - %@", err);
            path = [path stringByDeletingLastPathComponent];
        }
    }
    
    path = [path stringByAppendingPathComponent:baseName];
    path = [path stringByAppendingPathExtension:extension];
    if ([fileManager fileExistsAtPath:path] == YES) {
        [self loadFile:path];
        fileName = [theFileName retain];
        return;
    }
    
    //
    // Attempt to locate the file in the application bundle.
    //
    NSBundle* bundle = [NSBundle mainBundle];
    path = [bundle pathForResource:baseName ofType:extension];
    if (path != nil) {
        [self loadFile:path];
        fileName = [theFileName retain];
        return;
    }
    
    LOG(@"did not find resource file '%@.%@'", baseName, extension);
}

+ (id)createFromFile:(NSString *)theFileName
{
    return [[[LowPassFilter alloc] initFromFile:theFileName] autorelease];
}

+ (id)createFromArray:(NSArray *)array
{
    return [[[LowPassFilter alloc] initFromArray:array] autorelease];
}

- (id)initFromFile:(NSString*)theFileName
{
    self = [super init];
    if (self == nil) return self;
    fileName = nil;
    self.fileName = theFileName;
    return self;
}

- (id)initFromArray:(NSArray*)taps
{
    self = [super init];
    if (self == nil) return self;
    fileName = nil;
    if (taps == nil) {
        @throw [NSException exceptionWithName:@"NullTaps" reason:@"" userInfo:nil];
    }
    
    for (NSNumber* obj in taps) {
        B.push_back([obj floatValue]);
        Z.push_back(0.0);
    }
    
    return self;
}

- (void)dealloc
{
    self.fileName = nil;
    B.clear();
    Z.clear();
    [super dealloc];
}

- (void)reset
{
    for (UInt32 index = 0; index < Z.size(); ++index)
        Z[index] = 0.0;
}

- (Float32)filter:(Float32)x
{
    if (Z.size() == 0) return x;
    
    Float32 y = B[0] * x + Z[0];
    
    //
    // Update difference equation weights.
    //
    UInt32 tapIndex = 1;
    for (; tapIndex < Z.size(); ++tapIndex) {
        Z[tapIndex - 1] = B[tapIndex] * x + Z[tapIndex];
    }
    
    return y;
}

- (NSUInteger)size
{
    return Z.size();
}

- (NSString*)description
{
    std::ostringstream os;
    std::copy(Z.begin(), Z.end(), std::ostream_iterator<Float32>(os, ", "));
    std::string s(os.str());
    return [NSString stringWithCString:s.c_str() encoding:[NSString defaultCStringEncoding]];
}

- (void)loadFile:(NSString*)path
{
    LOG(@"LowPassFilter.loadFile: loading file '%@'", path);
    
    //
    // Read the contents of the file. The format should be one tap weight per line.
    //
    NSError* error;
    NSString* contents = [NSString stringWithContentsOfFile:path encoding:NSUnicodeStringEncoding error: &error];
    if (contents == nil) {
        LOG(@"failed to read contents of file '%@'", path);
        return;
    }
    
    //
    // Create a scanner to convert the text values into floating-point numbers.
    //
    NSScanner* scanner = [NSScanner scannerWithString:contents];
    NSDecimal tap;
    NSMutableArray* taps = [NSMutableArray arrayWithCapacity:32];
    while ([scanner scanDecimal:&tap]) {
        [taps addObject:[NSDecimalNumber decimalNumberWithDecimal:tap]];
    }
    
    LOG(@"num taps: %d", [taps count]);
    
    for (NSDecimalNumber* obj in taps) {
        B.push_back([obj floatValue]);
        LOG(@"B[%lu]: %f", B.size()-1, B.back());
        Z.push_back(0.0);
    }
}

@end
