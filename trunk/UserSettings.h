// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* kSettingsSignalProcessingActiveDetectorKey;
extern NSString* kSettingsSignalProcessingInvertSignalKey;

extern NSString* kSettingsInputViewUpdateRateKey;
extern NSString* kSettingsInputViewScaleKey;

extern NSString* kSettingsDetectionsViewDurationKey;
extern NSString* kSettingsDetectionsViewUpdateRateKey;

extern NSString* kSettingsPeakDetectorLevelKey;
extern NSString* kSettingsPeakDetectorScalingKey;
extern NSString* kSettingsPeakDetectorUseLowPassFilterKey;
extern NSString* kSettingsPeakDetectorLowPassFilterFileNameKey;
extern NSString* kSettingsPeakDetectorCountsDecayDurationKey;

extern NSString* kSettingsBitDetectorMaxLowLevelKey;
extern NSString* kSettingsBitDetectorMinHighLevelKey;
extern NSString* kSettingsBitDetectorSamplesPerPulseKey;

extern NSString* kSettingsMicSwitchDetectorThresholdKey;
extern NSString* kSettingsMicSwitchDetectorDurationKey;

extern NSString* kSettingsCloudStorageEnableKey;

extern NSString* kSettingsBitStreamFrameDetectorPrefixKey;
extern NSString* kSettingsBitStreamFrameDetectorSuffixKey;
extern NSString* kSettingsBitStreamFrameDetectorContentSizeKey;

extern NSString* kSettingsPulseWidthDetectorLowLevelKey;
extern NSString* kSettingsPulseWidthDetectorHighLevelKey;
extern NSString* kSettingsPulseWidthDetectorMinHighAmplitudeKey;
extern NSString* kSettingsPulseWidthDetectorMaxPulse2PulseWidthKey;
extern NSString* kSettingsPulseWidthDetectorSmoothingKey;

extern NSString* kSettingsRecordingsFileFormatKey;

@interface UserSettings : NSObject
{
}

+ (NSUserDefaults*)registerDefaults;
+ (NSUserDefaults*)validate;
+ (void)validateIntegerNamed:(NSString*)key minValue:(SInt32)minValue maxValue:(SInt32)maxValue;
+ (void)validateFloatNamed:(NSString*)key minValue:(Float32)minValue maxValue:(Float32)maxValue;

@end
