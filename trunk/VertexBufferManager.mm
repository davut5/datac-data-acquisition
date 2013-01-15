// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "DataCapture.h"
#import "SampleView.h"
#import "VertexBuffer.h"
#import "VertexBufferManager.h"

@implementation VertexBufferManager

@synthesize sampleRate, frozen, sampleView, lock, xMin, xMax, yMin, yMax;

+ (id)createForDuration:(Float64)seconds sampleRate:(Float64)sampleRate bufferSize:(UInt32)bufferSize
{
    return [[[VertexBufferManager alloc] initForDuration:seconds sampleRate:sampleRate bufferSize:bufferSize] autorelease];
}

- (id)initForDuration:(Float64)theSeconds sampleRate:(Float64)theSampleRate bufferSize:(UInt32)theBufferSize
{
    if ((self = [super init]) == nil) return nil;

    lock = [[NSLock alloc] init];

    seconds = theSeconds;
    sampleRate = theSampleRate;
    bufferSize = theBufferSize;

    //
    // This is the number of samples shown in an unmagnified (default) view.
    //
    bufferedSampleCount = theSampleRate * theSeconds;

    //
    // This is the number of VectorBuffer objects we need to allocate to fill an unmagnified view.
    //
    capacity = bufferedSampleCount / bufferSize + 1;

    //
    // This is the array that will hold the VectorBuffer objects.
    //
    vertices = [[NSMutableArray alloc] initWithCapacity:capacity];

    frozen = NO;

    self.xMin = 0.0;
    self.xMax = seconds;

    yMin = -1.0;
    yMax = 1.0;

    return self;
}

- (void)dealloc
{
    self.sampleView = nil;
    [vertices release];
    [lock release];
    [super dealloc];
}

- (void)releaseResources
{
    [vertices makeObjectsPerformSelector:@selector(releaseResources)];
}

- (void)addSamples:(Float32 *)samples count:(UInt32)frameSize
{
    if (frozen) return;

    while (frameSize > 0) {
        VertexBuffer* vertexBuffer = nil;
        if (vertices.count < capacity) {
            vertexBuffer = vertices.count ? [vertices objectAtIndex:0] : nil;
            if (vertexBuffer == nil || vertexBuffer.filled) {
                GLfloat lastY = vertexBuffer ? [vertexBuffer lastYValue] : 0.0;
                vertexBuffer = [[[VertexBuffer alloc] initWithCapacity:bufferSize lastY:lastY] autorelease];
                [lock lock];
                [vertices insertObject:vertexBuffer atIndex:0];
                frameSize = [vertexBuffer addSamples:samples count:frameSize];
                [lock unlock];
            }
            else {
                [lock lock];
                frameSize = [vertexBuffer addSamples:samples count:frameSize];
                [lock unlock];
            }
        }
        else {
            vertexBuffer = [vertices objectAtIndex:0];
            if ([vertexBuffer filled]) {
                GLfloat lastY = [vertexBuffer lastYValue];
                vertexBuffer = [vertices lastObject];
                [lock lock];
                [vertices removeLastObject];
                [vertices insertObject:vertexBuffer atIndex:0];
                [vertexBuffer resetWithLastY:lastY];
                frameSize = [vertexBuffer addSamples:samples count:frameSize];
                [lock unlock];
            }
            else {
                [lock lock];
                frameSize = [vertexBuffer addSamples:samples count:frameSize];
                [lock unlock];
            }
        }
    }
}

- (void)setXMin:(GLfloat)value
{
    xMin = (1.0 - value / seconds) * (bufferedSampleCount - 1);
}

- (void)setXMax:(GLfloat)value
{
    xMax = (1.0 - value / seconds) * (bufferedSampleCount - 1);
}

- (void)drawVertices
{
    glPushMatrix();

    //
    // Setup matrices such that we can easily draw sample values from VertexBuffer objects.
    // We want the newest values appearing on the left (those with the biggest X values).
    //
    glLoadIdentity();

    // glOrthof(bufferedSampleCount - 1, 0, -1.0, 1.0, -1.0f, 1.0f);
    glOrthof(xMin, xMax, yMin, yMax, -1.0f, 1.0f);

    GLfloat xPos = bufferedSampleCount - 1;
    GLfloat xOff = bufferedSampleCount - 1;

    [lock lock];
    for (VertexBuffer* vb in vertices) {

        UInt32 count = vb.count;
        glTranslatef(xOff - (count - 1), 0.0, 0.0);
        xOff = 0.0;

        [vb drawVertices];

        xPos -= count - 1;
        if (xPos <= xMax)
            break;
    }

    [lock unlock];

    glPopMatrix();
}

@end
