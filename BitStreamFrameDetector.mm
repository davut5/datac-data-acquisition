//
//  BitStreamFrameDetector.mm
//  Datac
//
//  Created by Brad Howes on 4/15/11.
//  Copyright 2011 Skype. All rights reserved.
//

// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "BitDetector.h"
#import "BitStreamFrameDetector.h"

@implementation BitStreamFrameDetector

@synthesize bits, frameSize, contentSize, frameContents, observer;

+ (id)createWithFrameSize:(NSUInteger)size framePrefix:(NSString*)prefix frameSuffix:(NSString*)suffix
{
    return [[[BitStreamFrameDetector alloc] initWithFrameSize:size framePrefix:prefix frameSuffix:suffix] autorelease];
}

- (id)initWithFrameSize:(NSUInteger)theFrameSize framePrefix:(NSString*)thePrefix frameSuffix:(NSString*)theSuffix
{
    if (self = [super init]) {
        bits = [[NSMutableString stringWithCapacity:theFrameSize] retain];
        prefix = [thePrefix retain];
        suffix = [theSuffix retain];
        frameSize = theFrameSize;
        contentSize = theFrameSize - [prefix length] - [suffix length];
        frameContents = nil;
        observer = nil;
    }
    return self;
}

- (void)dealloc
{
    [bits release];
    [prefix release];
    [suffix release];
    [frameContents release];
    self.observer = nil;
    [super dealloc];
}

- (void)nextBitValue:(NSString*)bitValue
{
    [bits appendString:bitValue];
    if ([bits length] == frameSize) {
        if ([bits hasPrefix:prefix] && [bits hasSuffix:suffix]) {

            //
            // Extract and save the contents of the frame. Alert observer of new frame contents.
            //
            NSLog(@"BitStreamFrameDetector: matched frame: %@", bits);
            frameContents = [[bits substringWithRange:NSMakeRange([prefix length], contentSize)] retain];
            if (observer != nil) {
                [observer frameContentBitStream:self.frameContents];
            }

            //
            // Clear out the bit accumulator since we used everything.
            //
            [bits replaceCharactersInRange:NSMakeRange(0, frameSize) withString:@""];
        }
        else {

            //
            // We did not match. Locate the next match for prefix and start from there. If not found, then we will clear
            // out the accumulator and start from scratch.
            //
            NSRange found = [bits rangeOfString:prefix options:NSLiteralSearch range:NSMakeRange(1, frameSize-1)];
            if (found.location == NSNotFound) {
                found.location = frameSize;
            }
            [bits replaceCharactersInRange:NSMakeRange(0, found.location) withString:@""];
        }
    }
}

@end
