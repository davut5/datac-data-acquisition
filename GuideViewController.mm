// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "GuideViewController.h"

@implementation GuideViewController
@synthesize url;

- (void)viewDidLoad
{
    NSString* file = @"guide.html";
    NSString* path = [[NSBundle mainBundle] pathForResource:[file stringByDeletingPathExtension] 
                                                     ofType:[file pathExtension]];
    self.url = [NSURL fileURLWithPath:path];
    [super viewDidLoad];
}

- (void)dealloc
{
    self.url = nil;
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
    [webView loadRequest:[NSURLRequest requestWithURL:self.url]];
}

- (void)viewDidUnload {
    self.url = nil;
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

@end
