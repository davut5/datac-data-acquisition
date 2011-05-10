// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "SampleProcessorProtocol.h"

@class SignalProcessorController;
@class UIViewController;

/** Protocol for objects that perform signal processing on the audio stream. Unlike the SampleProcessorProtocol, this
    one does not interact directly with DataCapture and the audio input samples. However, implementors of this protocol
    must implement the sampleProcessor message which will return an object that implements the SampleProcessorProtocol.
 */
@protocol SignalProcessorProtocol
@required

/** Begin signal processing.
 */
- (void)start;

/** Stop signal processing.
 */
- (void)stop;

/** Reset the signal processor to a known internal state.
 */
- (void)reset;

/** Update the signal processor runtime parameters using settings updated the user, either from the Settings tab in the application or by the iOS Settings application.
 */
- (void)updateFromSettings;

/** Obtain a SignalProcessorController object that the SignalViewController can use show and modify state within the
    signal processor. Implementations must return nil if there is no SignalProcessorController to use.
 */
- (SignalProcessorController*)controller;

/** Obtain a UIViewController object that will update the info overlay view of the SignalViewController. Implementations
    should return nil if there is nothing to display in the info overlay view.
 */
- (UIViewController*)infoOverlayController;

/** Obtain the low-level sample processor that will be used by the DataCapture instance to process raw audio samples.
 */
-  (NSObject<SampleProcessorProtocol>*)sampleProcessor;

@end
