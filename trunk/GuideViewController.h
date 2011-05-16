//
//  GuideViewController.h
//  Datac
//
//  Created by Brad Howes on 5/11/11.
//  Copyright 2011 Brad Howes. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GuideViewController : UIViewController {
    NSURL* url;
    IBOutlet UIWebView* webView;
}

@property (nonatomic, retain) NSURL* url;

@end
