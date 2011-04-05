//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "UserSettings.h"

NSString* kSettingsSignalDetectorLevelKey = @"signalDetectorLevel";
NSString* kSettingsSignalDetectorUpdateRateKey = @"signalDetectorUpdateRate";
NSString* kSettingsEnableLowPassFilterKey = @"enableLowPassFilter";
NSString* kSettingsTapsFileNameKey = @"tapsFileName";
NSString* kSettingsXMinKey = @"xMin";
NSString* kSettingsXMaxKey = @"xMax";
NSString* kSettingsRPMScaleFactorKey = @"rpmScaleFactor";
NSString* kSettingsCounterDecayDurationKey = @"counterDecayDuration";
NSString* kSettingsSignalDisplayUpdateRateKey = @"signalDisplayUpdateRate";
NSString* kSettingsSwitchDetectorThresholdKey = @"switchDetectorThreshold";
NSString* kSettingsSwitchDetectorDurationKey = @"switchDetectorDuration";
NSString* kSettingsRpmViewDurationKey = @"rpmViewDuration";
NSString* kSettingsCloudStorageEnableKey = @"enableCloudStorage";

@implementation UserSettings

+ (NSUserDefaults*)registerDefaults
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
						 [NSNumber numberWithBool:YES], kSettingsEnableLowPassFilterKey,
					     @"taps", kSettingsTapsFileNameKey,
						[NSNumber numberWithFloat:0.33], kSettingsSignalDetectorLevelKey,
						[NSNumber numberWithFloat:0.25], kSettingsSignalDetectorUpdateRateKey,
						[NSNumber numberWithFloat:0.0], kSettingsXMinKey,
						[NSNumber numberWithFloat:1.0], kSettingsXMaxKey,
						[NSNumber numberWithFloat:33.0], kSettingsRPMScaleFactorKey,
						  [NSNumber numberWithInt:4], kSettingsCounterDecayDurationKey,
						[NSNumber numberWithFloat:20.0], kSettingsSignalDisplayUpdateRateKey,
						[NSNumber numberWithFloat:0.0001], kSettingsSwitchDetectorThresholdKey,
						[NSNumber numberWithFloat:0.5], kSettingsSwitchDetectorDurationKey,
						[NSNumber numberWithFloat:30.0], kSettingsRpmViewDurationKey,
						 [NSNumber numberWithBool:YES], kSettingsCloudStorageEnableKey,
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
    [UserSettings validateFloatNamed:kSettingsSignalDetectorLevelKey minValue:0.0 maxValue:1.0];
    [UserSettings validateFloatNamed:kSettingsXMinKey minValue:0.0 maxValue:1.0];
    [UserSettings validateFloatNamed:kSettingsXMaxKey minValue:0.0 maxValue:1.0];
    [UserSettings validateFloatNamed:kSettingsRPMScaleFactorKey minValue:0.1 maxValue:10000.0];
    [UserSettings validateFloatNamed:kSettingsSignalDisplayUpdateRateKey minValue:1.0 maxValue:60.0];
    [UserSettings validateIntegerNamed:kSettingsCounterDecayDurationKey minValue:0 maxValue:10];
    [defaults synchronize];
    return defaults;
}

@end
