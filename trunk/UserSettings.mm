// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "UserSettings.h"

NSString* kSettingsSignalProcessingInvertSignalKey = @"SIGNAL_PROCESSING_INVERT_SIGNAL";
NSString* kSettingsSignalProcessingActiveDetectorKey = @"SIGNAL_PROCESSING_ACTIVE_DETECTOR";

NSString* kSettingsInputViewUpdateRateKey = @"INPUT_VIEW_UPDATE_RATE";
NSString* kSettingsInputViewScaleKey = @"INPUT_VIEW_SCALE";

NSString* kSettingsDetectionsViewDurationKey = @"DETECTIONS_VIEW_DURATION";
NSString* kSettingsDetectionsViewUpdateRateKey = @"DETECTIONS_VIEW_UPDATE_RATE";

NSString* kSettingsPeakDetectorLevelKey = @"LEVEL_DETECTOR_LEVEL";
NSString* kSettingsPeakDetectorScalingKey = @"LEVEL_DETECTOR_SCALING";
NSString* kSettingsPeakDetectorUseLowPassFilterKey = @"LEVEL_DETECTOR_USE_LOW_PASS_FILTER";
NSString* kSettingsPeakDetectorLowPassFilterFileNameKey = @"LEVEL_DETECTOR_LOW_PASS_FILTER_FILENAME";
NSString* kSettingsPeakDetectorCountsDecayDurationKey = @"LEVEL_DETECTOR_COUNTS_DECAY_DURATION";

NSString* kSettingsBitDetectorMaxLowLevelKey = @"BIT_DETECTOR_MAX_LOW_LEVEL";
NSString* kSettingsBitDetectorMinHighLevelKey = @"BIT_DETECTOR_MIN_HIGH_LEVEL";
NSString* kSettingsBitDetectorSamplesPerPulseKey = @"BIT_DETECTOR_SAMPLES_PER_PULSE";

NSString* kSettingsBitStreamFrameDetectorPrefixKey = @"BIT_STREAM_FRAME_DETECTOR_PREFIX";
NSString* kSettingsBitStreamFrameDetectorSuffixKey = @"BIT_STREAM_FRAME_DETECTOR_SUFFIX";
NSString* kSettingsBitStreamFrameDetectorContentSizeKey = @"BIT_STREAM_FRAME_DETECTOR_CONTENT_SIZE";

NSString* kSettingsMicSwitchDetectorThresholdKey = @"MIC_SWITCH_DETECTOR_THRESHOLD";
NSString* kSettingsMicSwitchDetectorDurationKey = @"MIC_SWITCH_DETECTOR_DURATION";

NSString* kSettingsCloudStorageEnableKey = @"CLOUD_STORAGE_ENABLE";

NSString* kSettingsRecordingsFileFormatKey = @"RECORDINGS_FILE_FORMAT";

NSString* kSettingsPulseWidthDetectorLowLevelKey = @"PULSE_WIDTH_DETECTOR_LOW_LEVEL";
NSString* kSettingsPulseWidthDetectorHighLevelKey = @"PULSE_WIDTH_DETECTOR_HIGH_LEVEL";
NSString* kSettingsPulseWidthDetectorMinHighAmplitudeKey = @"PULSE_WIDTH_DETECTOR_MIN_HIGH_AMPLITUDE";
NSString* kSettingsPulseWidthDetectorMaxPulse2PulseWidthKey = @"PULSE_WIDTH_DETECTOR_MAX_PULSE_2_PULSE_WIDTH";
NSString* kSettingsPulseWidthDetectorScalingKey = @"PULSE_WIDTH_DETECTOR_SCALING";
NSString* kSettingsPulseWidthDetectorSmoothingKey = @"PULSE_WIDTH_DETECTOR_SMOOTHING";

@implementation UserSettings

+ (NSUserDefaults*)registerDefaults
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
                                
                                @"PeakDetector", kSettingsSignalProcessingActiveDetectorKey,
                                [NSNumber numberWithBool:NO], kSettingsSignalProcessingInvertSignalKey,
                                
                                [NSNumber numberWithFloat:30.0], kSettingsInputViewUpdateRateKey,
                                [NSNumber numberWithFloat:0.0001], kSettingsInputViewScaleKey,
                                
                                [NSNumber numberWithFloat:30.0], kSettingsDetectionsViewDurationKey,
                                [NSNumber numberWithFloat:4], kSettingsDetectionsViewUpdateRateKey,
                                
                                [NSNumber numberWithFloat:0.3333], kSettingsPeakDetectorLevelKey,
                                [NSNumber numberWithFloat:(1000.0/33.0)], kSettingsPeakDetectorScalingKey,
                                [NSNumber numberWithBool:YES], kSettingsPeakDetectorUseLowPassFilterKey,
                                @"taps", kSettingsPeakDetectorLowPassFilterFileNameKey,
                                [NSNumber numberWithInt:4], kSettingsPeakDetectorCountsDecayDurationKey,
                                
                                [NSNumber numberWithFloat:0.33], kSettingsBitDetectorMaxLowLevelKey,
                                [NSNumber numberWithFloat:0.66], kSettingsBitDetectorMinHighLevelKey,
                                [NSNumber numberWithInt:37], kSettingsBitDetectorSamplesPerPulseKey,
                                
                                @"0010101011", kSettingsBitStreamFrameDetectorPrefixKey,
                                @"0101010101", kSettingsBitStreamFrameDetectorSuffixKey,
                                [NSNumber numberWithInt:30], kSettingsBitStreamFrameDetectorContentSizeKey,
                                
                                [NSNumber numberWithFloat:0.0001], kSettingsMicSwitchDetectorThresholdKey,
                                [NSNumber numberWithFloat:0.5], kSettingsMicSwitchDetectorDurationKey,
                                
                                [NSNumber numberWithBool:YES], kSettingsCloudStorageEnableKey,
                                
                                @"caf", kSettingsRecordingsFileFormatKey,
                                
                                [NSNumber numberWithFloat:-0.1], kSettingsPulseWidthDetectorLowLevelKey,
                                [NSNumber numberWithFloat: 0.0], kSettingsPulseWidthDetectorHighLevelKey,
                                [NSNumber numberWithFloat: 0.7], kSettingsPulseWidthDetectorMinHighAmplitudeKey,
                                [NSNumber numberWithInt:22050], kSettingsPulseWidthDetectorMaxPulse2PulseWidthKey,
                                [NSNumber numberWithFloat:1.0], kSettingsPulseWidthDetectorScalingKey,
                                [NSNumber numberWithInt:5], kSettingsPulseWidthDetectorSmoothingKey,
                                
                                nil]];
    [pool drain];
    
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
    NSLog(@"validateIntegerNamed: %@ %ld", key, value);
}

+ (NSUserDefaults*)validate
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [UserSettings validateFloatNamed:kSettingsInputViewUpdateRateKey minValue:1.0 maxValue:60.0];
    [UserSettings validateFloatNamed:kSettingsInputViewScaleKey minValue:0.0001 maxValue:1.0];
    [UserSettings validateFloatNamed:kSettingsDetectionsViewUpdateRateKey minValue:0.1 maxValue:60.0];
    [UserSettings validateFloatNamed:kSettingsPeakDetectorLevelKey minValue:0.0 maxValue:1.0];
    [UserSettings validateFloatNamed:kSettingsPeakDetectorScalingKey minValue:0.1 maxValue:10000.0];
    [UserSettings validateIntegerNamed:kSettingsPeakDetectorCountsDecayDurationKey minValue:0 maxValue:10];
    
    [UserSettings validateFloatNamed:kSettingsPulseWidthDetectorLowLevelKey minValue:-1.0 maxValue:1.0];
    [UserSettings validateFloatNamed:kSettingsPulseWidthDetectorHighLevelKey minValue:-1.0 maxValue:1.0];
    [UserSettings validateFloatNamed:kSettingsPulseWidthDetectorMinHighAmplitudeKey minValue:-1.0 maxValue:1.0];
    [UserSettings validateIntegerNamed:kSettingsPulseWidthDetectorMaxPulse2PulseWidthKey minValue:1 maxValue:44100];
    [UserSettings validateIntegerNamed:kSettingsPulseWidthDetectorSmoothingKey minValue:0 maxValue:100];
    
    Float32 maxLowValue = [defaults floatForKey:kSettingsBitDetectorMaxLowLevelKey];
    if (maxLowValue < -0.99) maxLowValue = -0.99;
    
    Float32 minHighValue = [defaults floatForKey:kSettingsBitDetectorMinHighLevelKey];
    if (minHighValue > 0.99) minHighValue = 0.99;
    
    if (maxLowValue > minHighValue) maxLowValue = minHighValue;
    
    [defaults setFloat:maxLowValue forKey:kSettingsBitDetectorMaxLowLevelKey];
    [defaults setFloat:minHighValue forKey:kSettingsBitDetectorMinHighLevelKey];
    
    [defaults synchronize];
    
    return defaults;
}

@end
