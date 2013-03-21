#import "ammNCWundergroundController.h"

#define i_numberOfDays 4

@implementation ammNCWundergroundController

@synthesize view=i_view;

+ (void)initialize {
    _ammNCWundergroundWeeAppBundle = [[NSBundle bundleForClass:[self class]] retain];
}

- (id)init {
    if((self = [super init]) != nil) {
        i_savedData = [[NSMutableDictionary alloc] init];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                             NSUserDomainMask, YES);
        i_saveFile = [[NSString alloc] initWithString:
            [[paths objectAtIndex:0] stringByAppendingString:
                @"/com.amm.ncwunderground.save.plist"]];
        
        i_locationManager = [[CLLocationManager alloc] init];
        i_locationUpdated = NO; // we use this later to ensure we only get one location update
        i_loadingData = NO; // indicates whether we're already loading data

        i_iconMap = [[NSDictionary alloc] initWithContentsOfFile:
            [_ammNCWundergroundWeeAppBundle pathForResource:
                @"com.amm.ncwunderground.iconmap" ofType:@"plist"]];

        backgroundQueue = dispatch_queue_create("com.amm.ncwunderground.urlqueue", NULL);
    } return self; 
}

- (void)dealloc { 
    // We release a lot of things here that are also released in unload view
    // We don't want both of those releases going through, so there we set to
    // nil after releasing. This is just in case unloadViews doesn't get called.

    i_isDisplayed = NO;
    // release all the views!
    [i_view release];
    [i_backgroundViews release];

    // release some other things!
    [i_savedData release];
    [i_saveFile release];
    [i_locationManager release];
    [i_iconMap release];
    [i_dayNames release];
    [i_dayTemps release];
    [i_dayIconViews release];
    [i_spinners release];

    // get rid of the queue
    dispatch_release(backgroundQueue);

    [super dealloc];
}

// A few default label attributes
- (void) clearLabelSmallWhiteText:(UILabel *)label {
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:14.f];
}

- (void)updateBackgroundLeft2SubviewValues {
    // "Last Refreshed" label
    NSDate *lastRefreshedDate = [NSDate dateWithTimeIntervalSince1970:
        [[i_savedData objectForKey:@"last request"] doubleValue]];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"h:mm:ss a"];
    [i_lastRefreshed setText:[@"Last Refreshed: " stringByAppendingString:
        [dateFormatter stringFromDate:lastRefreshedDate]]];
    [dateFormatter release];

    // "Distance From Station" label
    CLLocation *userLocation = [[CLLocation alloc] initWithLatitude:
        [[i_savedData objectForKey:@"latitude"] doubleValue] longitude:
        [[i_savedData objectForKey:@"longitude"] doubleValue]];
    NSDictionary *stationInfo = [[i_savedData objectForKey:@"current_observation"]
        objectForKey:@"observation_location"];
    CLLocation *stationLocation = [[CLLocation alloc] initWithLatitude:
        [[stationInfo objectForKey:@"latitude"] doubleValue] longitude:
        [[stationInfo objectForKey:@"longitude"] doubleValue]];
    [i_distanceToStation setText:[NSString stringWithFormat:
        @"Distance From Station: %.2lf mi",([stationLocation distanceFromLocation:
            userLocation] / 1609.344)]];

    [userLocation release];
    [stationLocation release];

    // "Configure" label
    [i_configureInSettings setText:@"Configure options in Settings."];
}

- (void)updateBackgroundLeftSubviewValues {
    // We'll need to access the tweak's user defaults to know how many hours to include
    NSDictionary *defaultsDom = [[NSUserDefaults standardUserDefaults] 
        persistentDomainForName:@"com.amm.ncwunderground"];
    NSNumber *hourlyLength = [defaultsDom objectForKey:@"hourlyLength"];
    int intervalLength;
    if (hourlyLength) {
        intervalLength = [hourlyLength integerValue];
    }
    else {
        NSLog(@"NCWunderground: user defaults contain no hourly forecast length field. Defaulting to 12 hours.");
        intervalLength = 12;
    }

    // convenience pointers
    NSArray *hourly_forecast = [i_savedData objectForKey:@"hourly_forecast"];
    NSDictionary *first_forecast = [hourly_forecast objectAtIndex:0];
    NSDictionary *last_forecast = [hourly_forecast objectAtIndex:(intervalLength-1)];

    ////    Row 1   ////

    // "Current Time" header label
    int nowTime = [[[first_forecast objectForKey:@"FCTTIME"] objectForKey:@"hour"] intValue];
    NSString *nowAMPM = [[first_forecast objectForKey:@"FCTTIME"] objectForKey:@"ampm"];
    if ([nowAMPM isEqualToString:@"PM"])
        nowTime -= 12;
    if (nowTime == 0)
        nowTime = 12;
    i_titleNow.text = [NSString stringWithFormat:@"%d %@",nowTime,nowAMPM];

    // "Interval length" header label
    i_titleLength.text = [NSString stringWithFormat:@"%d hr",intervalLength]; 
    
    // "End Time" header label
    int endTime = [[[last_forecast objectForKey:@"FCTTIME"] objectForKey:@"hour"] intValue];
    NSString *endAMPM = [[last_forecast objectForKey:@"FCTTIME"] objectForKey:@"ampm"];
    if ([endAMPM isEqualToString:@"PM"]) {
        endTime -= 12;
    }
    if (endTime == 0) {
        endTime = 12;
    }
    i_titleEnd.text = [NSString stringWithFormat:@"%d %@",endTime,endAMPM];

    // "High" and "Low" header labels
    i_titleHigh.text = @"High";
    i_titleLow.text = @"Low";

    ////    Row 2   ////

    // "Real Temp" row label and current value
    i_realTempName.text = @"Temp:";
    i_realTempNow.text = [[[first_forecast objectForKey:@"temp"] objectForKey:
        @"english"] stringByAppendingString:@" °F"];

    // Generate real temp spark chart
    NSMutableArray *realTempSparkData = [NSMutableArray array];
    for(int i = 0; i <= intervalLength-1; ++i) {
        NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
        [f setNumberStyle:NSNumberFormatterDecimalStyle];
        NSString *numberString = [[[hourly_forecast objectAtIndex:i] objectForKey:
            @"temp"] objectForKey:@"english"];
        NSNumber *myNumber = [f numberFromString:numberString];
        [f release];
        if (myNumber) {
            [realTempSparkData addObject:myNumber];
        }
        else {
            NSLog(@"NCWunderground: Got bad number string at position %d in hourly forecast. Bad.",i);
        }
    }
    [i_realTempSparkView setDataValues:realTempSparkData];

    // "Real Temp" end, high, low labels
    i_realTempEnd.text = [[[last_forecast objectForKey:@"temp"] objectForKey:
        @"english"] stringByAppendingString:@" °F"];
    i_realTempHigh.text = [[[i_realTempSparkView dataMaximum] stringValue] 
        stringByAppendingString:@" °F"];
    i_realTempLow.text = [[[i_realTempSparkView dataMinimum] stringValue] 
        stringByAppendingString:@" °F"];

    ////    Row 3   ////

    // "Feels Like" row label and current value
    i_feelsLikeName.text = @"Like:";
    i_feelsLikeNow.text = [[[first_forecast objectForKey:@"feelslike"] objectForKey:
        @"english"] stringByAppendingString:@" °F"];
    NSMutableArray *feelsLikeSparkData = [NSMutableArray array];
    for(int i = 0; i <= intervalLength-1; ++i) {
        NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
        [f setNumberStyle:NSNumberFormatterDecimalStyle];
        NSString *numberString = [[[hourly_forecast objectAtIndex:i] objectForKey:
            @"feelslike"] objectForKey:@"english"];
        NSNumber *myNumber = [f numberFromString:numberString];
        [f release];
        if (myNumber) {
            [feelsLikeSparkData addObject:myNumber];
        }
        else {
            NSLog(@"NCWunderground: Got bad number string at position %d in hourly forecast. Bad.",i);
        }
    }
    [i_feelsLikeSparkView setDataValues:feelsLikeSparkData];
    i_feelsLikeEnd.text = [[[last_forecast objectForKey:@"feelslike"] objectForKey:@"english"] stringByAppendingString:@" °F"];
    i_feelsLikeHigh.text = [[[i_feelsLikeSparkView dataMaximum] stringValue] stringByAppendingString:@" °F"];
    i_feelsLikeLow.text = [[[i_feelsLikeSparkView dataMinimum] stringValue] stringByAppendingString:@" °F"];
}

- (void)updateBackgroundSubviewValues {
    // convenience pointer
    NSDictionary *current_observation = [i_savedData objectForKey:@"current_observation"];

    i_temperatureLabel.text = [[[current_observation objectForKey:@"temp_f"] stringValue] stringByAppendingString:@" °F"];
    i_feelsLikeLabel.text = [NSString stringWithFormat:@"Feels Like: %@ °F",[current_observation objectForKey:@"feelslike_f"]];
    i_locationLabel.text = [[current_observation objectForKey:@"display_location"] objectForKey:@"full"];
    i_humidityLabel.text = [@"Humidity: " stringByAppendingString:[current_observation objectForKey:@"relative_humidity"]];
    i_windLabel.text = [NSString stringWithFormat:@"Wind: %@ mph",[[current_observation objectForKey:@"wind_mph"] stringValue]];
    
    NSString *wundergroundIconName = [[[current_observation objectForKey:
        @"icon_url"] lastPathComponent] stringByDeletingPathExtension];
    NSString *localIconName = [[i_iconMap objectForKey:wundergroundIconName] objectForKey:@"icon"];
    i_weatherTypeLabel.text = [[i_iconMap objectForKey:wundergroundIconName] objectForKey:@"word"];
    if (localIconName == nil) {
        wundergroundIconName = [current_observation objectForKey:@"icon"];
        localIconName = [[i_iconMap objectForKey:wundergroundIconName] objectForKey:@"icon"];
    }
    UIImage *weatherIcon = [UIImage imageWithContentsOfFile:
        [_ammNCWundergroundWeeAppBundle pathForResource:localIconName ofType:@"png"]];
    i_iconView.image=weatherIcon;
}

- (void)updateBackgroundRightSubviewValues {
    NSArray *forecastday = [i_savedData objectForKey:@"forecastday"];
    for (int j = 0; j < i_numberOfDays; ++j) {
        NSDictionary *day = [forecastday objectAtIndex:j];

        [[i_dayNames objectAtIndex:j] setText:[[day objectForKey:
            @"date"] objectForKey:@"weekday_short"]];

        [[i_dayTemps objectAtIndex:j] setText:[NSString stringWithFormat:
            @"%@/%@ (%@%%)",[[day objectForKey:@"high"] objectForKey:@"fahrenheit"],
            [[day objectForKey:@"low"] objectForKey:@"fahrenheit"],
            [[day objectForKey:@"pop"] stringValue]]];

        NSString *wundergroundIconName = [[[day objectForKey:
            @"icon_url"] lastPathComponent] stringByDeletingPathExtension];
        NSString *localIconName = [[i_iconMap objectForKey:
            wundergroundIconName] objectForKey:@"icon"];
        if (localIconName == nil) {
            wundergroundIconName = [day objectForKey:@"icon"];
            localIconName = [[i_iconMap objectForKey:wundergroundIconName] objectForKey:@"icon"];
        }
        UIImage *weatherIcon = [UIImage imageWithContentsOfFile:
            [_ammNCWundergroundWeeAppBundle pathForResource:localIconName ofType:@"png"]];
        [[i_dayIconViews objectAtIndex:j] setImage:weatherIcon];
    }
}

- (void)positionSubviewsForBackgroundViewWidth:(float)width {
    float c0off = (width - 316)/2; float c1off = 2.f; float c2off = 2.f; float c3off = 2.f; float c4off = 2.f; float c5off = 2.f;
    float c0width = 45.f; float c1width = 45.f; float c2width = 77.f; float c3width = 45.f; float c4width = 45.f; float c5width = 45.f;
    float c0x = c0off; float c1x = c0x+c0width+c1off; float c2x = c1x+c1width+c2off;
    float c3x = c2x+c2width+c3off; float c4x = c3x+c3width+c4off; float c5x = c4x+c4width+c5off;
    float r1off = 5.f; float r1height = 15.f; float r1y = r1off;
    float r2off = 8.f; float r2height = 15.f; float r2y = r1y+r1height+r2off;
    float r3off = 8.f; float r3height = 15.f; float r3y = r2y+r2height+r3off;

    // position and hide spinners
    for (spinner in i_spinners) {
        [spinner setCenter:CGPointMake(width/2,[self viewHeight]/2)];
        [spinner setHidden:YES];
    }

    // backgroundLeft2
    [i_lastRefreshed setFrame:CGRectMake(36,r1y,width-76,r1height)];
    [i_distanceToStation setFrame:CGRectMake(36,r2y,width-76,r2height)];
    [i_configureInSettings setFrame:CGRectMake(36,r3y,width-76,r3height)];
    [i_refreshButton setFrame:CGRectMake(width-34,([self viewHeight] - 32)/2,32,32)];

    // backgroundLeft

    // row 1
    i_titleNow.frame = CGRectMake(c1x,r1y,c1width,r1height);
    i_titleLength.frame = CGRectMake(c2x,r1y,c2width,r1height);
    i_titleEnd.frame = CGRectMake(c3x,r1y,c3width,r1height);
    i_titleHigh.frame = CGRectMake(c4x,r1y,c4width,r1height);
    i_titleLow.frame = CGRectMake(c5x,r1y,c5width,r1height);

    // row 2
    i_realTempName.frame = CGRectMake(c0x,r2y,c0width,r2height);
    i_realTempNow.frame = CGRectMake(c1x,r2y,c1width,r2height);
    i_realTempSparkView.frame = CGRectMake(c2x,r2y,c2width,r2height);
    i_realTempEnd.frame = CGRectMake(c3x,r2y,c3width,r2height);
    i_realTempHigh.frame = CGRectMake(c4x,r2y,c4width,r2height);
    i_realTempLow.frame = CGRectMake(c5x,r2y,c5width,r2height);

    // row 3
    i_feelsLikeName.frame = CGRectMake(c0x,r3y,c0width,r3height);
    i_feelsLikeNow.frame = CGRectMake(c1x,r3y,c1width,r3height);
    i_feelsLikeSparkView.frame = CGRectMake(c2x,r3y,c2width,r3height);
    i_feelsLikeEnd.frame = CGRectMake(c3x,r3y,c3width,r3height);
    i_feelsLikeHigh.frame = CGRectMake(c4x,r3y,c4width,r3height);
    i_feelsLikeLow.frame = CGRectMake(c5x,r3y,c5width,r3height);

    // background
    float temperatureWidth = (316.f - 8 - [self viewHeight]) / 2;
    float moreInfoWidth = 316.f - 8.f - [self viewHeight] - temperatureWidth;

    i_temperatureLabel.frame = CGRectMake(c0off,2.f,temperatureWidth,30.f);
    i_feelsLikeLabel.frame = CGRectMake(c0off,34.f,temperatureWidth,14.f);
    i_weatherTypeLabel.frame = CGRectMake(c0off,50.f,temperatureWidth,15.f);
    i_iconView.frame = CGRectMake(c0off + temperatureWidth+2,0.f,[self viewHeight],[self viewHeight]);
    i_locationLabel.frame = CGRectMake(c0off + temperatureWidth + [self viewHeight]+4,5.f,moreInfoWidth,15.f);
    i_humidityLabel.frame = CGRectMake(c0off + temperatureWidth + [self viewHeight]+4,28.f,moreInfoWidth,15.f);
    i_windLabel.frame = CGRectMake(c0off + temperatureWidth + [self viewHeight]+4,51.f,moreInfoWidth,15.f);

    // backgroundRight
    float dayWidth = (316 - 2 * (i_numberOfDays + 1)) / i_numberOfDays;
    float iconDims = [self viewHeight] - 42;
    if (dayWidth < iconDims)
        iconDims = dayWidth;
    NSArray *rightSubviewLabelContainers = [NSArray arrayWithObjects:i_dayNames,i_dayTemps,nil];
    for (int j = 0; j < i_numberOfDays; ++j) {
        for (int i = 0; i < 2; ++i) {
            UILabel *label = [[rightSubviewLabelContainers objectAtIndex:i] objectAtIndex:j];
            label.frame = CGRectMake(c0off + j * (2 + dayWidth),17 * i + 2,dayWidth,15);
        }
        [[i_dayIconViews objectAtIndex:j] setFrame:
            CGRectMake(c0off + j * (2 + dayWidth) + (dayWidth - iconDims)/2,36,iconDims,iconDims)];
    }
}

- (void)loadBackgroundLeft2Subviews {
    // build a convenience array while alloc'ing and init'ing
    NSArray *backgroundLeft2LabelArray = [NSArray arrayWithObjects:
        (i_lastRefreshed = [[UILabel alloc] init]),
        (i_distanceToStation = [[UILabel alloc] init]),
        (i_configureInSettings = [[UILabel alloc] init]),nil];

    // refresh button
    i_refreshButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *refreshImage = [UIImage imageWithContentsOfFile:
        [_ammNCWundergroundWeeAppBundle pathForResource:
                @"refresh" ofType:@"png"]];
    [i_refreshButton setBackgroundImage:refreshImage forState:UIControlStateNormal];
    [i_refreshButton addTarget:self action:@selector(loadData:) 
        forControlEvents:UIControlEventTouchUpInside];
    NSLog(@"NCWunderground: button actions %@",[i_refreshButton actionsForTarget:self
        forControlEvent:UIControlEventTouchUpInside]);

    // loading spinner
    if ([i_spinners count] != 0) {
        [i_spinners removeAllObjects];
    }
    [i_spinners addObject:[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:
        UIActivityIndicatorViewStyleGray]];
    
    // basic tasks on all the labels
    for (UILabel *iterView in backgroundLeft2LabelArray) {
        [self clearLabelSmallWhiteText:iterView];
        iterView.textAlignment = NSTextAlignmentCenter;
    }

    // add and release the labels
    for (UILabel *iterView in backgroundLeft2LabelArray) {
        [[i_backgroundViews objectAtIndex:0] addSubview:iterView];
        [iterView release];
    }

    // add the other things
    [[i_backgroundViews objectAtIndex:0] addSubview:i_refreshButton];
    [[i_backgroundViews objectAtIndex:0] addSubview:[i_spinners objectAtIndex:0]];

    // don't need to release i_refreshButton
    [[i_spinners objectAtIndex:0] release];
}

- (void)loadBackgroundLeftSubviews {
    NSArray *backgroundLeftLabelArray = [NSArray arrayWithObjects:
        (i_titleNow = [[UILabel alloc] init]),
        (i_titleLength = [[UILabel alloc] init]),
        (i_titleEnd = [[UILabel alloc] init]),
        (i_titleHigh = [[UILabel alloc] init]),
        (i_titleLow = [[UILabel alloc] init]),
        (i_realTempName = [[UILabel alloc] init]),
        (i_realTempNow = [[UILabel alloc] init]),
        (i_realTempEnd = [[UILabel alloc] init]),
        (i_realTempHigh = [[UILabel alloc] init]),
        (i_realTempLow = [[UILabel alloc] init]),
        (i_feelsLikeName = [[UILabel alloc] init]),
        (i_feelsLikeNow = [[UILabel alloc] init]),
        (i_feelsLikeEnd = [[UILabel alloc] init]),
        (i_feelsLikeHigh = [[UILabel alloc] init]),
        (i_feelsLikeLow = [[UILabel alloc] init]),nil];

    // loading spinner
    if ([i_spinners count] != 1) {
        [i_spinners removeObjectsInRange:NSMakeRange(1,[i_spinners count]-1)];
    }
    [i_spinners addObject:[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:
        UIActivityIndicatorViewStyleGray]];

    // basic tasks on all the labels
    for (UILabel *iterView in backgroundLeftLabelArray) {
        [self clearLabelSmallWhiteText:iterView];
        iterView.textAlignment = NSTextAlignmentCenter;
    }

    NSArray *backgroundLeftSparkArray = [NSArray arrayWithObjects: 
        (i_realTempSparkView = [[ASBSparkLineView alloc] init]),
        ( i_feelsLikeSparkView = [[ASBSparkLineView alloc] init]),nil];
    // Color all of the spark views
    for (ASBSparkLineView *iterView in backgroundLeftSparkArray) {
        iterView.penColor = [UIColor whiteColor];
        iterView.backgroundColor = [UIColor clearColor];
        iterView.showCurrentValue = NO;
    }


    // add and release all the views
    for (UILabel *iterView in backgroundLeftLabelArray) {
        [[i_backgroundViews objectAtIndex:1] addSubview:iterView];
        [iterView release];
    }
    for (ASBSparkLineView *iterView in backgroundLeftSparkArray) {
        [[i_backgroundViews objectAtIndex:1] addSubview:iterView];
        [iterView release];
    }
    [[i_backgroundViews objectAtIndex:1] addSubview:[i_spinners objectAtIndex:1]];
    [[i_spinners objectAtIndex:1] release];
}

- (void)loadBackgroundSubviews {
    NSArray *backgroundLabelArrayLeftCol = [NSArray arrayWithObjects:
        (i_temperatureLabel = [[UILabel alloc] init]),
        (i_feelsLikeLabel = [[UILabel alloc] init]),
        (i_weatherTypeLabel = [[UILabel alloc] init]),nil];
    NSArray *backgroundLabelArrayRightCol = [NSArray arrayWithObjects:
        (i_locationLabel = [[UILabel alloc] init]),
        (i_humidityLabel = [[UILabel alloc] init]),
        (i_windLabel = [[UILabel alloc] init]),nil];

    i_iconView = [[UIImageView alloc] init];

    // loading spinner
    if ([i_spinners count] != 2) {
        [i_spinners removeObjectsInRange:NSMakeRange(2,[i_spinners count]-2)];
    }
    [i_spinners addObject:[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:
        UIActivityIndicatorViewStyleGray]];

    for (UILabel *iterView in backgroundLabelArrayRightCol) {
        [iterView setTextAlignment:NSTextAlignmentRight];
    }
    for (UILabel *iterView in [backgroundLabelArrayLeftCol arrayByAddingObjectsFromArray:backgroundLabelArrayRightCol]) {
        [self clearLabelSmallWhiteText:iterView];
        [[i_backgroundViews objectAtIndex:2] addSubview:iterView];
        [iterView release];
    }
    i_temperatureLabel.font = [UIFont systemFontOfSize:30.f];
    
    [[i_backgroundViews objectAtIndex:2] addSubview:i_iconView];
    [i_iconView release];

    [[i_backgroundViews objectAtIndex:2] addSubview:[i_spinners objectAtIndex:2]];
    [[i_spinners objectAtIndex:2] release];
}

- (void)loadBackgroundRightSubviews {
    NSArray *subviewLabelContainers;
    if (i_dayNames || i_dayTemps || i_dayIconViews) {
        NSLog(@"NCWunderground: Trying to alloc new containers when they're non-nil, bad.");
        return;
    }
    else {
        subviewLabelContainers = [NSArray arrayWithObjects:
            (i_dayNames = [[NSMutableArray alloc] init]),
            (i_dayTemps = [[NSMutableArray alloc] init]),nil];
        i_dayIconViews = [[NSMutableArray alloc] init];
    }

    // loading spinner
    if ([i_spinners count] != 3) {
        [i_spinners removeObjectsInRange:NSMakeRange(3,[i_spinners count]-3)];
    }
    [i_spinners addObject:[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:
        UIActivityIndicatorViewStyleGray]];
    
    for (int j = 0;j < i_numberOfDays;++j) {
        for (int i = 0; i < 2; i++) {
            NSMutableArray *container = [subviewLabelContainers objectAtIndex:i];
            UILabel *newLabel = [[UILabel alloc] init];
            [container addObject:newLabel];
            [self clearLabelSmallWhiteText:newLabel];
            [newLabel setTextAlignment:NSTextAlignmentCenter];
            if (i == 1) {
                [newLabel setFont:[UIFont systemFontOfSize:13]];
            }
            [[i_backgroundViews objectAtIndex:3] addSubview:newLabel];
            [newLabel release];
        }
        UIImageView *newImageView = [[UIImageView alloc] init];
        [i_dayIconViews addObject:newImageView];
        [[i_backgroundViews objectAtIndex:3] addSubview:newImageView];
        [newImageView release];
    }
    [[i_backgroundViews objectAtIndex:3] addSubview:[i_spinners objectAtIndex:3]];
    [[i_spinners objectAtIndex:3] release];
}

- (void)updateSubviewValues {
    [self updateBackgroundLeft2SubviewValues];
    [self updateBackgroundLeftSubviewValues];
    [self updateBackgroundSubviewValues];
    [self updateBackgroundRightSubviewValues];
}

- (void)loadSubviews {
    i_spinners = [[NSMutableArray alloc] init];
    [self loadBackgroundSubviews];
    [self loadBackgroundLeftSubviews];
    [self loadBackgroundLeft2Subviews];
    [self loadBackgroundRightSubviews];
    [self positionSubviewsForBackgroundViewWidth:[UIScreen mainScreen].bounds.size.width];
}

- (void)willAnimateRotationToInterfaceOrientation:(int)arg1
{
    float screenWidth;
    if (UIInterfaceOrientationIsLandscape(arg1)) {
        screenWidth = [UIScreen mainScreen].bounds.size.height;
    }
    else {
        screenWidth = [UIScreen mainScreen].bounds.size.width;
    }

    i_view.contentOffset = CGPointMake(i_view.contentOffset.x / i_view.contentSize.width * screenWidth * 4,0);
    i_view.contentSize = CGSizeMake(screenWidth*4,[self viewHeight]);

    for (int i = 0;i<4;++i) {
        [[i_backgroundViews objectAtIndex:i] setFrame:CGRectMake(screenWidth*i+2,0,screenWidth-4,[self viewHeight])];
    }
    [self positionSubviewsForBackgroundViewWidth:screenWidth];
}

- (void)loadFullView {
    // Add subviews to i_backgroundView (or i_view) here.
    // Actually, we do it in load placeholder view because it needs to happen before
    // rotation method is called
    [self loadData:nil];
}

- (void)loadPlaceholderView {
    // This should only be a placeholder - it should not connect to any servers or perform any intense
    // data loading operations.
    //
    // All widgets are 316 points wide. Image size calculations match those of the Stocks widget.

    float screenWidth = [UIScreen mainScreen].bounds.size.width;

    i_view = [[UIScrollView alloc] initWithFrame:(CGRect){CGPointZero, {screenWidth, [self viewHeight]}}];
    UIImage *bgImg = [UIImage imageWithContentsOfFile:@"/System/Library/WeeAppPlugins/StocksWeeApp.bundle/WeeAppBackground.png"];
    UIImage *stretchableBgImg = [bgImg stretchableImageWithLeftCapWidth:floorf(bgImg.size.width / 2.f) topCapHeight:floorf(bgImg.size.height / 2.f)];
    /*NSArray *backgroundViews = [NSArray arrayWithObjects:
        (i_backgroundLeftView2 = [[UIImageView alloc] initWithImage:stretchableBgImg]),
        (i_backgroundLeftView = [[UIImageView alloc] initWithImage:stretchableBgImg]),
        (i_backgroundView = [[UIImageView alloc] initWithImage:stretchableBgImg]),
        (i_backgroundRightView = [[UIImageView alloc] initWithImage:stretchableBgImg]),nil];*/

    i_view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    i_view.contentSize = CGSizeMake(4 * screenWidth,[self viewHeight]);
    i_view.contentOffset = CGPointMake(2 * screenWidth,0.f);
    i_view.pagingEnabled = YES;
    i_view.showsHorizontalScrollIndicator = NO;

    if (i_backgroundViews) {
        NSLog(@"NCWunderground: Trying to alloc new backgroundViews when non-nil; bad");
    }
    else {
        i_backgroundViews = [[NSMutableArray alloc] init];
    }
    for (int i = 0;i<4;++i) {
        UIImageView *newBackgroundView = [[UIImageView alloc] initWithImage:stretchableBgImg];
        [newBackgroundView setUserInteractionEnabled:YES]; // allow buttons to be pressed
        [i_backgroundViews addObject:newBackgroundView];
        [newBackgroundView setFrame:
            CGRectMake(screenWidth*i+2,0,screenWidth-4,[self viewHeight])];
        [newBackgroundView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [i_view addSubview:newBackgroundView];
        [newBackgroundView release];
    }

    // load subviews
    [self loadSubviews];

    i_isDisplayed = YES;
}

- (void)unloadView {
    i_isDisplayed = NO;

    [i_backgroundViews release];
    i_backgroundViews = nil;
    [i_view release];
    i_view = nil;

    [i_dayNames release];
    i_dayNames = nil;
    [i_dayTemps release];
    i_dayTemps = nil;
    [i_dayIconViews release];
    i_dayIconViews = nil;

    [i_spinners release];
    i_spinners = nil;
    // Destroy any additional subviews you added here. Don't waste memory :(.
}

- (float)viewHeight {
    return 71.f;
}

- (void)loadData:(id)caller {
    if (i_loadingData) {
        NSLog(@"NCWunderground: tried to loadData while already loadingData");
        return;
    }
    i_loadingData = YES;
    [i_refreshButton setHidden:YES];
    for (spinner in i_spinners) {
        [spinner startAnimating];
        [spinner setHidden:NO];
    }

    NSFileManager *fileManager = [NSFileManager defaultManager];

    if ([fileManager fileExistsAtPath:i_saveFile]) {
        NSMutableDictionary *tempDict = [[NSMutableDictionary alloc] initWithContentsOfFile:i_saveFile];
        [i_savedData addEntriesFromDictionary:tempDict];
        [tempDict release];
    }
    
    if ([i_savedData objectForKey:@"last request"] == nil) {
        NSLog(@"NCWunderground: No save file found.");
    }
    else {
        [self updateSubviewValues];
    }

    NSDictionary *defaultsDom = [[NSUserDefaults standardUserDefaults] persistentDomainForName:
        @"com.amm.ncwunderground"];
    NSNumber *updateSeconds = [defaultsDom objectForKey:@"updateSeconds"];
    int updateLength;
    if (updateSeconds) {
        updateLength = [updateSeconds integerValue];
    }
    else {
        NSLog(@"NCWunderground: User's defaults contain no update delay. Defaulting to 5 minutes.");
        updateLength = 300; // default to 5 minutes
    }

    if (caller != nil || [i_savedData objectForKey:@"last request"] == nil || 
        [[NSDate date] timeIntervalSince1970] - [[i_savedData objectForKey:
            @"last request"] integerValue] >= updateLength) {
        // It's been too long since we last queried the database. Let's do it again.
        [self downloadData];
    }
    else {
        NSLog(@"NCWunderground: Using save data");
        i_loadingData = NO;
    }
}

- (void) downloadData {
    // Here we tell it to start looking for the location. Once we have the location, the locationManager:didUpdateToLocation method handles the rest of the download work
    i_locationManager.delegate = self;
    i_locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    i_locationUpdated = NO;
    [i_locationManager startUpdatingLocation];
}

// This should only ever run inside the backgroundQueue
- (void) startURLRequest {
    // get data from website by HTTP GET request
    NSHTTPURLResponse * response;
    NSError * error;

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    NSDictionary *defaultsDom = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.amm.ncwunderground"];
    NSString *apiKey = [defaultsDom objectForKey:@"APIKey"];
    if (apiKey == nil) {
        NSLog(@"NCWunderground: got null APIKey, not updating data.");
        [request release];

        // TODO
        // We shouldn't silently fail here. We should overwrite the
        // views with something instructing the user to enter the API key.

        return;
    }
    NSMutableString *urlString = [NSMutableString stringWithString:@"http://api.wunderground.com/api/"];
    [urlString appendString:apiKey];
    [urlString appendString:@"/conditions/hourly/forecast10day/q/"];
    [urlString appendString:[i_savedData objectForKey:@"latitude"]];
    [urlString appendString:@","];
    [urlString appendString:[i_savedData objectForKey:@"longitude"]];
    [urlString appendString:@".json"];
    NSLog(@"NCWunderground: Making request with url %@",urlString);
    [request setURL:[NSURL URLWithString:urlString]];
    [request setHTTPMethod:@"GET"];

    NSData *resultJSON = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    [request release];
    if (!resultJSON) {
        NSLog(@"NCWunderground: Unsuccessful connection attempt. Data not updated.");
        // TOOD: Add a red dot somewhere to indicate last update failed?
        return;
    }
    else {
        // TODO: clear the red dot?
    }

    if(NSClassFromString(@"NSJSONSerialization")) {
        NSError *error = nil;
        NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:resultJSON options:0 error:&error];
        if (error) {
            NSLog(@"NCWunderground: JSON was malformed. Bad.");
            return;
        }

        if ([jsonDict objectForKey:@"error"]) {
            NSLog(@"NCWunderground: We got a well-formed JSON, but it's an error: %@ / %@",
                [[jsonDict objectForKey:@"error"] objectForKey:@"type"],
                [[jsonDict objectForKey:@"error"] objectForKey:@"description"]);
            return;
        }

        if ([jsonDict isKindOfClass:[NSDictionary class]]) {
            NSLog(@"NCWunderground: parsing data.");
            // update last-request time
            [i_savedData setObject:[NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]] forKey:@"last request"];

            // convenience pointers
            NSDictionary *currentObservation = [jsonDict objectForKey:@"current_observation"];
            NSDictionary *dailyForecast = [[jsonDict objectForKey:@"forecast"] objectForKey:@"simpleforecast"];
            NSDictionary *displayLocation = [currentObservation objectForKey:@"display_location"];

            // Use Wunderground's parsing of lat/long into city/state/country
            [i_savedData setObject:[displayLocation objectForKey:@"city"] forKey:@"city"];
            [i_savedData setObject:[displayLocation objectForKey:@"state"] forKey:@"state"];
            [i_savedData setObject:[displayLocation objectForKey:@"country"] forKey:@"country"];

            // import current observations, daily forecast, and hourly forecast
            [i_savedData setObject:currentObservation forKey:@"current_observation"];
            [i_savedData setObject:[dailyForecast objectForKey:@"forecastday"] forKey:@"forecastday"];
            [i_savedData setObject:[jsonDict objectForKey:@"hourly_forecast"] forKey:@"hourly_forecast"];

            // save data to disk for later use
            [i_savedData writeToFile:i_saveFile atomically:YES];
            NSLog(@"NCWunderground: data saved to disk at %@",i_saveFile);

            // update the views now that we have new data. has to be done on main queue
            // this should be the last thing done on the background queue, because the main queue needs to use i_savedData
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                if (i_isDisplayed) {
                    [self updateSubviewValues];
                }
                else {
                    NSLog(@"NCWunderground: prevented it from updating subviews while not displayed");
                }
                for (spinner in i_spinners) {
                    [spinner stopAnimating];
                    [spinner setHidden:YES];
                }
                [i_refreshButton setHidden:NO];
                i_loadingData = NO;
            });
        }
        else {
            NSLog(@"NCWunderground: JSON was non-dict. Bad.");
            i_loadingData = NO;
            return;
        }
    }
    else {
        NSLog(@"NCWunderground: We don't have NSJSONSerialization. Bad.");
        i_loadingData = NO;
        return;
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {

    NSLog(@"NCWunderground: didUpdateToLocation: %@", [locations lastObject]);
    if (locations != nil) {
        [i_savedData setObject:[NSString stringWithFormat:@"%.8f", [[locations lastObject] coordinate].latitude] forKey:@"latitude"];
        [i_savedData setObject:[NSString stringWithFormat:@"%.8f", [[locations lastObject] coordinate].longitude] forKey:@"longitude"];
        if (i_locationUpdated == NO) {
            i_locationUpdated = YES;
            [i_locationManager stopUpdatingLocation];

            // start a URL request in the backgroundQueue
            dispatch_async(backgroundQueue, ^(void) {
                [self startURLRequest];
            });
        }
    }
    else {
        NSLog(@"NCWunderground: locationManager:didUpdateToLocation called but newLocation nil. Bad.");
    }
}

- (void) locationManager:(CLLocationManager *)manager didFailWithError:(NSError *) error {
    NSLog(@"NCWunderground: locationManager:didFailWithError: %@",error);
}

@end
