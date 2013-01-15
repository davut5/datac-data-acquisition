// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SampleProcessorProtocol.h"

@class SampleView;
@class VertexBuffer;

/** Collection of one or more VertexBuffer objects that hold past audio samples for display
 in an OpenGL window. The manager will contain enough buffers to represent a configurable number of
 seconds of audio samples at a given sample rate. It allocates new VertexBuffer objects until the
 configured duration is met, at which point it begins to overwrite the oldest buffers with newer
 data
 */
@interface VertexBufferManager : NSObject<SampleProcessorProtocol> {
@private
    NSMutableArray* vertices;
    UInt32 capacity;
    NSLock* lock;
    Float64 seconds;
    Float64 sampleRate;
    UInt32 bufferSize;
    SampleView* sampleView;
    GLfloat bufferedSampleCount;
    GLfloat xMin;
    GLfloat xMax;
    GLfloat yMin;
    GLfloat yMax;
    BOOL frozen;
}

@property (nonatomic, retain) NSLock* lock;
@property (nonatomic, assign) Float64 sampleRate;
@property (nonatomic, assign) BOOL frozen;
@property (nonatomic, retain) SampleView* sampleView;
@property (nonatomic, assign) GLfloat xMin;
@property (nonatomic, assign) GLfloat xMax;
@property (nonatomic, assign) GLfloat yMin;
@property (nonatomic, assign) GLfloat yMax;

/** Class method that creates a new VertexBufferManager object for a given number of seconds duration
 at a given audio sample rate.
 */
+ (id)createForDuration:(Float64)seconds sampleRate:(Float64)sampleRate bufferSize:(UInt32)bufferSize;

/** Initialize new VertexBufferManager instance.
 */
- (id)initForDuration:(Float64)seconds sampleRate:(Float64)sampleRate bufferSize:(UInt32)bufferSize;

- (void)drawVertices;

- (void)releaseResources;

@end
