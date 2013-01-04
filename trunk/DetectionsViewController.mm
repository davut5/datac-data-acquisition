// -*- Mode: ObjC -*-
//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "AppDelegate.h"
#import "DetectionsViewController.h"
#import "PeakDetector.h"
#import "UserSettings.h"

@interface DetectionsViewController(Private)

- (void)makeGraph;
- (void)pullValue:(NSTimer*)timer;

@end

@implementation DetectionsViewController

@synthesize points, graph, detector;

- (id)initWithCoder:(NSCoder*)decoder
{
    LOG(@"RpmViewController.initWithCoder");
    
    //
    // We override initWithCoder since we need to run a timer task even if our view is not loaded or shown.
    //
    if (self = [super initWithCoder:decoder]) {
        graph = nil;
        detector = nil;
        [self updateFromSettings];
        newest = 0;
    }
    
    return self;
}

- (void)dealloc {
    [updateTimer invalidate];
    [updateTimer release];
    updateTimer = nil;
    self.graph = nil;
    [super dealloc];
}

- (void)viewDidLoad
{
    LOG(@"RpmViewController.viewDidLoad");
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    LOG(@"RpmViewController.viewDidUnload");
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
    CPTGraphHostingView* hostingView = (CPTGraphHostingView*)self.view;
    hostingView.hostedGraph = nil;
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)updateFromSettings
{
    LOG(@"RpmViewController.updateFromSettings");
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    
    Float32 maxX = [settings floatForKey:kSettingsDetectionsViewDurationKey];
    xScale = 1.0 / [settings floatForKey:kSettingsDetectionsViewUpdateRateKey];
    
    if (updateTimer != nil) {
        [updateTimer invalidate];
        [updateTimer release];
    }
    
    updateTimer = [[NSTimer scheduledTimerWithTimeInterval:xScale
                                                    target:self
                                                  selector:@selector(pullValue:)
                                                  userInfo:nil
                                                   repeats:YES] retain];
    
    UInt32 count = maxX / xScale + 0.5 + 1;
    if (points == nil || count != [points count]) {
        self.points = [NSMutableArray arrayWithCapacity:count];
        while ([points count] < count) {
            [points addObject:[NSNumber numberWithFloat:0.0]];
        }
        newest = 0;
    }
    
    if (graph != nil) {
        CPTXYPlotSpace* plotSpace = static_cast<CPTXYPlotSpace*>(graph.defaultPlotSpace);
        NSDecimal oldMaxX = plotSpace.xRange.length;
        NSDecimal newMaxX = CPTDecimalFromFloat(maxX);
        if (NSDecimalCompare(&oldMaxX, &newMaxX) != NSOrderedSame) {
            plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(0) length:newMaxX];
        }
    }
}

#pragma mark -
#pragma mark Plot Data Source Methods

- (NSUInteger)numberOfRecordsForPlot:(CPTPlot*)plot
{
    return [points count];
}

- (NSNumber*)numberForPlot:(CPTPlot*)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    switch (fieldEnum) {
        case CPTScatterPlotFieldX:
            // Generate X values based on the index of the point we are working with
            return [NSNumber numberWithFloat:(index * xScale)];
            break;
        case CPTScatterPlotFieldY:
            // Points are stored in a circular buffer, starting at newest.
            index = ( newest + index ) % [points count];
            return [points objectAtIndex:index];
            break;
        default:
            // Anything else is ignored.
            return [NSDecimalNumber zero];
    }
}

@end

@implementation DetectionsViewController (Private)

- (void)makeGraph
{
    Float32 maxX = [[NSUserDefaults standardUserDefaults] floatForKey:kSettingsDetectionsViewDurationKey];
    
    self.graph = [[[CPTXYGraph alloc] initWithFrame:CGRectZero] autorelease];
    [graph applyTheme:[CPTTheme themeNamed:kCPTDarkGradientTheme]];
    
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
    
    CPTMutableLineStyle* majorGridLineStyle = [CPTMutableLineStyle lineStyle];
    majorGridLineStyle.lineWidth = 0.75;
    majorGridLineStyle.lineColor = [[CPTColor colorWithGenericGray:0.5] colorWithAlphaComponent:0.75];
    
    CPTMutableLineStyle *minorGridLineStyle = [CPTMutableLineStyle lineStyle];
    minorGridLineStyle.lineWidth = 0.25;
    minorGridLineStyle.lineColor = [[CPTColor whiteColor] colorWithAlphaComponent:0.1];
    
    CPTMutableTextStyle *textStyle = [CPTTextStyle textStyle];
    textStyle.color = [CPTColor colorWithGenericGray:0.75];
    textStyle.fontSize = 12.0f;
    
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)graph.defaultPlotSpace;
    plotSpace.allowsUserInteraction = NO;
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(0) length:CPTDecimalFromFloat(maxX)];
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.0f) length:CPTDecimalFromFloat(12.0f)];
    
    CPTXYAxisSet* axisSet = (CPTXYAxisSet *)graph.axisSet;
    CPTXYAxis* x = axisSet.xAxis;
    x.titleTextStyle = textStyle;
    x.labelTextStyle = textStyle;
    x.majorIntervalLength = CPTDecimalFromInt(5);
    x.minorTicksPerInterval = 5;
    x.majorGridLineStyle = majorGridLineStyle;
    x.minorGridLineStyle = minorGridLineStyle;
    NSNumberFormatter* formatter = [[[NSNumberFormatter alloc] init] autorelease];
    [formatter setMaximumFractionDigits:0];
    x.labelFormatter = formatter;
    x.title = NSLocalizedString(@"Seconds Past", @"X axis label for RPM plot");
    x.titleOffset = 18.0f;
    
    CPTXYAxis* y = axisSet.yAxis;
    y.titleTextStyle = textStyle;
    y.labelTextStyle = textStyle;
    y.majorIntervalLength = CPTDecimalFromInt(2);
    y.minorTicksPerInterval = 5;
    y.majorGridLineStyle = majorGridLineStyle;
    y.minorGridLineStyle = minorGridLineStyle;
    formatter = [[[NSNumberFormatter alloc] init] autorelease];
    [formatter setMaximumFractionDigits:0];
    [formatter setPositiveSuffix:NSLocalizedString(@"k",@"1000's units designator for RPM ticks")];
    y.labelFormatter = formatter;
    y.title = NSLocalizedString(@"RPM", @"Y axis label for RPM plot");
    y.titleOffset = 20.0f;
    
    CPTScatterPlot* plot = [[[CPTScatterPlot alloc] init] autorelease];
    CPTMutableLineStyle* lineStyle = [CPTMutableLineStyle lineStyle];
    lineStyle.lineJoin = kCGLineJoinRound;
    lineStyle.lineCap = kCGLineCapRound;
    lineStyle.lineWidth = 3.0f;
    lineStyle.lineColor = [CPTColor cyanColor];
    
    plot.dataLineStyle = lineStyle;
    
    CPTFill* fill = [CPTFill fillWithColor:[[CPTColor cyanColor] colorWithAlphaComponent:0.3]];
    plot.areaFill = fill;
    plot.areaBaseValue = CPTDecimalFromInt(0);
    plot.dataSource = self;
    
    [graph addPlot:plot toPlotSpace:plotSpace];
    
    CPTGraphHostingView* hostingView = (CPTGraphHostingView*)self.view;
    hostingView.backgroundColor = [UIColor blackColor];
    hostingView.collapsesLayers = YES;
    hostingView.hostedGraph = graph;
}

- (void)pullValue:(NSTimer*)timer
{
    if (detector) {
        if (newest == 0) newest = [points count];
        newest -= 1;
        Float32 detection = [detector updatedDetectionValue] / 1000.0;
        [points replaceObjectAtIndex:newest withObject:[NSNumber numberWithFloat:detection]];
        if (graph != nil) {
            [graph reloadData];
        }
    }
}

@end
