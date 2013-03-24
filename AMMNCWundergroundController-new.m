#import "AMMNCWundergroundController-new.h"

@implementation AMMNCWundergroundController

@synthesize saveFile=i_saveFile;
@synthesize locationUpdated=i_locationUpdated;
@synthesize loadingData=i_loadingData;
@synthesize baseWidth=i_baseWidth;
@synthesize currentWidth=i_currentWidth;
@synthesize viewHeight=i_viewHeight;

+ (void)initialize {
    _ammNCWundergroundWeeAppBundle = [[NSBundle bundleForClass:[self class]] retain];
}

- (id)init {
    if ((self = [super init]) != nil) {
        i_viewHeight = 71;
        i_baseWidth = [UIScreen mainScreen].bounds.size.width;

        i_model = [[AMMNCWundergroundModel alloc] init];

        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                             NSUserDomainMask, YES);
        i_saveFile = [[NSString alloc] initWithString:
            [[paths objectAtIndex:0] stringByAppendingString:
                @"/com.amm.ncwunderground.save.plist"]];

        i_locationManager = [[CLLocationManager alloc] init];
        i_locationUpdated = NO;

        i_loadingData = NO;

        i_iconMap = [[NSDictionary alloc] initWithContentsOfFile:
            [_ammNCWundergroundWeeAppBundle pathForResource:
                @"icons/com.amm.ncwunderground.iconmap" ofType:@"plist"]];
    }
    return self;
}

- (void)dealloc {
    [i_view release];
    i_view = nil;

    [i_model release];
    i_model = nil;

    [i_saveFile relase];
    i_saveFile = nil;

    [i_locationManager release];
    i_locationManager = nil;

    [i_iconMap release];
    i_iconMap = nil;

    [super dealloc];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    float screenWidth;
    if (UIInterfaceOrientationIsLandscape(arg1)) {
        [i_view setScreenWidth:[UIScreen mainScreen].bounds.size.height];
    }
    else {
        [i_view setScreenWidth:[UIScreen mainScreen].bounds.size.width];
    }
}

- (void)loadFullView {
    [self addSubviewsToView];
    [self loadData:nil];
}

- (void)loadPlaceholderView {
    i_currentWidth = i_baseWidth;
    i_view = [[AMMNCWundergroundView alloc] initWithPages:4
            width:i_currentWidth height:i_viewHeight];
}

- (void)unloadView {
    [i_view release];
    i_view = nil;
}

/* Does: adds all the specific subviews to i_view
         hooks subview values up to i_model */
- (void)addSubviewsToView {
    // -- details page -- //

    // labels
    for (int i=0; i < 3; ++i) {
        UILabel *newLabel = [[UILabel alloc] init];
        [newLabel setBackgroundColor:[UIColor clearColor]];
        [newLabel setTextColor:[UIColor whiteColor]];
        [newLabel setFont:[UIFont systemFontOfSize:14]];
        [newLabel setTextAlignment:NSTextAlignmentCenter];
        [newLabel setFrame:CGRectMake(0.2*[self baseWidth],5+23*i,
            0.6*[self baseWidth],15)]
        if (i == 2) {
            [newLabel setText:@"Configure options in Settings app."];
        }
        [i_view addSubview:newLabel toPage:0 withTag:(i+1) manualRefresh:NO];
        [newLabel release];
    }

    // refresh button
    UIButton *refreshButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *refreshImage = [UIImage imageWithContentsOfFile:
        [_ammNCWundergroundWeeAppBundle pathForResource:
                @"refresh" ofType:@"png"]];
    [refreshButton setBackgroundImage:refreshImage forState:UIControlStateNormal];
    [refreshButton addTarget:self action:@selector(loadData:) 
        forControlEvents:UIControlEventTouchUpInside];
    [refreshButton setFrame:CGRectMake(0.85*[self baseWidth],
        ([self viewHeight] - 0.1*[self baseWidth])/2,
        0.1*[self baseWidth],0.1*[self baseWidth])]
    [i_view addSubview:refreshButton toPage:0 withTag:4 manualRefresh:NO];
    // don't need to release refresh button

    // -- hourly forecast / sparklines page -- //

    // useful formatting constants
    float labelWidth = 0.14 * [self baseWidth];
    float colBuffer = 0.00625 * [self baseWidth];
    float sparkWidth = [self baseWidth] - labelWidth * 5 - colBuffer * 7;
    float rowHeight = 15;
    float rowFirstBuffer = 5;
    float rowBuffer = 8;

    for (int i=0; i < 3; ++i) { // rows
        float y = rowFirstBuffer + i * (rowHeight + rowBuffer);
        for (int j=0; j < 5; ++j) { // columns
            // create tag of form 1(i+1)(j+1)
            int tag = 100 + (i+1)*10 + (j+1);

            UILabel *newLabel = [[UILabel alloc] init];
            [newLabel setBackgroundColor:[UIColor clearColor]];
            [newLabel setTextColor:[UIColor whiteColor]];
            [newLabel setFont:[UIFont systemFontOfSize:14]];
            [newLabel setTextAlignment:NSTextAlignmentCenter];

            // calculate locations
            if (i == 0) {
                float x = colBuffer + (colBuffer + labelWidth) * (j+1)
                if (j > 1) {
                    x = x - labelWidth + sparkWidth;
                }
                else if (j == 1) {
                    [newLabel setFrame:CGRectMake(x,y,sparkWidth,rowHeight)];
                }
                else {
                    [newLabel setFrame:CGRectMake(x,y,labelWidth,rowHeight)];
                }
            }
            else {
                float x = colBuffer + (colBuffer + labelWidth) * j;
                if (j > 1)
                    x += colBuffer + sparkWidth;
                [newLabel setFrame:CGRectMake(x,y,labelWidth,rowHeight)];
            }

            [i_view addSubview:newLabel toPage:1 withTag:tag manualRefresh:NO];
            [newLabel release];
        }

        //sparkviews
        if (i > 0) {
            ASBSparkLineView *sparkView = [[ASBSparkLineView alloc] init];
            [sparkView setPenColor:[UIColor whiteColor]];
            [sparkView setBackgroundColor:[UIColor clearColor]];
            [sparkView setShowCurrentValue:NO];

            float x = colBuffer * 3 + labelWidth * 2;
            [sparkView setFrame:CGRectMake(x,y,sparkWidth,rowHeight)];

            [i_view addSubview:sparkView toPage:1 withTag:(100 + (i+1)*10)
                manualRefresh:YES];
            [sparkView release];
        }
        
    }

    // -- current conditions page -- //

    labelWidth = ([self baseWidth] - 4 - 4 * colBuffer - [self viewHeight]) / 2;
    leftHeight = ([self viewHeight] - rowFirstBuffer * 2 - rowBuffer * 2) / 4;
    rightHeight = leftHeight * 4 / 3;

    float xArray[] = {colBuffer,colBuffer * 3 + labelWidth + [self viewHeight]};
    float heightArray [][] = {{leftHeight * 2, rightHeight},
        {leftHeight,rightHeight},{leftHeight,rightHeight}};
    float yArray[][] = {{rowFirstBuffer,rowFirstBuffer},
        {rowFirstBuffer + heightArray[0][0] + rowBuffer,
            rowFirstBuffer + heightArray[0][2] + rowBuffer},
        {rowFirstBuffer + heightArray[0][0] + heightArray[1][0] + rowBuffer * 2,
            rowFirstBuffer + heightArray[0][2] + heightArray[1][2] + rowBuffer * 2}};
    for (int i=0; i < 3; ++i) { // row
        for (int j = 0; j < 2; ++j) { // column
            UILabel *newLabel = [[UILabel alloc] init];
            [newLabel setBackgroundColor:[UIColor clearColor]];
            [newLabel setTextColor:[UIColor whiteColor]];
            [newLabel setFont:[UIFont systemFontOfSize:(heightArray[i][j]-1)]];
            if (j == 1)
                [newLabel setTextAlignment:NSTextAlignmentRight];
            [newLabel setFrame:CGRectMake(xArray[j],yArray[i][j],
                heightArray[i][j],labelWidth)];

            [i_view addSubview:newLabel toPage:2 withTag:
                (200 + (i+1)*10 + (j+1)) manualRefresh:NO];
            [newLabel release];
        }
    }

    CGRect iconRect = CGRectMake(colBuffer * 2 + labelWidth,rowFirstBuffer,
        [self viewHeight],[self viewHeight]);

    UIImageView *iconBackView = [[UIImageView alloc] init];
    [iconBackView setFrame:iconRect];
    [i_view addSubview:iconBackView toPage:2 withTag:200 manualRefresh:YES];
    [iconBackView release];

    UIImageView *iconFrontView = [[UIImageView alloc] init];
    [iconFrontView setFrame:iconRect];
    [i_view addSubview:iconFrontView toPage:2 withTag:201 manualRefresh:YES];
    [iconFrontView release];

    // -- daily forecast page -- //

    float dayWidth = ([self baseWidth] - 4 - colBuffer * ((float)[self numberOfDays] + 1)) / (float)[self numberOfDays];
    float rowBuffer = 3;
    float iconDims = [self viewHeight] - 15 * 2 - rowBuffer * 4;
    if (dayWidth < iconDims)
        iconDims = dayWidth;
    float iconY = 15 * 2 + rowBuffer * 3 + ([self viewHeight] - 15 * 2 - rowBuffer * 4 - iconDims) / 2;

    for (int j = 0; j < [self numberOfDays]; ++j) { // columns
        for (int i = 0; i < 2; ++i) { // rows
            UILabel *newLabel = [[UILabel alloc] init];
            [newLabel setBackgroundColor:[UIColor clearColor]];
            [newLabel setTextColor:[UIColor whiteColor]];
            [newLabel setFont:[UIFont systemFontOfSize:14]];
            [newLabel setTextAlignment:NSTextAlignmentCenter];
            [newLabel setFrame:CGRectMake(colBuffer + j * (colBuffer + dayWidth),
                rowBuffer + (rowBuffer + 15) * i, dayWidth, 15)];
            [i_view addSubview:newLabel toPage:3 withTag:
                (300 + (i+1)*10 + (j+1)) manualRefresh:NO];
            [newLabel release];
        }

        UIImageView *dayIconView = [[UIImageView alloc] init];
        [dayIconView setFrame:CGRectMake(colBuffer + j * (colBuffer + dayWidth),
            iconY, iconDims, iconDims)];
        [i_view addSubview:dayIconView toPage:3 withTag:
            (300 + 30 + (j+1)) manualRefresh:YES];
    }
}

/* Takes: object which is responsible for calling it
          SPECIAL: iff caller==nil, this will respect user's preferences re: delay on reloading data */
// Does: tells the model to reload the data
- (void)loadData:(id)caller {
    if (i_loadingData) {
        NSLog(@"NCWunderground: Cannot reload data, because data is already loading.");
        return;
    }
    i_loadingData = YES;
    [[i_view getSubviewFromPage:0 withTag:3] setHidden:YES]; // hide the refresh button
    [i_view setLoading:YES];

    // Try to load in save data
    if ([i_model loadSaveData:i_saveFile]) {
        // loading the save file succeeded
        NSLog(@"NCWunderground: Save file loaded, updating views.");
        [self associateModelToView];

        // If caller==nil, check update delay preferences
        if (!caller) {
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

            if ([[NSDate date] timeIntervalSince1970] - [i_model lastRequestInt] >= updateLength) {
                NSLog(@"NCWunderground: Too soon to download data again. Done updating.");
                [[i_view getSubviewFromPage:0 withTag:4] setHidden:NO]; // hide the refresh button
                [i_view setLoading:NO];
                i_loadingData = NO;
                return;
            }
        }
    }
    else {
        NSLog(@"NCWunderground: No save file found.");
    }

    [i_model downloadData];
}

// Does: after data model has been updated, loads data into views
- (void)associateModelToView {
    // -- details page -- //

    // "Last Refreshed"
    NSDate *lastRefreshedDate = [NSDate dateWithTimeIntervalSince1970:[i_model lastRequestInt]];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"h:mm:ss a"];
    [[i_view getSubviewFromPage:0 withTag:1] setText:[NSString stringWithFormat:
        @"Last Refreshed: %@",[dateFormatter stringFromDate:lastRefreshedDate]]];
    [dateFormatter release];

    // "Distance From Station"
    CLLocation *userLocation = [[CLLocation alloc] initWithLatitude:
        [i_model latitudeDouble] longitude:[i_model longitudeDouble]];
    CLLocation *stationLocation = [[CLLocation alloc] initWithLatitude:
        [i_model obsLatitudeDouble] longitude:[i_model obsLongitudeDouble]];
    [[i_view getSubviewFromPage:0 withTag:2] setText:[NSString stringWithFormat:
        @"Distance From Station: %.2lf mi",([stationLocation distanceFromLocation:
            userLocation] / 1609.344)]];
    [userLocation release];
    [stationLocation release];

    // -- hourly forecast page -- //
    int intervalLength = [self hourlyForecastLength];

    NSMutableArray *realTempSparkData = [i_model hourlyTempNumberArrayF:
        0 length:intervalLength];
    NSMutableArray *feelsLikeSparkData = [i_model hourlyFeelsNumberArrayF:
        0 length:intervalLength];

    ASBSparkLineView *realTempSparkView = [i_view getSubviewFromPage:1 withTag:120];
    ASBSparkLineView *feelsLikeSparkView = [i_view getSubviewFromPage:1 withTag:130];

    [realTempSparkView setDataValues:realTempSparkData];
    [feelsLikeSparkView setDataValues:feelsLikeSparkData];
    
    NSArray *page1TextArray = [NSArray arrayWithObjects:
        [i_model hourlyTime12HrString:0],
        [NSString stringWithFormat:@"%d hr",intervalLength],
        [i_model hourlyTime12HrString:(intervalLength - 1)],
        @"High",@"Low",@"Temp",[i_model hourlyTempStringF:0],
        [i_model hourlyTempStringF:(intervalLength-1)],
        [NSString stringWithFormat:@"%@ °F",[[realTempSparkView dataMaximum] stringValue]],
        [NSString stringWithFormat:@"%@ °F",[[realTempSparkView dataMinimum] stringValue]],
        @"Like",[i_model hourlyFeelsStringF:0],
        [i_model hourlyFeelsStringF:(intervalLength-1)],
        [NSString stringWithFormat:@"%@ °F",[[feelsLikeSparkView dataMaximum] stringValue]],
        [NSString stringWithFormat:@"%@ °F",[[feelsLikeSparkView dataMinimum] stringValue]],
        nil];

    for (int i = 0; i < 3; ++i) {
        for (int j = 0; j < 5; ++j) {
            UILabel *label = [i_view getSubviewFromPage:1 withTag:
                (100 + 10 * (i+1) + (j+1))];
            [label setText:[page1TextArray objectAtIndex:(i * 5 + j)]];
        }
    }

    // -- current conditions page -- //

    NSString *remoteIconName = [i_model currentConditionsIconName];
    NSDictionary *localIconInfo = [i_iconMap objectForKey:remoteIconName];

    NSArray *page2TextArray = [NSArray arrayWithObjects:
        [i_model currentTempStringF],[i_model currentLocationString],
        [NSString stringWithFormat:@"Feels Like %@",
            [i_model currentFeelsStringF]],
        [NSString stringWithFormat:@"Humidity: %@",
            [i_model currentHumidityString]],
        [localIconInfo objectForKey:@"word"],
        [NSString stringWithFormat:@"Wind: %@",
            [i_model currentWindMPHString]],nil];

    for (int i = 0; i < 3; ++i) {
        for (int j = 0; j < 2; ++j) {
            UILabel *label = [i_view getSubviewFromPage:2 withTag:
                (200 + 10 * (i+1) + (j+1))];
            [label setText:[page2TextArray objectAtIndex:(i*2+j)]];
        }
    }

    id localIcon = [localIconInfo objectForKey:@"icon"];
    UIImage *weatherIcon;
    UIImage *weatherIconFront;
    if ([localIcon isKindOfClass:[NSString class]]) {
        weatherIcon = [UIImage imageWithContentsOfFile:
            [_ammNCWundergroundWeeAppBundle pathForResource:
                [NSString stringWithFormat:
                    @"icons/%@",localIcon] ofType:@"png"]];
    }
    else {
        weatherIcon = [UIImage imageWithContentsOfFile:
            [_ammNCWundergroundWeeAppBundle pathForResource:
                [NSString stringWithFormat:
                    @"icons/%@",[localIcon objectForKey:
                        @"back"]] ofType:@"png"]];
        weatherIconFront = [UIImage imageWithContentsOfFile:
            [_ammNCWundergroundWeeAppBundle pathForResource:
                [NSString stringWithFormat:
                    @"icons/%@",[localIcon objectForKey:
                        @"front"]] ofType:@"png"]];
    }

    [[i_view getSubviewFromPage:2 withTag:200] setImage:weatherIcon];
    [[i_view getSubviewFromPage:2 withTag:201] setImage:weatherIconFront];

    // -- daily forecast page -- //

    for (int j = 0; j < [self numberOfDays]; ++j) {
        [[i_view getSubviewFromPage:3 withTag:(310 + (j+1))] setText:
            [i_model dailyDayShortString:j]];
        [[i_view getSubviewFromPage:3 withTag:(320 + (j+1))] setText:
            [NSString stringWithFormat:@"%@/%@ (%@)",
                [i_model dailyHighStringF:j],[i_model dailyLowStringF:j],
                [i_model dailyPOPString:j]]];

        remoteIconName = [i_model dailyConditionsIconName:j];
        localIconInfo = [i_iconMap objectForKey:remoteIconName];
        localIcon = [localIconInfo objectForKey:@"icon"];
        weatherIcon = [UIImage imageWithContentsOfFile:
            [_ammNCWundergroundWeeAppBundle pathForResource:
                [NSString stringWithFormat:
                    @"icons/%@",localIcon] ofType:@"png"]];
        [[i_view getSubviewFromPage:3 withTag:(330 + (j+1))] setImage:
            weatherIcon];
    }
}

// Returns: number of days in daily forecast (4)
- (int)numberOfDays {
    return 4;
}

// Returns: user preferences for number of hours to display
- (int)hourlyForecastLength {
    NSDictionary *defaultsDom = [[NSUserDefaults standardUserDefaults] 
        persistentDomainForName:@"com.amm.ncwunderground"];
    NSNumber *hourlyLength = [defaultsDom objectForKey:@"hourlyLength"];
    if (hourlyLength) {
        return [hourlyLength integerValue];
    }
    else {
        NSLog(@"NCWunderground: user defaults contain no hourly forecast length field. Defaulting to 12 hours.");
        return 12;
    }
}

@end
