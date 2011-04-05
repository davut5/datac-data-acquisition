//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "AudioSampleBuffer.h"
#import "LowPassFilter.h"

@implementation LowPassFilter

@synthesize fileName;

- (void)setFileName:(NSString *)theFileName
{
    numTaps = 0;
    delete [] B;
    delete [] Z;
    B = nil;
    Z = nil;
	
    fileName = [theFileName retain];

    //
    // Locate the file to read that contains the filter tap weights.
    //
    NSBundle* bundle = [NSBundle mainBundle];
    NSString* path = [bundle pathForResource:fileName ofType:@"txt"];
    if (path == nil) {
	NSLog(@"did not find resource file '%@.txt'", fileName);
	return;
    }

    //
    // Read the contents of the file. The format should be one tap weight per line.
    //
    NSError* error;
    NSString* contents = [NSString stringWithContentsOfFile:path encoding:NSUnicodeStringEncoding error: &error];
    if (contents == nil) {
	NSLog(@"failed to read contents of file '%@'", path);
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

    NSLog(@"num taps: %d", [taps count]);

    //
    // Initialize filter using loaded weight values.
    //
    if (numTaps != [taps count]) {
	numTaps = [taps count];
	delete [] B;
	delete [] Z;
	B = new Float32[numTaps];
	Z = new Float32[numTaps];
    }

    for (UInt32 index = 0; index < numTaps; ++index) {
	B[ index ] = [[taps objectAtIndex:index] floatValue];
	NSLog(@"B[%d]: %f", index, B[index]);
	Z[ index ] = 0.0;
    }
}

+ (id)createFromFile:(NSString *)fileName
{
    return [[[LowPassFilter alloc] initFromFile: fileName] autorelease];
}

+ (id)createFromArray:(NSArray *)array
{
    return [[[LowPassFilter alloc] initFromArray:array] autorelease];
}

- (id)initFromFile:(NSString*)theFileName
{
    self = [super init];
    if (self == nil) return self;
    self.fileName = theFileName;
    return self;
}

- (id)initFromArray:(NSArray*)taps
{
    self = [super init];
    if (self == nil) return self;
    numTaps = [taps count];
    B = nil;
    Z = nil;
    if (numTaps > 0) {
	B = new Float32[numTaps];
	Z = new Float32[numTaps];
	for (UInt32 index = 0; index < numTaps; ++index) {
	    NSNumber* tap = [taps objectAtIndex:index];
	    B[index] = [tap floatValue];
	    Z[index] = 0.0;
	}
    }
    return self;
}

- (void)dealloc
{
    delete [] B;
    delete [] Z;
    [super dealloc];
}

- (void)reset
{
    for (UInt32 index = 0; index < numTaps; ++index)
	Z[index] = 0.0;
}

- (Float32)filter:(Float32)x
{
    if (numTaps == 0) return x;

    Float32 y = fabs(B[ 0 ] * x + Z[ 0 ]);

    //
    // Update difference equation weights.
    //
    UInt32 tapIndex = 1;
    for (; tapIndex < numTaps - 1; ++tapIndex) {
	Z[tapIndex - 1] = B[tapIndex] * x + Z[tapIndex];
    }
    Z[tapIndex - 1] = B[tapIndex] * x;

    return y;
}

@end
