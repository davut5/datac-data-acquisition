// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* kSettingsSignalDetectorLevelKey;
extern NSString* kSettingsSignalDetectorUpdateRateKey;
extern NSString* kSettingsEnableLowPassFilterKey;
extern NSString* kSettingsTapsFileNameKey;
extern NSString* kSettingsXMinKey;
extern NSString* kSettingsXMaxKey;
extern NSString* kSettingsRPMScaleFactorKey;
extern NSString* kSettingsCounterDecayDurationKey;
extern NSString* kSettingsSignalDisplayUpdateRateKey;
extern NSString* kSettingsSwitchDetectorThresholdKey;
extern NSString* kSettingsSwitchDetectorDurationKey;
extern NSString* kSettingsRpmViewDurationKey;
extern NSString* kSettingsCloudStorageEnableKey;

@interface UserSettings : NSObject
{
}

+ (NSUserDefaults*)registerDefaults;
+ (NSUserDefaults*)validate;
+ (void)validateIntegerNamed:(NSString*)key minValue:(SInt32)minValue maxValue:(SInt32)maxValue;
+ (void)validateFloatNamed:(NSString*)key minValue:(Float32)minValue maxValue:(Float32)maxValue;

@end
