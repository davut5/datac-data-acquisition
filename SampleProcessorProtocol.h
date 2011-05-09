// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <UIKit/UIKit.h>

/** Protocol for objects that operate on a stream of raw audio samples. Note that the addSamples:count: message defined
    in the protocol will execute in an audio thread, not in the main one. Care must be taken to not update UI objects
    from within this message (eg via NSNotificationCenter messaging)
 */

@protocol SampleProcessorProtocol
@required

/** Process a stream of raw audio samples.
    \param sample pointer to the first audio sample to processes
    \param count the number of samples available to process
 */
- (void)addSamples:(Float32*)sample count:(UInt32)count;

@end
