// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "IndicatorButton.h"
#import "IndicatorLight.h"

@implementation IndicatorButton

@synthesize light, label;

- (void)setOn:(BOOL)value
{
    self.light.illuminated = value;
}

- (BOOL)on
{
    return self.light.illuminated;
}

- (void)dealloc {
    [light release];
    [label release];
    [super dealloc];
}

- (NSTimeInterval)blinkingInterval
{
    return light.blinkingInterval;
}

- (void)setBlinkingInterval:(NSTimeInterval)interval
{
    light.blinkingInterval = interval;
}

@end

#if 0

- (void)drawRect:(CGRect)rect
{
    if (self.enabled == NO) return;

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetShouldAntialias(context, true);
    CGContextSetAllowsAntialiasing(context, true);

    const CGFloat lineWidth = 1.5;
    rect = CGRectInset(self.bounds, lineWidth / 2.0f, lineWidth / 2.0f);

    CGContextSetLineWidth(context, lineWidth);
    CGContextSetLineJoin(context, kCGLineJoinMiter);
    CGContextSetLineCap(context, kCGLineCapRound);

    const CGFloat cornerRad = 6.0f;

    CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();

    // CGColorRef color = CGColorCreate(rgb, (CGFloat[]){ 1.f, .5f, .0f, 1.f }); // orange
    // CGColorRef color = CGColorCreate(rgb, (CGFloat[]){ .2f, .2f, .2f, 1.f }); // dark grey
    // CGColorRef color = CGColorCreate(rgb, (CGFloat[]){ .3f, .3f, .3f, 1.f }); // dark grey
    CGColorRef color = CGColorCreate(rgb, (CGFloat[]){ .0f, 1.f, 1.f, .5f }); // cyan
    CGContextSetStrokeColorWithColor(context, color);
    CGColorRelease(color);

    CGColorSpaceRelease(rgb);

    CGContextBeginPath(context);

    // Top Left
    CGContextMoveToPoint(context, rect.origin.x, cornerRad);
    CGContextAddArcToPoint(context, rect.origin.x, rect.origin.y, rect.origin.x + cornerRad, rect.origin.y, cornerRad);
    // Top right
    CGContextAddArcToPoint(context, rect.origin.x + rect.size.width, rect.origin.y, rect.origin.x + rect.size.width,
                           rect.origin.x + cornerRad, cornerRad);
    // Bottom right
    CGContextAddArcToPoint(context, rect.origin.x + rect.size.width, rect.origin.y + rect.size.height,
                           rect.origin.x + rect.size.width - cornerRad, rect.origin.y + rect.size.height, cornerRad);
    // Bottom left
    CGContextAddArcToPoint(context, rect.origin.x, rect.origin.y + rect.size.height, rect.origin.x, rect.origin.y,
                           cornerRad);

    CGContextClosePath(context);

    CGContextDrawPath(context, kCGPathStroke);
}

@implementation IndicatorButton

@synthesize light, label;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
//        UIImage* image = [UIImage imageNamed:@"BlackPushButton.png"];
//        image = [image stretchableImageWithLeftCapWidth:15 topCapHeight:0];
//        background = [[UIImageView alloc] initWithImage:image];
//        [self insertSubview:background atIndex:0];
//        background.frame = self.bounds;
    }
    
    return self;
}

- (void)setOn:(BOOL)value
{
    self.light.illuminated = value;
}

- (BOOL)on
{
    return self.light.illuminated;
}

- (void)dealloc {
    [light release];
    [label release];
    [super dealloc];
}

- (NSTimeInterval)blinkingInterval
{
    return light.blinkingInterval;
}

- (void)setBlinkingInterval:(NSTimeInterval)interval
{
    light.blinkingInterval = interval;
}

@end

#endif

