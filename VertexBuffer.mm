//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "AudioSampleBuffer.h"
#import "VertexBuffer.h"

@implementation VertexBuffer

@synthesize vertices, count;

//
// NOTE: this constant should come from the DataCapture component after it connects to Core Audio.
//
static const double kXScale = 1.0 / 44.1e3;
static const int kValuesPerVertex = 2;

+ (id)bufferWithCapacity:(UInt32)theCapacity sampleRate:(Float64)sampleRate
{
    return [[[VertexBuffer alloc] initWithCapacity:theCapacity sampleRate:sampleRate] autorelease];
}

- (id)initWithCapacity:(UInt32)theCapacity sampleRate:(Float64)sampleRate
{
    if ((self = [super init])) {
	//
	// Internally we hold N + 1 vertices, with the first being reserved for the last one from the
	// previous buffer. That way we can properly stitch together buffers using the glDrawArrays()
	// call.
	//
	capacity = theCapacity + 1;
	vertices = new GLfloat[capacity * kValuesPerVertex];

	GLfloat xScale = 1.0 / sampleRate;
	GLfloat* ptr = vertices;
	for (int index = 0; index < capacity; ++index) {
	    *ptr++ = xScale * (index - 1);
	    *ptr++ = 0.0;
	}
		
	[self clear];
    }
    return self;
}

- (void)dealloc
{
    delete [] vertices;
    vertices = 0;
    [super dealloc];
}

- (GLfloat)lastValue
{
    // NOTE: count does not reflect the space held by the reserved vertex.
    return vertices[count * kValuesPerVertex + 1];
}

- (void)clear
{
    vptr = &vertices[ 3 ];
    count = 0;
}

- (void)addSample:(Float32)sample
{
    *vptr = sample;
    vptr += 2;
}

- (GLfloat)drawVerticesJoinedWith:(VertexBuffer*)previousBuffer
{
    //
    // If not the first buffer to draw, copy the last Y value from the previous buffer
    // into the first vertex slot of our buffer, then draw. Otherwise, just draw the
    // data in our vertices.
    //
    if (previousBuffer != nil) {
	vertices[1] = [previousBuffer lastValue];
	glVertexPointer(2, GL_FLOAT, 0, &vertices[0]);
	glDrawArrays(GL_LINE_STRIP, 0, count+1);
		
    }
    else {
	glVertexPointer(2, GL_FLOAT, 0, &vertices[2]);
	glDrawArrays(GL_LINE_STRIP, 0, count);
    }

    return vertices[count * kValuesPerVertex];
}

@end
