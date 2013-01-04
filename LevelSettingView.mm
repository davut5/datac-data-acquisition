//
//  LevelSettingView.mm
//  Datac
//
//  Created by Brad Howes on 6/4/11.
//  Copyright 2011 Brad Howes. All rights reserved.
//

#import "LevelSettingView.h"

@interface LevelSettingView (Private)

- (void)makeFormatter;
- (void)fadeView;
- (void)hideView;

@end

@implementation LevelSettingView

- (void)dealloc {
    [hidingTimer invalidate];
    [hidingTimer release];
    [formatter release];
    [super dealloc];
}

- (void)makeFormatter
{
    formatter = [[NSNumberFormatter alloc] init];
    [formatter setLocale:[NSLocale currentLocale]];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [formatter setMaximumSignificantDigits:5];
    [formatter setUsesSignificantDigits:YES];
}

- (void)fadeView
{
    [hidingTimer release];
    hidingTimer = nil;
    [formatter release];
    formatter = nil;
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.40];
    self.alpha = 0.0;
    [UIView setAnimationDidStopSelector:@selector(hideView)];
    [UIView commitAnimations];
}

- (void)hideView
{
    self.hidden = YES;
}

- (void)setName:(NSString*)name value:(Float32)value
{
    if (formatter == nil) [self makeFormatter];
    
    self.text = [NSString stringWithFormat:@"%@\n%@", name,
                 [formatter stringFromNumber:[NSNumber numberWithFloat:value]], nil];
    self.hidden = NO;
    self.alpha = 1.0;
    
    if (hidingTimer != nil) {
        [hidingTimer invalidate];
        [hidingTimer release];
    }
    
    hidingTimer = [[NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(fadeView)
                                                  userInfo:nil repeats:NO] retain];
}

- (void)fillRoundedRect:(CGRect)rect inContext:(CGContextRef)context
{
    float radius = 5.0f;
    CGContextBeginPath(context);
    CGContextSetGrayFillColor(context, 0.2, 0.7);
    CGContextMoveToPoint(context, CGRectGetMinX(rect) + radius, CGRectGetMinY(rect));
    CGContextAddArc(context, CGRectGetMaxX(rect) - radius, CGRectGetMinY(rect) + radius, radius, 3 * M_PI / 2, 0, 0);
    CGContextAddArc(context, CGRectGetMaxX(rect) - radius, CGRectGetMaxY(rect) - radius, radius, 0, M_PI / 2, 0);
    CGContextAddArc(context, CGRectGetMinX(rect) + radius, CGRectGetMaxY(rect) - radius, radius, M_PI / 2, M_PI, 0);
    CGContextAddArc(context, CGRectGetMinX(rect) + radius, CGRectGetMinY(rect) + radius, radius, M_PI, 3 * M_PI / 2, 0);
    CGContextClosePath(context);
    CGContextFillPath(context);
}

- (void)drawRect:(CGRect)rect
{
    CGRect boxRect = self.bounds;
    CGContextRef ctxt = UIGraphicsGetCurrentContext();
    boxRect = CGRectInset(boxRect, 1.0f, 1.0f);
    [self fillRoundedRect:boxRect inContext:ctxt];
    [super drawRect:rect];
}

- (void)hide
{
    if (! self.hidden) {
        self.hidden = YES;
    }
}

@end
