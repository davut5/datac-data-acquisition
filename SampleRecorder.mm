//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "RecordingInfo.h"
#import "SampleRecorder.h"

@interface SampleRecorder ()

- (void)updateSize;

@end

@implementation SampleRecorder

@synthesize outputStream, recording;

+ (id)createRecording:(RecordingInfo*)recording
{
    return [[[SampleRecorder alloc] initRecording:recording] autorelease];
}

- (id)initRecording:(RecordingInfo*)theRecording
{
    if (self = [super init]) {
	self.recording = theRecording;
	self.outputStream = [NSOutputStream outputStreamToFileAtPath:recording.filePath append:NO];
	runningSize = 0;
	updateCounter = 0;
	[self.outputStream open];
    }

    return self;
}

- (void)dealloc
{
    [self close];
    [super dealloc];
}

- (void)close
{
    if (outputStream) {
	[outputStream close];
	self.outputStream = nil;
	[recording finalizeSize];
	self.recording = nil;
    }
}

- (void)updateSize
{
    [recording updateSizeWith:runningSize];
}

- (void)write:(const SInt32*)ptr maxLength:(UInt32)count
{
    if (outputStream != nil) {
	count *= sizeof(SInt32);
	[outputStream write:reinterpret_cast<const uint8_t*>(ptr) maxLength:count];
	runningSize += count;
	if (++updateCounter == 100) {
	    updateCounter = 0;
	    [self performSelectorOnMainThread:@selector(updateSize) withObject:nil waitUntilDone:NO];
	}
    }
}

@end
