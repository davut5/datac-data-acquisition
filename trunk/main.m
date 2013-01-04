// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UserSettings.h"

int main(int argc, char *argv[])
{
    //
    // !!! Register default setting values before we do anything else.
    //
    [UserSettings registerDefaults];
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    int retVal = UIApplicationMain(argc, argv, nil, nil);
    [pool release];
    return retVal;
}

