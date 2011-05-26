// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <UIKit/UIKit.h>

/** A protocol for obervers interested in new bit frame detections.
 */
@protocol BitStreamFrameDetectorObserver
@required

/** Notifcation sent out when the BitStreamFrameDetector finds a new valid frame.
 \param bits the stream of bits that define the frame.
 */
- (void)frameContentBitStream:(NSString*)bits;

@end

