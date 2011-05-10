// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* kSettingsLevelDetectorLevelKey;
extern NSString* kSettingsLevelDetectorUpdateRateKey;
extern NSString* kSettingsEnableLowPassFilterKey;
extern NSString* kSettingsTapsFileNameKey;
extern NSString* kSettingsXMinKey;
extern NSString* kSettingsXMaxKey;
extern NSString* kSettingsRPMScaleFactorKey;
extern NSString* kSettingsCounterDecayDurationKey;
extern NSString* kSettingsSignalDisplayUpdateRateKey;
extern NSString* kSettingsMicSwitchDetectorThresholdKey;
extern NSString* kSettingsMicSwitchDetectorDurationKey;
extern NSString* kSettingsRpmViewDurationKey;
extern NSString* kSettingsCloudStorageEnableKey;
extern NSString* kSettingsPulseDecoderSamplesPerPulseKey;
extern NSString* kSettingsPulseDecoderMaxLowLevelKey;
extern NSString* kSettingsPulseDecoderMinHighLevelKey;
extern NSString* kSettingsWaveCycleDetectorNonZeroLevelKey;
extern NSString* kSettingsBitStreamFrameDetectorPrefixKey;
extern NSString* kSettingsBitStreamFrameDetectorSuffixKey;
extern NSString* kSettingsBitStreamFrameDetectorContentSizeKey;

@interface UserSettings : NSObject
{
}

+ (NSUserDefaults*)registerDefaults;
+ (NSUserDefaults*)validate;
+ (void)validateIntegerNamed:(NSString*)key minValue:(SInt32)minValue maxValue:(SInt32)maxValue;
+ (void)validateFloatNamed:(NSString*)key minValue:(Float32)minValue maxValue:(Float32)maxValue;

@end
