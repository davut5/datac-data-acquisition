// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "VertexBuffer.h"

@implementation VertexBuffer

@synthesize vertices, count;

static const int kValuesPerVertex = 2;

- (id)initWithCapacity:(UInt32)theCapacity lastY:(GLfloat)lastY
{
    if ((self = [super init])) {

        //
        // Internally we hold N + 1 vertices, with the first being reserved for the last Y value from the
        // previous buffer. That way we can properly stitch together buffers using the glDrawArrays()
        // and a proper glTranslate() call.
        //
        capacity = theCapacity + 1;
        vertices = new Vertex[capacity];
        Vertex* vptr = vertices;
        *vptr++ = Vertex(0, lastY);
        for (UInt32 i = 1; i < capacity; ++i) {
            *vptr++ = Vertex(i, 0.0);
        }
        vbo = 0;
        count = 1;
        stale = YES;
    }

    return self;
}

- (void)dealloc
{
    delete [] vertices;
    vertices = 0;
    [super dealloc];
}

- (GLfloat)lastYValue;
{
    return vertices[count - 1].y_;
}

- (void)resetWithLastY:(GLfloat)lastY
{
    count = 1;
    vertices[0].y_ = lastY;
    stale = vbo == 0;
}

- (BOOL)filled
{
    return capacity == count;
}

- (void)releaseResources
{
    if (vbo != 0) {
        glDeleteBuffers(1, &vbo);
        vbo = 0;
    }
}

- (UInt32)addSamples:(Float32*)ptr count:(UInt32)numSamples
{
    //
    // Add samples to the buffer until we are full. Newer values appear at the end with higher X values.
    //
    Vertex* vptr = vertices + count;
    for (; numSamples > 0 && count < capacity; --numSamples, ++count) {
        vptr++->y_ = *ptr++;
    }

    stale = YES;
    return numSamples;
}

- (void)drawVertices
{
    if (stale == YES) {
        stale = NO;

        //
        // Create a VBO for our samples.
        //
        if (vbo == 0) {
            glGenBuffers(1, &vbo);
        }

        //
        // Use our VBO and copy samples into it.
        //
        glBindBuffer(GL_ARRAY_BUFFER, vbo);
        glBufferData(GL_ARRAY_BUFFER, count * sizeof(Vertex), vertices, GL_DYNAMIC_DRAW);
    }
    else {
        glBindBuffer(GL_ARRAY_BUFFER, vbo);
    }

    //
    // Use our VBO and draw its contents.
    //
    glVertexPointer(2, GL_FLOAT, 0, 0);
    glDrawArrays(GL_LINE_STRIP, 0, count);
}

@end
