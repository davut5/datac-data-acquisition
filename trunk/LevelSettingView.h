//
//  LevelSettingView.h
//  Datac
//
//  Created by Brad Howes on 6/4/11.
//  Copyright 2011 Brad Howes. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LevelSettingView : UILabel {
@private
    NSTimer* hidingTimer;
    NSNumberFormatter* formatter;
}

- (void)hide;

- (void)setName:(NSString*)name value:(Float32)value;

@end
