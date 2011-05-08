//
//  DetectorController.mm
//  Datac
//
//  Created by Brad Howes on 5/6/11.
//  Copyright 2011 Skype. All rights reserved.
//

#import "DetectorController.h"

@implementation DetectorController

@synthesize sampleView;

- (id)init
{
    if (self = [super init]) {
        sampleView = nil;
    }
    
    return self;
}

- (void)dealloc
{
    self.sampleView = nil;
    [super dealloc];
}

- (void)drawOnSampleView:(GLfloat*)vertices
{
}

- (void)handlePanGesture:(UIPanGestureRecognizer*)recognizer
{
}

@end
