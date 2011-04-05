// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES1/gl.h>

@class AudioSampleBuffer;

/** Array of OpenGL floats used to communicate vertex coordinates to OpenGL processor.
    The array has a maximum capacity, and a current count value that is set from within
    the processAudioSamples call. Of special note, the first element of the internal
    vertices attribute does not hold new data, but is instead held in reserve to hold
    the Y value of the last vertex of the previously drawn VertexBuffer.
*/
@interface VertexBuffer : NSObject {
@private
    GLfloat* vertices;
    GLfloat* vptr;
    UInt32 count;
    UInt32 capacity;
}

@property(nonatomic,assign,readonly) GLfloat* vertices;
@property(nonatomic,assign) UInt32 count;

/** Class method that allocates and initializes a new VertexBuffer object to hold
    the maximum number of 2-tuple vertices with the X values preset to a monotonically
    increasing sequence of 1/sampleRate values.
*/
+ (id)bufferWithCapacity:(UInt32)capacity sampleRate:(Float64)sampleRate;

/** Initialize new VertexBuffer object to hold the maximum number of 2-tuple vertices 
    with the X values preset to a monotonically increasing sequence of 1/sampleRate values.
*/
- (id)initWithCapacity:(UInt32)capacity sampleRate:(Float64)sampleRate;

- (void)clear;

- (void)addSample:(Float32)sample;

/** Render the vertices held in the buffer. If the given previousBuffer is not
    nil, set up the draw such that the new vertices appear joined to the previous
    ones.
*/
- (GLfloat)drawVerticesJoinedWith:(VertexBuffer*)previousBuffer;

@end
