//
// Copyright (C) 2011, Brad Howes. All rights reserved.
//

#import "AppDelegate.h"
#import "RpmViewController.h"
#import "SignalDetector.h"
#import "UserSettings.h"

@interface RpmViewController(Private)

- (void)makeGraph;
- (void)updateSignalStats:(NSNotification*)notification;

@end

@implementation RpmViewController

@synthesize appDelegate, graph, visible;

- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle
{
    if (self = [super initWithNibName:nibName bundle:nibBundle]) {
	self.graph = nil;
	self.visible = NO;
    }
	
    return self;
}

- (void)viewDidLoad
{
    NSLog(@"RpmViewController.viewDidLoad");
    [super viewDidLoad];
    [self makeGraph];
}

- (void)makeGraph
{
    Float32 duration = [[NSUserDefaults standardUserDefaults] floatForKey:kSettingsRpmViewDurationKey];
	
    CPGraphHostingView* hostingView = (CPGraphHostingView*)self.view;
    hostingView.backgroundColor = [UIColor blackColor];
    hostingView.collapsesLayers = NO;

    self.graph = [[[CPXYGraph alloc] initWithFrame:CGRectZero] autorelease];
    [graph applyTheme:[CPTheme themeNamed:kCPDarkGradientTheme]];
    hostingView.hostedGraph = graph;

    graph.plotAreaFrame.borderLineStyle =nil;
    graph.plotAreaFrame.cornerRadius = 0.0f;

    graph.paddingLeft = 0.0f;
    graph.paddingRight = 0.0f;
    graph.paddingTop = 0.0f;
    graph.paddingBottom = 0.0f;

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
    plotSpace.allowsUserInteraction = YES;
    plotSpace.xRange = [CPPlotRange plotRangeWithLocation:CPDecimalFromInt(0) length:CPDecimalFromFloat(duration)];
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
    x.title = @"Seconds Past";
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
    [formatter setPositiveSuffix:@"k"];
    y.labelFormatter = formatter;
    y.title = @"RPM";
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
    plot.dataSource = appDelegate;

    [graph addPlot:plot toPlotSpace:plotSpace];
}

- (void)viewDidUnload
{
    NSLog(@"RpmViewController.viewDidUnload");
    self.graph = nil;
    [super viewDidUnload];
}

- (void)updateFromSettings
{
    NSLog(@"RpmViewController.updateFromSettings");
    NSUserDefaults* settings = [UserSettings registerDefaults];
    NSDecimal newDuration = CPDecimalFromFloat([settings floatForKey:kSettingsRpmViewDurationKey]);
    CPXYPlotSpace* plotSpace = static_cast<CPXYPlotSpace*>(graph.defaultPlotSpace);
    NSDecimal oldDuration = plotSpace.xRange.length;
    if (NSDecimalCompare(&oldDuration, &newDuration) != NSOrderedSame) {
	plotSpace.xRange = [CPPlotRange plotRangeWithLocation:CPDecimalFromInt(0) length:newDuration];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    visible = YES;
    if (graph == nil) [self makeGraph];
    [[graph plotAtIndex:0] setDataNeedsReloading];
    [super viewWillAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    visible = NO;
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)update
{
    if (visible == YES) {
	[graph reloadData];
    }
}

- (void)dealloc {
    self.graph = nil;
    [super dealloc];
}

@end
