// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "BitStreamFrameDetector.h"
#import "UserSettings.h"

@implementation BitStreamFrameDetector

@synthesize bits, contentSize, frameContents, observer, prefix, suffix;

+ (id)create
{
    return [[[BitStreamFrameDetector alloc] init] autorelease];
}

- (void)makeBits
{
    if (bits == nil || [bits length] != frameSize) {
        [bits release];
        bits = [[NSMutableString stringWithCapacity:frameSize] retain];
    }
}

- (id)init
{
    if (self = [super init]) {
        frameContents = nil;
        observer = nil;
        [self updateFromSettings];
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

- (void)reset
{
    [bits setString:@""];
    if (frameContents != nil) {
        [frameContents release];
        frameContents = nil;
    }
}

- (void)updateFromSettings
{
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    prefix = [[settings stringForKey:kSettingsBitStreamFrameDetectorPrefixKey] retain];
    suffix = [[settings stringForKey:kSettingsBitStreamFrameDetectorSuffixKey] retain];
    contentSize = [settings integerForKey:kSettingsBitStreamFrameDetectorContentSizeKey];
    frameSize = contentSize + [prefix length] + [suffix length];
    [self makeBits];
}

- (void)setPrefix:(NSString*)value
{
    frameSize += ([value length] - [prefix length]);
    [prefix release];
    prefix = [value retain];
    [self makeBits];
}

- (void)setSuffix:(NSString*)value
{
    frameSize += ([value length] - [suffix length]);
    [suffix release];
    suffix = [value retain];
    [self makeBits];
}

- (void)setContentSize:(NSUInteger)value
{
    frameSize += (value - contentSize);
    contentSize = value;
    [self makeBits];
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
            [frameContents release];
            frameContents = [[bits substringWithRange:NSMakeRange([prefix length], contentSize)] retain];
            if (observer != nil) {
                [observer frameContentBitStream:frameContents];
            }

            //
            // Clear out the bit accumulator since we used everything.
            //
            [bits deleteCharactersInRange:NSMakeRange(0, frameSize)];
        }
        else {

            //
            // We did not match. Locate the next match for prefix and start from there. If not found, start dropping 
            // bits from the end of the prefix and look for a match at the end of the string.
            //
            NSRange found = [bits rangeOfString:prefix options:NSLiteralSearch range:NSMakeRange(1, frameSize-1)];
            if (found.location != NSNotFound) {
                [bits deleteCharactersInRange:NSMakeRange(0, found.location)];
            }
            else {
                NSMutableString* tag = [NSMutableString stringWithString:
                                        [prefix substringWithRange:NSMakeRange(0, [prefix length] - 1)]];
                while ([tag length] > 0) {
                    if ([bits hasSuffix:tag]) {
                        [bits release];
                        bits = [tag retain];
                        break;
                    }
                    [tag deleteCharactersInRange:NSMakeRange(0, 1)];
                }
                
                //
                // No match above. Forget everything we've seen in the past.
                //
                if ([tag length] == 0) {
                    [bits setString:@""];
                }
            }
        }
    }
}

@end
