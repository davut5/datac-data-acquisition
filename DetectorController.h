//
//  DetectorController.h
//  Datac
//
//  Created by Brad Howes on 5/6/11.
//  Copyright 2011 Skype. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/ES1/gl.h>

@class SampleView;

@interface DetectorController : NSObject
{
    SampleView* sampleView;
}

@property (nonatomic, retain) SampleView* sampleView;

- (void)drawOnSampleView:(GLfloat*)vertices;

- (void)handlePanGesture:(UIPanGestureRecognizer*)recognizer;

@end
