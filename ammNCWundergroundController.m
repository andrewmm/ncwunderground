#import "ammNCWundergroundController.h"

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
        
        i_iconMap = [[NSDictionary alloc] initWithContentsOfFile:
            [_ammNCWundergroundWeeAppBundle pathForResource:
                @"com.amm.ncwunderground.iconmap" ofType:@"plist"]];

        backgroundQueue = dispatch_queue_create("com.amm.ncwunderground.urlqueue", NULL);
    } return self;
}

- (void)dealloc { 
    // release all the views!
    [i_view release];
    [i_backgroundLeftView2 release];
    [i_backgroundLeftView release];
    [i_backgroundView release];
    [i_backgroundRightView release];

    // release some other things!
    [i_savedData release];
    [i_saveFile release];
    [i_locationManager release];
    [i_iconMap release];

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
    NSLog(@"Calculating distance between %@ and %@.",userLocation,stationLocation);
    [i_distanceToStation setText:[NSString stringWithFormat:
        @"Distance From Station: %.2lf mi",([stationLocation distanceFromLocation:
            userLocation] / 1609.344)]];

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
    
    NSString *wundergroundIconName = [[[[i_savedData objectForKey:@"current_observation"] objectForKey:@"icon_url"] lastPathComponent] stringByDeletingPathExtension];
    NSString *localIconName;
    localIconName = [[i_iconMap objectForKey:wundergroundIconName] objectForKey:@"icon"];
    i_weatherTypeLabel.text = [[i_iconMap objectForKey:wundergroundIconName] objectForKey:@"word"];
    if (localIconName == nil) {
        wundergroundIconName = [[i_savedData objectForKey:@"current_observation"] objectForKey:@"icon"];
        localIconName = [[i_iconMap objectForKey:wundergroundIconName] objectForKey:@"icon"];
    }
    i_weatherIcon = [UIImage imageWithContentsOfFile:[_ammNCWundergroundWeeAppBundle pathForResource:localIconName ofType:@"png"]];
    i_iconView.image=i_weatherIcon;
}

- (void)loadBackgroundLeft2Subviews {
    static const float r1off = 5.f; static const float r1height = 15.f; static const float r1y = r1off;
    static const float r2off = 8.f; static const float r2height = 15.f; static const float r2y = r1y+r1height+r2off;
    static const float r3off = 8.f; static const float r3height = 15.f; static const float r3y = r2y+r2height+r3off;

    // build a convenience array while alloc'ing and init'ing
    NSArray *backgroundLeft2LabelArray = [NSArray arrayWithObjects:
        (i_lastRefreshed = [[UILabel alloc] init]),
        (i_distanceToStation = [[UILabel alloc] init]),
        (i_configureInSettings = [[UILabel alloc] init]),nil];
    
    // basic tasks on all the labels
    for (UILabel *iterView in backgroundLeft2LabelArray) {
        [self clearLabelSmallWhiteText:iterView];
    }

    [i_lastRefreshed setFrame:CGRectMake(2,r1y,312,r1height)];
    [i_distanceToStation setFrame:CGRectMake(2,r2y,312,r2height)];
    [i_configureInSettings setFrame:CGRectMake(2,r3y,312,r3height)];

    for (UILabel *iterView in backgroundLeft2LabelArray) {
        [i_backgroundLeftView2 addSubview:iterView];
        [iterView release];
    }
}

- (void)loadBackgroundLeftSubviews {
    static const float r1off = 5.f; static const float r1height = 15.f; static const float r1y = r1off;
    static const float r2off = 8.f; static const float r2height = 15.f; static const float r2y = r1y+r1height+r2off;
    static const float r3off = 8.f; static const float r3height = 15.f; static const float r3y = r2y+r2height+r3off;
    static const float c0off = 2.f; static const float c0width = 45.f; static const float c0x = c0off;
    static const float c1off = 2.f; static const float c1width = 45.f; static const float c1x = c0x+c0width+c1off;
    static const float c2off = 2.f; static const float c2x = c1x+c1width+c2off;
    static const float c3off = 2.f; static const float c3width = 45.f;
    static const float c4off = 2.f; static const float c4width = 45.f;
    static const float c5off = 2.f; static const float c5width = 45.f;
    static const float rightbuff = 2.f;
    static const float c2width = 316 - c0off - c0width - c1off - c1width - c2off - c3off - c3width - c4off - c4width - c5off - c5width - rightbuff;
    static const float c3x = c2x+c2width+c3off;
    static const float c4x = c3x+c3width+c4off;
    static const float c5x = c4x+c4width+c5off;

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

    // basic tasks on all the labels
    for (UILabel *iterView in backgroundLeftLabelArray) {
        [self clearLabelSmallWhiteText:iterView];
        iterView.textAlignment = NSTextAlignmentCenter;
    }

    // row 1
    i_titleNow.frame = CGRectMake(c1x,r1y,c1width,r1height);
    i_titleLength.frame = CGRectMake(c2x,r1y,c2width,r1height);
    i_titleEnd.frame = CGRectMake(c3x,r1y,c3width,r1height);
    i_titleHigh.frame = CGRectMake(c4x,r1y,c4width,r1height);
    i_titleLow.frame = CGRectMake(c5x,r1y,c5width,r1height);

    // row 2
    i_realTempName.frame = CGRectMake(c0x,r2y,c0width,r2height);
    i_realTempNow.frame = CGRectMake(c1x,r2y,c1width,r2height);
    i_realTempSparkView = [[ASBSparkLineView alloc] initWithFrame:CGRectMake(c2x,r2y,c2width,r2height)];
    i_realTempEnd.frame = CGRectMake(c3x,r2y,c3width,r2height);
    i_realTempHigh.frame = CGRectMake(c4x,r2y,c4width,r2height);
    i_realTempLow.frame = CGRectMake(c5x,r2y,c5width,r2height);

    // row 3
    i_feelsLikeName.frame = CGRectMake(c0x,r3y,c0width,r3height);
    i_feelsLikeNow.frame = CGRectMake(c1x,r3y,c1width,r3height);
    i_feelsLikeSparkView = [[ASBSparkLineView alloc] initWithFrame:CGRectMake(c2x,r3y,c2width,r3height)];
    i_feelsLikeEnd.frame = CGRectMake(c3x,r3y,c3width,r3height);
    i_feelsLikeHigh.frame = CGRectMake(c4x,r3y,c4width,r3height);
    i_feelsLikeLow.frame = CGRectMake(c5x,r3y,c5width,r3height);

    NSArray *backgroundLeftSparkArray = [NSArray arrayWithObjects: 
        i_realTempSparkView,i_feelsLikeSparkView,nil];
    // Color all of the spark views
    for (ASBSparkLineView *iterView in backgroundLeftSparkArray) {
        iterView.penColor = [UIColor whiteColor];
        iterView.backgroundColor = [UIColor clearColor];
        iterView.showCurrentValue = NO;
    }


    // add and release all the views
    for (UILabel *iterView in backgroundLeftLabelArray) {
        [i_backgroundLeftView addSubview:iterView];
        [iterView release];
    }
    for (ASBSparkLineView *iterView in backgroundLeftSparkArray) {
        [i_backgroundLeftView addSubview:iterView];
        [iterView release];
    }
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

    float temperatureWidth = (316.f - 8 - [self viewHeight] - 1) / 2;
    float moreInfoWidth = 316.f - 8.f - [self viewHeight] - temperatureWidth;

    i_temperatureLabel.frame = CGRectMake(2.f,2.f,temperatureWidth,30.f);
    i_feelsLikeLabel.frame = CGRectMake(2.f,34.f,temperatureWidth,14.f);
    i_weatherTypeLabel.frame = CGRectMake(2.f,50.f,temperatureWidth,15.f);
    i_locationLabel.frame = CGRectMake(6.f + temperatureWidth + [self viewHeight],5.f,moreInfoWidth,15.f);
    i_humidityLabel.frame = CGRectMake(6.f + temperatureWidth + [self viewHeight],28.f,moreInfoWidth,15.f);
    i_windLabel.frame = CGRectMake(6.f + temperatureWidth + [self viewHeight],51.f,moreInfoWidth,15.f);

    i_iconView = [[UIImageView alloc] init];
    i_iconView.frame = CGRectMake(4.f + temperatureWidth,0.f,[self viewHeight],[self viewHeight]);

    for (UILabel *iterView in backgroundLabelArrayRightCol) {
        [iterView setTextAlignment:NSTextAlignmentRight];
    }
    for (UILabel *iterView in [backgroundLabelArrayLeftCol arrayByAddingObjectsFromArray:backgroundLabelArrayRightCol]) {
        [self clearLabelSmallWhiteText:iterView];
        [i_backgroundView addSubview:iterView];
        [iterView release];
    }
    i_temperatureLabel.font = [UIFont systemFontOfSize:30.f];
    
    [i_backgroundView addSubview:i_iconView];
    [i_iconView release];
}

- (void)updateSubviewValues {
    [self updateBackgroundLeft2SubviewValues];
    [self updateBackgroundLeftSubviewValues];
    [self updateBackgroundSubviewValues];
}

- (void)loadSubviews {
    [self loadBackgroundSubviews];
    [self loadBackgroundLeftSubviews];
    [self loadBackgroundLeft2Subviews];
}

- (void)loadFullView {
    // Add subviews to i_backgroundView (or i_view) here.
    [self loadSubviews];
    [self loadData];
}

- (void)loadPlaceholderView {
    // This should only be a placeholder - it should not connect to any servers or perform any intense
    // data loading operations.
    //
    // All widgets are 316 points wide. Image size calculations match those of the Stocks widget.

    UIDevice *device = [UIDevice currentDevice];
    [device beginGeneratingDeviceOrientationNotifications];
    float screenWidth;
    if (UIDeviceOrientationIsPortrait(device.orientation))
        screenWidth = [UIScreen mainScreen].bounds.size.width;
    else
        screenWidth = [UIScreen mainScreen].bounds.size.height;
    NSLog(@"NCWunderground: screen width is %f",screenWidth);

    i_view = [[UIScrollView alloc] initWithFrame:(CGRect){CGPointZero, {316.f, [self viewHeight]}}];
    i_view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    i_view.contentSize = CGSizeMake(1280.f,[self viewHeight]);
    i_view.pagingEnabled = YES;
    i_view.contentOffset = CGPointMake(640.f,0.f);
    i_view.showsHorizontalScrollIndicator = NO;

    UIImage *bgImg = [UIImage imageWithContentsOfFile:@"/System/Library/WeeAppPlugins/StocksWeeApp.bundle/WeeAppBackground.png"];
    UIImage *stretchableBgImg = [bgImg stretchableImageWithLeftCapWidth:floorf(bgImg.size.width / 2.f) topCapHeight:floorf(bgImg.size.height / 2.f)];

    NSArray *backgroundViews = [NSArray arrayWithObjects:
        (i_backgroundLeftView2 = [[UIImageView alloc] initWithImage:stretchableBgImg]),
        (i_backgroundLeftView = [[UIImageView alloc] initWithImage:stretchableBgImg]),
        (i_backgroundView = [[UIImageView alloc] initWithImage:stretchableBgImg]),
        (i_backgroundRightView = [[UIImageView alloc] initWithImage:stretchableBgImg]),nil];

    i_backgroundLeftView2.frame = CGRectMake(2,0,312.f,[self viewHeight]);
    i_backgroundLeftView.frame = CGRectMake(322.f,0,312.f,[self viewHeight]);
    i_backgroundView.frame = CGRectMake(642.f,0, 312.f,[self viewHeight]);
    i_backgroundRightView.frame = CGRectMake(962.f,0,312.f,[self viewHeight]);

    for (UIImageView *iterView in backgroundViews) {
        iterView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [i_view addSubview:iterView];
    }
}

- (void)unloadView {
    [i_view release];
    i_view = nil;
    [i_backgroundLeftView2 release];
    i_backgroundLeftView2 = nil;
    [i_backgroundLeftView release];
    i_backgroundLeftView = nil;
    [i_backgroundView release];
    i_backgroundView = nil;
    [i_backgroundRightView release];
    i_backgroundRightView = nil;
    // Destroy any additional subviews you added here. Don't waste memory :(.
}

- (float)viewHeight {
    return 71.f;
}

// new functions

- (void)loadData {

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

    NSDictionary *defaultsDom = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.amm.ncwunderground"];
    NSNumber *updateSeconds = [defaultsDom objectForKey:@"updateSeconds"];
    int updateLength;
    if (updateSeconds) {
        updateLength = [updateSeconds integerValue];
    }
    else {
        NSLog(@"NCWunderground: User's defaults contain no update delay. Defaulting to 5 minutes.");
        updateLength = 300; // default to 5 minutes
    }

    if ([i_savedData objectForKey:@"last request"] == nil || [[NSDate date] timeIntervalSince1970] - [[i_savedData objectForKey:@"last request"] integerValue] >= updateLength) {
        // It's been too long since we last queried the database. Let's do it again.
        [self downloadData];
    }
    else {
        NSLog(@"NCWunderground: Using save data");
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
    if (!resultJSON) {
        NSLog(@"NCWunderground: Unsuccessful connection attempt. Data not updated.");
        [request release];
        // TOOD: Add a red dot somewhere to indicate last update failed?
        return;
    }
    else {
        // TODO: clear the red dot?
    }
    [request release];

    if(NSClassFromString(@"NSJSONSerialization")) {
        NSError *error = nil;
        NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:resultJSON options:0 error:&error];
        if (error) {
            NSLog(@"NCWunderground: JSON was malformed. Bad.");
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
                [self updateSubviewValues];
            });
        }
        else {
            NSLog(@"NCWunderground: JSON was non-dict. Bad.");
            return;
        }
    }
    else {
        NSLog(@"NCWunderground: We don't have NSJSONSerialization. Bad.");
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
