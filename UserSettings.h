// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* kSettingsInputViewUpdateRateKey;
extern NSString* kSettingsInputViewXMinKey;
extern NSString* kSettingsInputViewXMaxKey;

extern NSString* kSettingsDetectionsViewDurationKey;
extern NSString* kSettingsDetectionsViewUpdateRateKey;

extern NSString* kSettingsLevelDetectorLevelKey;
extern NSString* kSettingsLevelDetectorUseLowPassFilterKey;
extern NSString* kSettingsLevelDetectorLowPassFilterFileNameKey;
extern NSString* kSettingsLevelDetectorCountsDecayDurationKey;
extern NSString* kSettingsLevelDetectorScalingKey;

extern NSString* kSettingsBitDetectorMaxLowLevelKey;
extern NSString* kSettingsBitDetectorMinHighLevelKey;
extern NSString* kSettingsBitDetectorSamplesPerPulseKey;

extern NSString* kSettingsMicSwitchDetectorThresholdKey;
extern NSString* kSettingsMicSwitchDetectorDurationKey;

extern NSString* kSettingsCloudStorageEnableKey;

extern NSString* kSettingsWaveCycleDetectorNonZeroLevelKey;
extern NSString* kSettingsBitStreamFrameDetectorPrefixKey;
extern NSString* kSettingsBitStreamFrameDetectorSuffixKey;
extern NSString* kSettingsBitStreamFrameDetectorContentSizeKey;

extern NSString* kSettingsRecordingsFileFormatKey;

@interface UserSettings : NSObject
{
}

+ (NSUserDefaults*)registerDefaults;
+ (NSUserDefaults*)validate;
+ (void)validateIntegerNamed:(NSString*)key minValue:(SInt32)minValue maxValue:(SInt32)maxValue;
+ (void)validateFloatNamed:(NSString*)key minValue:(Float32)minValue maxValue:(Float32)maxValue;

@end
