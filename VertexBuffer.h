// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES1/gl.h>

#import "SampleProcessorProtocol.h"

struct Vertex
{
    Vertex() {}
    Vertex(GLfloat x, GLfloat y) : x_(x), y_(y) {}
    GLfloat x_;
    GLfloat y_;
};

/** Array of OpenGL floats used to communicate vertex coordinates to OpenGL processor.
 */
@interface VertexBuffer : NSObject {
@private
    Vertex* vertices;
    UInt32 count;
    UInt32 capacity;
    GLuint vbo;
    BOOL stale;
}

@property(nonatomic, assign, readonly) Vertex* vertices;
@property(nonatomic, assign, readonly) UInt32 count;

/** Initialize new VertexBuffer object to hold the maximum number of 2-tuple vertices
 with the X values preset to a monotonically increasing sequence of 1/sampleRate values.
 */
- (id)initWithCapacity:(UInt32)capacity lastY:(GLfloat)lastY;

- (void)releaseResources;

- (void)resetWithLastY:(GLfloat)lastY;

- (BOOL)filled;

- (UInt32)addSamples:(Float32 *)samples count:(UInt32)frameSize;

- (void)drawVertices;

- (GLfloat)lastYValue;

@end
