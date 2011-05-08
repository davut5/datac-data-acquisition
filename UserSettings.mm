// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "UserSettings.h"

NSString* kSettingsLevelDetectorLevelKey = @"signalDetectorLevel";
NSString* kSettingsLevelDetectorUpdateRateKey = @"signalDetectorUpdateRate";
NSString* kSettingsEnableLowPassFilterKey = @"enableLowPassFilter";
NSString* kSettingsTapsFileNameKey = @"tapsFileName";
NSString* kSettingsXMinKey = @"xMin";
NSString* kSettingsXMaxKey = @"xMax";
NSString* kSettingsRPMScaleFactorKey = @"rpmScaleFactor";
NSString* kSettingsCounterDecayDurationKey = @"counterDecayDuration";
NSString* kSettingsSignalDisplayUpdateRateKey = @"signalDisplayUpdateRate";
NSString* kSettingsMicSwitchDetectorThresholdKey = @"switchDetectorThreshold";
NSString* kSettingsMicSwitchDetectorDurationKey = @"switchDetectorDuration";
NSString* kSettingsRpmViewDurationKey = @"rpmViewDuration";
NSString* kSettingsCloudStorageEnableKey = @"enableCloudStorage";
NSString* kSettingsPulseDecoderSamplesPerPulseKey = @"samplesPerPulse";
NSString* kSettingsPulseDecoderMaxLowLevelKey = @"maxLowLevel";
NSString* kSettingsPulseDecoderMinHighLevelKey = @"minHighLevel";
NSString* kSettingsWaveCycleDetectorNonZeroLevelKey = @"nonZeroLevel";

@implementation UserSettings

+ (NSUserDefaults*)registerDefaults
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithBool:YES], kSettingsEnableLowPassFilterKey,
                                @"taps", kSettingsTapsFileNameKey,
                                [NSNumber numberWithFloat:0.33], kSettingsLevelDetectorLevelKey,
                                [NSNumber numberWithFloat:0.25], kSettingsLevelDetectorUpdateRateKey,
                                [NSNumber numberWithFloat:0.0], kSettingsXMinKey,
                                [NSNumber numberWithFloat:1.0], kSettingsXMaxKey,
                                [NSNumber numberWithFloat:33.0], kSettingsRPMScaleFactorKey,
                                [NSNumber numberWithInt:4], kSettingsCounterDecayDurationKey,
                                [NSNumber numberWithFloat:20.0], kSettingsSignalDisplayUpdateRateKey,
                                [NSNumber numberWithFloat:0.0001], kSettingsMicSwitchDetectorThresholdKey,
                                [NSNumber numberWithFloat:0.5], kSettingsMicSwitchDetectorDurationKey,
                                [NSNumber numberWithFloat:30.0], kSettingsRpmViewDurationKey,
                                [NSNumber numberWithBool:YES], kSettingsCloudStorageEnableKey,
                                [NSNumber numberWithInt:37], kSettingsPulseDecoderSamplesPerPulseKey,
                                [NSNumber numberWithFloat:0.33], kSettingsPulseDecoderMaxLowLevelKey,
                                [NSNumber numberWithFloat:0.66], kSettingsPulseDecoderMinHighLevelKey,
                                [NSNumber numberWithFloat:0.33], kSettingsWaveCycleDetectorNonZeroLevelKey,
                                nil]];
    return defaults;
}

+ (void)validateFloatNamed:(NSString*)key minValue:(Float32)minValue maxValue:(Float32)maxValue
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    Float32	value = [defaults floatForKey:key];
    if (value < minValue) {
	value = minValue;
    }
    else if	(value > maxValue) {
	value = maxValue;
    }
    [defaults setFloat:value forKey:key];
    NSLog(@"validateFloatNamed: %@ %f", key, value);
}

+ (void)validateIntegerNamed:(NSString*)key minValue:(SInt32)minValue maxValue:(SInt32)maxValue
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    SInt32	value = [defaults integerForKey:key];
    if (value < minValue) {
	value = minValue;
    }
    else if	(value > maxValue) {
	value = maxValue;
    }
    [defaults setInteger:value forKey:key];
    NSLog(@"validateIntegerNamed: %@ %f", key, value);
}

+ (NSUserDefaults*)validate
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [UserSettings validateFloatNamed:kSettingsLevelDetectorLevelKey minValue:0.0 maxValue:1.0];
    [UserSettings validateFloatNamed:kSettingsXMinKey minValue:0.0 maxValue:1.0];
    [UserSettings validateFloatNamed:kSettingsXMaxKey minValue:0.0 maxValue:1.0];
    [UserSettings validateFloatNamed:kSettingsRPMScaleFactorKey minValue:0.1 maxValue:10000.0];
    [UserSettings validateFloatNamed:kSettingsSignalDisplayUpdateRateKey minValue:1.0 maxValue:60.0];
    [UserSettings validateIntegerNamed:kSettingsCounterDecayDurationKey minValue:0 maxValue:10];

    Float32 maxLowValue = [defaults floatForKey:kSettingsPulseDecoderMaxLowLevelKey];
    if (maxLowValue < -0.99) maxLowValue = -0.99;

    Float32 minHighValue = [defaults floatForKey:kSettingsPulseDecoderMinHighLevelKey];
    if (minHighValue > 0.99) minHighValue = 0.99;

    if (maxLowValue > minHighValue) maxLowValue = minHighValue;

    [defaults setFloat:maxLowValue forKey:kSettingsPulseDecoderMaxLowLevelKey];
    [defaults setFloat:minHighValue forKey:kSettingsPulseDecoderMinHighLevelKey];

    [defaults synchronize];

    return defaults;
}

@end
