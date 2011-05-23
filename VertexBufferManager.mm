// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "DataCapture.h"
#import "VertexBuffer.h"
#import "VertexBufferManager.h"

@implementation VertexBufferManager

@synthesize frozen;

+ (id)createForDuration:(Float64)seconds sampleRate:(Float64)sampleRate
{
    return [[[VertexBufferManager alloc] initForDuration:seconds sampleRate:sampleRate] autorelease];
}

- (id)initForDuration:(Float64)seconds sampleRate:(Float64)theSampleRate 
{
    if ((self = [super init]) == nil) return nil;

    lock = [[NSLock alloc] init];

    sampleRate = theSampleRate;

    //
    // Number of samples we need before we have everything we need to show the configured duration of
    // audio.
    //
    unallocated = seconds * sampleRate * 2;
    vertexBuffers = [[NSMutableArray alloc] initWithCapacity:unallocated / 512];
    first = 0;
    frozen = NO;

    return self;
}

- (void)dealloc
{
    [vertexBuffers release];
    [lock release];
    [super dealloc];
}

- (VertexBuffer*)getBufferForCount:(UInt32)count
{
    UInt32 pos;
    VertexBuffer* vertexBuffer;

    // 
    // If we have unallocated samples, create a new VertexBuffer object. Otherwise, grab the oldest to
    // write into.
    //
    if (unallocated > 0) {
	vertexBuffer = [[VertexBuffer alloc] initWithCapacity:count sampleRate:sampleRate];
	pos = vertexBuffers.count;
    }
    else {
	pos = first + 1;
	if (pos == vertexBuffers.count)
	    pos = 0;
	vertexBuffer = [vertexBuffers objectAtIndex:pos];
	[vertexBuffer clear];
    }

    //
    // Keep the main thread from using the buffer collection until we are done
    //
    [lock lock];

    if (! frozen) first = pos;

    if (unallocated > 0) {
	[vertexBuffers addObject:vertexBuffer];
	unallocated -= count;
	[vertexBuffer release];
    }
    [lock unlock];

    return vertexBuffer;
}

- (void)drawVerticesStartingAt:(GLfloat)xMin forSpan:(GLfloat)xSpan
{
    //
    // Keep the AudioUnit thread from manipulating the buffer array until we have a 
    // copy. Note that we are copying an array of buffers, not the actual buffer 
    // objects.
    //
    [lock lock];
    NSArray* bufs = [NSArray arrayWithArray:vertexBuffers];
    UInt32 pos = first;
    [lock unlock];
    
    GLfloat xMax = xMin + xSpan;
    xMin = 0.0f;

    //
    // Draw buffers, newest to oldest until we've filled the screen.
    //
    UInt32 count = bufs.count;
    VertexBuffer* previousBuffer = nil;
    for (; count > 0; --count, --pos) {

	VertexBuffer* vertexBuffer = [bufs objectAtIndex:pos];
	if (vertexBuffer.count > 0) {

	    GLfloat span = [vertexBuffer drawVerticesJoinedWith:previousBuffer];
	    xMin += span;
	    if (xMin >= xMax)
		break;

	    //
	    // Shift the OpenGL view over so that the next buffer drawn will appear at the
	    // appropriate location on the screen.
	    //
	    glTranslatef(span, 0.0f, 0.0f);
	    previousBuffer = vertexBuffer;
	}

	if (pos == 0)
	    pos = bufs.count;
    }
}

@end
