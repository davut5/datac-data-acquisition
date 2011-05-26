// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <UIKit/UIKit.h>

/** A protocol for observers interested in frame decoding.
 */
@protocol BitFrameDecoderObserver
@required

/** Notification sent out when the bit frame decoder finds a valid message frame.
 \param buttonState the current button state from the external device (8 bits)
 \param frequency the current frequency (RPM) reported by the external device (16 bits)
 */
- (void)frameButtonState:(NSInteger)buttonState frequency:(NSInteger)frequency;

@end
