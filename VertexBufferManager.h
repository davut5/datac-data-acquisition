// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "DataCapture.h"

@class AudioSampleBuffer;
@class VertexBuffer;

/** Collection of one or more VertexBuffer objects that hold past audio samples for display
    in an OpenGL window. The manager will contain enough buffers to represent a configurable number of
    seconds of audio samples at a given sample rate. It allocates new VertexBuffer objects until the
    configured duration is met, at which point it begins to overwrite the oldest buffers with newer
    data
*/
@interface VertexBufferManager : NSObject {
@private
    NSMutableArray* vertexBuffers;
    NSLock* lock;
    UInt32 first;
    SInt32 unallocated;
    Float64 sampleRate;
    BOOL frozen;
}

@property (nonatomic, assign) BOOL frozen;

/** Class method that creates a new VertexBufferManager object for a given number of seconds duration
    at a given audio sample rate.
*/
+ (id)createForDuration:(Float64)seconds sampleRate:(Float64)sampleRate;

/** Initialize new VertexBufferManager instance. 
 */
- (id)initForDuration:(Float64)seconds sampleRate:(Float64)sampleRate;

- (VertexBuffer*)getBufferForCount:(UInt32)count;

/** Draw the current vertex data, starting with the most-recent on the left-hand side of the display, visiting
    VertexBuffer objects until it completely redraws the view.
*/
- (void)drawVerticesStartingAt:(GLfloat)offset forSpan:(GLfloat)span;

@end
