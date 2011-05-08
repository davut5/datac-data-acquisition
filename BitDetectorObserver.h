// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <Foundation/Foundation.h>

/** A protocol for observers interested in BitDetector bit detections.
 */
@protocol BitDetectorObserver
@required

/** Notification sent out when the bit detector find a new bit.
 \param value NSString object representing the bit value ("0" or "1").
 */
- (void)nextBitValue:(NSString*)value;

@end
