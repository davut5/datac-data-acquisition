// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "AppDelegate.h"
#import "RpmViewController.h"
#import "LevelDetector.h"
#import "UserSettings.h"

@interface RpmViewController(Private)

- (void)makeGraph;
- (void)updateSignalStats:(NSNotification*)notification;

@end

@implementation RpmViewController

@synthesize points, graph;

- (id)initWithCoder:(NSCoder*)decoder
{
    if (self = [super initWithCoder:decoder]) {
        graph = nil;
        [self updateFromSettings];
        newest = 0;
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(updateSignalStats:)
                                                     name:kLevelDetectorCounterUpdateNotification
                                                   object:nil];
    }
    
    return self;
}

- (void)dealloc {
    self.graph = nil;
    [super dealloc];
}

- (void)makeGraph
{
    Float32 maxX = [[NSUserDefaults standardUserDefaults] floatForKey:kSettingsDetectionsViewDurationKey];
	
    self.graph = [[[CPXYGraph alloc] initWithFrame:CGRectZero] autorelease];
    [graph applyTheme:[CPTheme themeNamed:kCPDarkGradientTheme]];

    graph.paddingLeft = 0.0f;
    graph.paddingRight = 0.0f;
    graph.paddingTop = 0.0f;
    graph.paddingBottom = 0.0f;
    
    graph.plotAreaFrame.borderLineStyle = nil;
    graph.plotAreaFrame.cornerRadius = 0.0f;
    graph.plotAreaFrame.paddingLeft = 40.0;
    graph.plotAreaFrame.paddingTop = 8.0;
    graph.plotAreaFrame.paddingRight = 10.0;
    graph.plotAreaFrame.paddingBottom = 35.0;

    CPMutableLineStyle* majorGridLineStyle = [CPMutableLineStyle lineStyle];
    majorGridLineStyle.lineWidth = 0.75;
    majorGridLineStyle.lineColor = [[CPColor colorWithGenericGray:0.5] colorWithAlphaComponent:0.75];
	
    CPMutableLineStyle *minorGridLineStyle = [CPMutableLineStyle lineStyle];
    minorGridLineStyle.lineWidth = 0.25;
    minorGridLineStyle.lineColor = [[CPColor whiteColor] colorWithAlphaComponent:0.1];
	
    CPMutableLineStyle *redLineStyle = [CPMutableLineStyle lineStyle];
    redLineStyle.lineWidth = 10.0;
    redLineStyle.lineColor = [[CPColor redColor] colorWithAlphaComponent:0.5];

    CPMutableTextStyle *textStyle = [CPTextStyle textStyle];
    textStyle.color = [CPColor colorWithGenericGray:0.75];
    textStyle.fontSize = 12.0f;

    CPXYPlotSpace *plotSpace = (CPXYPlotSpace *)graph.defaultPlotSpace;
    plotSpace.allowsUserInteraction = NO;
    plotSpace.xRange = [CPPlotRange plotRangeWithLocation:CPDecimalFromInt(0) length:CPDecimalFromFloat(maxX)];
    plotSpace.yRange = [CPPlotRange plotRangeWithLocation:CPDecimalFromFloat(0.0f) length:CPDecimalFromFloat(12.0f)];

    CPXYAxisSet* axisSet = (CPXYAxisSet *)graph.axisSet;
    CPXYAxis* x = axisSet.xAxis;
    x.titleTextStyle = textStyle;
    x.labelTextStyle = textStyle;
    x.majorIntervalLength = CPDecimalFromInt(5);
    x.minorTicksPerInterval = 5;
    x.majorGridLineStyle = majorGridLineStyle;
    x.minorGridLineStyle = minorGridLineStyle;
    NSNumberFormatter* formatter = [[[NSNumberFormatter alloc] init] autorelease]; 
    [formatter setMaximumFractionDigits:0];
    x.labelFormatter = formatter;
    x.title = NSLocalizedString(@"Seconds Past", @"X axis label for RPM plot");
    x.titleOffset = 18.0f;

    CPXYAxis* y = axisSet.yAxis;
    y.titleTextStyle = textStyle;
    y.labelTextStyle = textStyle;
    y.majorIntervalLength = CPDecimalFromInt(2);
    y.minorTicksPerInterval = 5;
    y.majorGridLineStyle = majorGridLineStyle;
    y.minorGridLineStyle = minorGridLineStyle;
    formatter = [[[NSNumberFormatter alloc] init] autorelease];
    [formatter setMaximumFractionDigits:0];
    [formatter setPositiveSuffix:NSLocalizedString(@"k",@"1000's units designator for RPM ticks")];
    y.labelFormatter = formatter;
    y.title = NSLocalizedString(@"RPM", @"Y axis label for RPM plot");
    y.titleOffset = 20.0f;

    CPScatterPlot* plot = [[[CPScatterPlot alloc] init] autorelease];
    CPMutableLineStyle* lineStyle = [CPMutableLineStyle lineStyle];
    lineStyle.lineJoin = kCGLineJoinRound;
    lineStyle.lineCap = kCGLineCapRound;
    lineStyle.lineWidth = 3.0f;
    lineStyle.lineColor = [CPColor cyanColor];

    plot.dataLineStyle = lineStyle;

    CPFill* fill = [CPFill fillWithColor:[[CPColor cyanColor] colorWithAlphaComponent:0.3]];
    plot.areaFill = fill;
    plot.areaBaseValue = CPDecimalFromInt(0);
    plot.dataSource = self;

    [graph addPlot:plot toPlotSpace:plotSpace];

    CPGraphHostingView* hostingView = (CPGraphHostingView*)self.view;
    hostingView.backgroundColor = [UIColor blackColor];
    hostingView.collapsesLayers = YES;
    hostingView.hostedGraph = graph;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    //
    // About to show RPM graph. Create it.
    //
    [self makeGraph];
    [super viewWillAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    //
    // No longer showing RPM graph. Tear it down.
    //
    self.graph = nil;
    CPGraphHostingView* hostingView = (CPGraphHostingView*)self.view;
    hostingView.hostedGraph = nil;
    [super viewDidDisappear:animated];
}

- (void)updateFromSettings
{
    NSLog(@"RpmViewController.updateFromSettings");
    NSUserDefaults* settings = [UserSettings registerDefaults];

    Float32 maxX = [settings floatForKey:kSettingsDetectionsViewDurationKey];
    xScale = [settings floatForKey:kSettingsLevelDetectorUpdateRateKey];

    UInt32 count = maxX / xScale + 0.5 + 1;
    if (points == nil || count != [points count]) {
        self.points = [NSMutableArray arrayWithCapacity:count];
        while ([points count] < count) {
            [points addObject:[NSNumber numberWithFloat:0.0]];
        }
        newest = 0;
    }

    if (graph != nil) {
        CPXYPlotSpace* plotSpace = static_cast<CPXYPlotSpace*>(graph.defaultPlotSpace);
        NSDecimal oldMaxX = plotSpace.xRange.length;
        NSDecimal newMaxX = CPDecimalFromFloat(maxX);
        if (NSDecimalCompare(&oldMaxX, &newMaxX) != NSOrderedSame) {
            plotSpace.xRange = [CPPlotRange plotRangeWithLocation:CPDecimalFromInt(0) length:newMaxX];
        }
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark -
#pragma mark Plot Data Source Methods

- (NSUInteger)numberOfRecordsForPlot:(CPPlot*)plot
{
    return [points count];
}

- (NSNumber*)numberForPlot:(CPPlot*)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    switch (fieldEnum) {
        case CPScatterPlotFieldX:
            // Generate X values based on the index of the point we are working with
            return [NSNumber numberWithFloat:(index * xScale)];
            break;
        case CPScatterPlotFieldY:
            // Points are stored in a circular buffer, starting at newest.
            index = ( newest + index ) % [points count];
            return [points objectAtIndex:index];
            break;
        default:
            // Anything else is ignored.
            return [NSDecimalNumber zero];
    }
}

- (void)updateSignalStats:(NSNotification*)notification
{
    if (newest == 0) newest = [points count];
    newest -= 1;
    NSDictionary* userInfo = [notification userInfo];
    NSNumber* rpmValue = [userInfo objectForKey:kLevelDetectorRPMKey];
    [points replaceObjectAtIndex:newest withObject:rpmValue];
    if (graph != nil) {
        [graph reloadData];
    }
}

@end
