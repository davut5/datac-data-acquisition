// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <vector>

/** Digital low-pass filter, using the direct form II transposed method. The
    tap weights for the filter are provided externally, either in a text file
    resource, or directly in an NSArray. For a file, each line should contain
    just one floating-poin value. For an NSArray, each element should be an
    NSNumber holding a floating-point number.

    Internally, the filter uses 32-bit C 'float' objects.
*/
@interface LowPassFilter : NSObject {
@private
    NSString* fileName;
    std::vector<Float32> B;
    std::vector<Float32> Z;
}

@property (nonatomic, assign) NSString* fileName;

/** Class method that creates a new LowPassFilter object and initializes it
    with the contents of a file.
*/
+ (id)createFromFile:(NSString*)fileName;

/** Class method that creates a new LowPassFilter object and initializes it
    with the contents of the given NSArray object.
*/
+ (id)createFromArray:(NSArray*)taps;

- (id)initFromFile:(NSString *)theFileName;

- (id)initFromArray:(NSArray*)taps;

/** Reset the filter, erasing any held state.
 */
- (void)reset;

/** Filter the given value and return the result.
    \param x the value to filter
 */
- (Float32)filter:(Float32)x;

/** Obtain the number of filter taps
    \return filter taps
 */
- (NSUInteger)size;

- (NSString*)description;

@end
