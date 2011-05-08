// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

@class DetectorController;

@protocol SampleProcessorProtocol
@optional

- (void)start;

- (void)stop;

- (void)reset;

- (void)updateFromSettings;

- (DetectorController*)controller;

@required

- (void)addSamples:(Float32*)sample count:(UInt32)count;

@end
