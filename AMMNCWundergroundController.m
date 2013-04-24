#import <CoreLocation/CoreLocation.h>
#import "Sparklines/Sparklines/ASBSparkLineView.h"
#import "AMMNCWundergroundView.h"
#import "AMMNCWundergroundModel.h"
#import <dispatch/dispatch.h>

#import "AMMNCWundergroundController.h"

static NSBundle *_ammNCWundergroundWeeAppBundle = nil;

@interface AMMNCWundergroundController ()

@property (nonatomic, strong) AMMNCWundergroundView *view;
@property (nonatomic, strong) AMMNCWundergroundModel *model;
@property (nonatomic, copy) NSString *saveDirectory;
@property (nonatomic, copy) NSString *saveFile;
@property (atomic, strong) CLLocationManager *locationManager;
@property (nonatomic, assign) float baseWidth;
@property (nonatomic, assign) float currentWidth;
@property (nonatomic, assign) float viewHeight;
@property (nonatomic, copy) NSDictionary *iconMap;

@end

@implementation AMMNCWundergroundController

@synthesize view=i_view;
@synthesize model=i_model;
@synthesize saveDirectory = i_saveDirectory;
@synthesize saveFile=i_saveFile;
@synthesize locationManager=i_locationManager;
@synthesize locationUpdated=i_locationUpdated;
@synthesize baseWidth=i_baseWidth;
@synthesize currentWidth=i_currentWidth;
@synthesize viewHeight=i_viewHeight;
@synthesize iconMap=i_iconMap;

+ (void)initialize {
    _ammNCWundergroundWeeAppBundle = [NSBundle bundleForClass:[self class]];
}

- (id)init {
    if ((self = [super init]) != nil) {
        i_viewHeight = 71;
        i_baseWidth = [UIScreen mainScreen].bounds.size.width;

        i_model = [[AMMNCWundergroundModel alloc] initWithController:self];

        i_saveDirectory = @"/var/mobile/Library/Application Support/NCWunderground/";
        i_saveFile = @"weather.save.plist";

        i_locationManager = [[CLLocationManager alloc] init];
        i_locationUpdated = NO;

        i_iconMap = [[NSDictionary alloc] initWithContentsOfFile:[_ammNCWundergroundWeeAppBundle pathForResource:@"icons/com.amm.ncwunderground.iconmap"
                                                                                                          ofType:@"plist"]];
    }
    return self;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
        [self.view setScreenWidth:[UIScreen mainScreen].bounds.size.height];
    }
    else {
        [self.view setScreenWidth:[UIScreen mainScreen].bounds.size.width];
    }
}

- (void)loadFullView {
    if (self.currentWidth != self.baseWidth) {
        NSDictionary *defaultsDom = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.amm.ncwunderground"];
        int cur_page = [(NSNumber *)[defaultsDom objectForKey:@"cur_page"] intValue] + 2;
        // We store it as -2 so 0 corresponds to default

        self.view = [[AMMNCWundergroundView alloc] initWithPages:4
                                                          atPage:cur_page
                                                           width:self.currentWidth
                                                          height:self.viewHeight];
    }
    [self addSubviewsToView];
    [self loadData:nil];
}

- (void)loadPlaceholderView {
    NSDictionary *defaultsDom = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.amm.ncwunderground"];
    int cur_page = [(NSNumber *)[defaultsDom objectForKey:@"cur_page"] intValue] + 2;
    // We store it as -2 so 0 corresponds to default

    self.currentWidth = self.baseWidth;
    self.view = [[AMMNCWundergroundView alloc] initWithPages:4
                                                      atPage:cur_page
                                                       width:self.currentWidth
                                                      height:self.viewHeight];
}

- (void)unloadView {
    NSDictionary *oldDefaultsDom = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.amm.ncwunderground"];
    NSMutableDictionary *newDefaultsDom = [NSMutableDictionary dictionaryWithDictionary:oldDefaultsDom];
    [newDefaultsDom setObject:[NSNumber numberWithFloat:([self.view contentOffset].x / self.currentWidth - 2)]
                                                 forKey:@"cur_page"]; // We store it as -2 so that 0 corresponds to main page
    [[NSUserDefaults standardUserDefaults] setPersistentDomain:newDefaultsDom
                                                       forName:@"com.amm.ncwunderground"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    self.view = nil;
}

/* Does: adds all the specific subviews to self.view
         hooks subview values up to self.model */
- (void)addSubviewsToView {
    // -- details page -- //

    // labels
    for (int i=0; i < 3; ++i) {
        UILabel *newLabel = [[UILabel alloc] init];
        [newLabel setBackgroundColor:[UIColor clearColor]];
        [newLabel setTextColor:[UIColor whiteColor]];
        [newLabel setFont:[UIFont systemFontOfSize:14]];
        [newLabel setTextAlignment:NSTextAlignmentCenter];
        [newLabel setFrame:CGRectMake(0.1875*self.baseWidth,5+23*i,0.625*self.baseWidth,15)];
        if (i == 2) {
            [newLabel setText:@"Configure options in Settings."];
        }
        [self.view addSubview:newLabel toPage:0 withTag:(i+1) manualRefresh:NO];
    }

    // refresh button
    UIButton *refreshButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *refreshImage = [UIImage imageWithContentsOfFile:
        [_ammNCWundergroundWeeAppBundle pathForResource:@"refresh"
                                                 ofType:@"png"]];
    [refreshButton setBackgroundImage:refreshImage forState:UIControlStateNormal];
    [refreshButton addTarget:self
                      action:@selector(loadData:) 
            forControlEvents:UIControlEventTouchUpInside];
    [refreshButton setFrame:CGRectMake(0.859375*self.baseWidth, (self.viewHeight - 0.1*self.baseWidth)/2,
                                       0.09375*self.baseWidth,0.09375*self.baseWidth)];
    [self.view addSubview:refreshButton toPage:0 withTag:4 manualRefresh:NO];

    // -- hourly forecast / sparklines page -- //

    // useful formatting constants
    float labelWidth = 0.14 * self.baseWidth;
    float colBuffer = 0.00625 * self.baseWidth;
    float sparkWidth = self.baseWidth - labelWidth * 5 - colBuffer * 7;
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
                float x = colBuffer + (colBuffer + labelWidth) * (j+1);
                if (j > 1) {
                    x = x - labelWidth + sparkWidth;
                    [newLabel setFrame:CGRectMake(x,y,labelWidth,rowHeight)];
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

            [self.view addSubview:newLabel
                           toPage:1
                          withTag:tag
                    manualRefresh:NO];
        }

        //sparkviews
        if (i > 0) {
            ASBSparkLineView *sparkView = [[ASBSparkLineView alloc] init];
            [sparkView setPenColor:[UIColor whiteColor]];
            [sparkView setBackgroundColor:[UIColor clearColor]];
            [sparkView setShowCurrentValue:NO];
            sparkView.labelText = @"";

            float x = colBuffer * 3 + labelWidth * 2;
            [sparkView setFrame:CGRectMake(x,y,sparkWidth,rowHeight)];

            [self.view addSubview:sparkView
                           toPage:1
                          withTag:(100 + (i+1)*10)
                    manualRefresh:YES];
        }
        
    }

    // -- current conditions page -- //

    rowFirstBuffer = 2;
    rowBuffer = 3;

    labelWidth = (self.baseWidth - 4 - 4 * colBuffer - self.viewHeight) / 2;
    float leftHeight = (self.viewHeight - rowFirstBuffer * 2 - rowBuffer * 2) / 4;
    float rightHeight = leftHeight * 4 / 3;

    float xArray[] = {colBuffer,colBuffer * 3 + labelWidth + self.viewHeight};
    float heightArray [3][2] = {{leftHeight * 2, rightHeight},
        {leftHeight,rightHeight},{leftHeight,rightHeight}};
    float yArray[3][2] = {{rowFirstBuffer,rowFirstBuffer},
        {rowFirstBuffer + heightArray[0][0] + rowBuffer,
            rowFirstBuffer + heightArray[0][1] + rowBuffer},
        {rowFirstBuffer + heightArray[0][0] + heightArray[1][0] + rowBuffer * 2,
            rowFirstBuffer + heightArray[0][1] + heightArray[1][1] + rowBuffer * 2}};
    for (int i=0; i < 3; ++i) { // row
        for (int j = 0; j < 2; ++j) { // column
            UILabel *newLabel = [[UILabel alloc] init];
            [newLabel setBackgroundColor:[UIColor clearColor]];
            [newLabel setTextColor:[UIColor whiteColor]];
            if (j == 1) {
                [newLabel setFont:[UIFont systemFontOfSize:14.f]];
                [newLabel setTextAlignment:NSTextAlignmentRight];
            }
            else
                [newLabel setFont:[UIFont systemFontOfSize:(heightArray[i][0]-0.5)]];
            [newLabel setFrame:CGRectMake(xArray[j],yArray[i][j],
                labelWidth,heightArray[i][j])];

            [self.view addSubview:newLabel
                        toPage:2
                       withTag:(200 + (i+1)*10 + (j+1))
                 manualRefresh:NO];
        }
    }

    CGRect iconRect = CGRectMake(colBuffer * 2 + labelWidth,rowFirstBuffer,
                                 self.viewHeight,self.viewHeight);

    UIImageView *iconBackView = [[UIImageView alloc] init];
    [iconBackView setFrame:iconRect];
    [self.view addSubview:iconBackView toPage:2 withTag:200 manualRefresh:YES];

    UIImageView *iconFrontView = [[UIImageView alloc] init];
    [iconFrontView setFrame:iconRect];
    [self.view addSubview:iconFrontView toPage:2 withTag:201 manualRefresh:YES];

    // put a transparent button on top of the icon to open the url
    UIButton *urlButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [urlButton addTarget:self
                  action:@selector(openForecastURL)
        forControlEvents:UIControlEventTouchUpInside];
    [urlButton setFrame:iconRect];
    [self.view addSubview:urlButton toPage:2 withTag:202 manualRefresh:NO];

    // -- daily forecast page -- //

    float dayWidth = (self.baseWidth - 4 - colBuffer * ((float)[self numberOfDays] + 1)) / (float)[self numberOfDays];
    rowBuffer = 3;
    float iconDims = self.viewHeight - 15 * 2 - rowBuffer * 4;
    if (dayWidth < iconDims)
        iconDims = dayWidth;
    float iconY = 15 * 2 + rowBuffer * 3 + (self.viewHeight - 15 * 2 - rowBuffer * 4 - iconDims) / 2;

    for (int j = 0; j < [self numberOfDays]; ++j) { // columns
        for (int i = 0; i < 2; ++i) { // rows
            UILabel *newLabel = [[UILabel alloc] init];
            [newLabel setBackgroundColor:[UIColor clearColor]];
            [newLabel setTextColor:[UIColor whiteColor]];
            if (i == 0)
                [newLabel setFont:[UIFont systemFontOfSize:14]];
            else
                [newLabel setFont:[UIFont systemFontOfSize:13.5]];
            [newLabel setTextAlignment:NSTextAlignmentCenter];
            [newLabel setFrame:CGRectMake(colBuffer + j * (colBuffer + dayWidth),
                rowBuffer + (rowBuffer + 15) * i, dayWidth, 15)];
            [self.view addSubview:newLabel
                           toPage:3
                          withTag:(300 + (i+1)*10 + (j+1))
                    manualRefresh:NO];
        }

        CGRect iconRect = CGRectMake(colBuffer + j * (colBuffer + dayWidth) + (dayWidth - iconDims) / 2,
            iconY, iconDims, iconDims);

        UIImageView *dayIconView = [[UIImageView alloc] init];
        UIImageView *dayIconViewBack = [[UIImageView alloc] init];
        [dayIconView setFrame:iconRect];
        [self.view addSubview:dayIconViewBack
                       toPage:3
                      withTag:(330 + (j+1))
                manualRefresh:YES];
        [self.view addSubview:dayIconView
                       toPage:3
                      withTag:(340 + (j+1))
                manualRefresh:YES];
    }
}

/* Takes: object which is responsible for calling it
          SPECIAL: iff caller==nil, this will respect user's preferences re: delay on reloading data */
// Does: tells the model to reload the data
- (void)loadData:(id)caller {
    NSLog(@"NCWunderground: Loading data.");
    [self.view setLoading:YES];

    // Try to load in save data
    if ([self.model loadSaveData:self.saveFile inDirectory:self.saveDirectory]) {
        // loading the save file succeeded
        NSLog(@"NCWunderground: Save file loaded, updating views.");
        [self associateModelToView];

        // If caller==nil, check update delay preferences
        if (!caller) {
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

            if ([[NSDate date] timeIntervalSince1970] - [self.model lastRequestInt] <= updateLength) {
                NSLog(@"NCWunderground: Too soon to download data again. Done updating.");
                [self.view setLoading:NO];
                return;
            }
        }
    }
    else {
        NSLog(@"NCWunderground: No save file found.");
    }

    NSLog(@"NCWunderground: Starting location updates.");
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self.model;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    self.locationUpdated = NO;
    [self.locationManager startUpdatingLocation];
}

- (void)dataDownloaded {
    [self.model saveDataToFile:self.saveFile inDirectory:self.saveDirectory];
    if (self.view) {
        [self associateModelToView];
        [self.view setLoading:NO];
    }
    else {
        NSLog(@"NCWunderground: Didn't update view, because it no longer exists.");
    }
}

- (void)dataDownloadFailed {
    NSLog(@"NCWunderground: dataDownloadFailed");
    [self.view setLoading:NO];
}

// Does: after data model has been updated, loads data into views
- (void)associateModelToView {
    // -- details page -- //

    // "Last Refreshed"
    NSDate *lastRefreshedDate = [NSDate dateWithTimeIntervalSince1970:[self.model lastRequestInt]];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"h:mm:ss a"];
    UILabel *lastRefreshedLabel = (UILabel *)[self.view getSubviewFromPage:0
                                                                   withTag:1];
    lastRefreshedLabel.text = [NSString stringWithFormat:@"Last Refreshed: %@",[dateFormatter stringFromDate:lastRefreshedDate]];

    // "Distance From Station"
    CLLocation *userLocation = [[CLLocation alloc] initWithLatitude:[self.model latitudeDouble]
                                                          longitude:[self.model longitudeDouble]];
    CLLocation *stationLocation = [[CLLocation alloc] initWithLatitude:[self.model obsLatitudeDouble]
                                                             longitude:[self.model obsLongitudeDouble]];
    UILabel *distanceLabel = (UILabel *)[self.view getSubviewFromPage:0 withTag:2];
    distanceLabel.text = [NSString stringWithFormat:@"Distance From Station: %.2lf mi",([stationLocation distanceFromLocation:userLocation] / 1609.344)];

    // -- hourly forecast page -- //
    int intervalLength = [self hourlyForecastLength];

    NSMutableArray *realTempSparkData = [self.model hourlyTempNumberArrayF:0
                                                                    length:intervalLength];
    NSMutableArray *feelsLikeSparkData = [self.model hourlyFeelsNumberArrayF:0
                                                                      length:intervalLength];

    ASBSparkLineView *realTempSparkView = (ASBSparkLineView *)[self.view getSubviewFromPage:1 withTag:120];
    ASBSparkLineView *feelsLikeSparkView = (ASBSparkLineView *)[self.view getSubviewFromPage:1 withTag:130];

    [realTempSparkView setDataValues:realTempSparkData];
    [feelsLikeSparkView setDataValues:feelsLikeSparkData];
    
    NSArray *page1TextArray = [NSArray arrayWithObjects:[self.model hourlyTime12HrString:0],
                                                        [NSString stringWithFormat:@"%d hr",intervalLength],
                                                        [self.model hourlyTime12HrString:(intervalLength - 1)],
                                                        @"High",@"Low",@"Temp",[self.model hourlyTempStringF:0],
                                                        [self.model hourlyTempStringF:(intervalLength-1)],
                                                        [NSString stringWithFormat:@"%@ °F",[[realTempSparkView dataMaximum] stringValue]],
                                                        [NSString stringWithFormat:@"%@ °F",[[realTempSparkView dataMinimum] stringValue]],
                                                        @"Like",[self.model hourlyFeelsStringF:0],[self.model hourlyFeelsStringF:(intervalLength-1)],
                                                        [NSString stringWithFormat:@"%@ °F",[[feelsLikeSparkView dataMaximum] stringValue]],
                                                        [NSString stringWithFormat:@"%@ °F",[[feelsLikeSparkView dataMinimum] stringValue]],nil];

    for (int i = 0; i < 3; ++i) {
        for (int j = 0; j < 5; ++j) {
            UILabel *label = (UILabel *)[self.view getSubviewFromPage:1
                                                              withTag:(100 + 10 * (i+1) + (j+1))];
            [label setText:[page1TextArray objectAtIndex:(i * 5 + j)]];
        }
    }

    // -- current conditions page -- //

    NSArray *page2TextArray = [NSArray arrayWithObjects:[self.model currentTempStringF],[self.model currentLocationString],
                                                        [NSString stringWithFormat:@"Feels Like %@",[self.model currentFeelsStringF]],
                                                        [NSString stringWithFormat:@"Humidity: %@",[self.model currentHumidityString]],
                                                        [self.model currentConditionsString],[NSString stringWithFormat:@"Wind: %@",
                                                        [self.model currentWindMPHString]],nil];

    for (int i = 0; i < 3; ++i) {
        for (int j = 0; j < 2; ++j) {
            UILabel *label = (UILabel *)[self.view getSubviewFromPage:2
                                                              withTag:(200 + 10 * (i+1) + (j+1))];
            [label setText:[page2TextArray objectAtIndex:(i*2+j)]];

        }
    }

    NSString *remoteIconName = [self.model currentConditionsIconName];
    NSDictionary *localIconInfo = [self.iconMap objectForKey:remoteIconName];
    UIImage *weatherIconBack;
    UIImage *weatherIconFront;

    weatherIconBack = [UIImage imageWithContentsOfFile:[_ammNCWundergroundWeeAppBundle pathForResource:[NSString stringWithFormat:@"icons/%@",[localIconInfo objectForKey:@"back"]]
                                                                                                ofType:@"png"]];
    weatherIconFront = [UIImage imageWithContentsOfFile:[_ammNCWundergroundWeeAppBundle pathForResource:[NSString stringWithFormat:@"icons/%@",[localIconInfo objectForKey:@"front"]]
                                                                                                 ofType:@"png"]];
    [(UIImageView *)[self.view getSubviewFromPage:2 withTag:200] setImage:weatherIconBack];
    [(UIImageView *)[self.view getSubviewFromPage:2 withTag:201] setImage:weatherIconFront];

    // -- daily forecast page -- //

    for (int j = 0; j < [self numberOfDays]; ++j) {
        UILabel *dayLabel = (UILabel *)[self.view getSubviewFromPage:3 withTag:(310 + (j+1))];
        UILabel *tempLabel = (UILabel *)[self.view getSubviewFromPage:3 withTag:(320 + (j+1))];
        [dayLabel setText:[self.model dailyDayShortString:j]];
        [tempLabel setText:[NSString stringWithFormat:@"%@/%@ (%@)",[self.model dailyHighStringF:j],
                                                                    [self.model dailyLowStringF:j],
                                                                    [self.model dailyPOPString:j]]];

        remoteIconName = [self.model dailyConditionsIconName:j];
        localIconInfo = [self.iconMap objectForKey:remoteIconName];
        weatherIconBack = [UIImage imageWithContentsOfFile:[_ammNCWundergroundWeeAppBundle pathForResource:[NSString stringWithFormat:@"icons/%@",[localIconInfo objectForKey:@"back"]]
                                                                                                    ofType:@"png"]];
        weatherIconFront = [UIImage imageWithContentsOfFile:[_ammNCWundergroundWeeAppBundle pathForResource:[NSString stringWithFormat:@"icons/%@",[localIconInfo objectForKey:@"front"]]
                                                                                                     ofType:@"png"]];
        [(UIImageView *)[self.view getSubviewFromPage:3 withTag:(330 + (j+1))] setImage:weatherIconBack];
        [(UIImageView *)[self.view getSubviewFromPage:3 withTag:(340 + (j+1))] setImage:weatherIconFront];
    }

}

// Returns: number of days in daily forecast (4)
- (int)numberOfDays {
    return 4;
}

// Returns: user preferences for number of hours to display
- (int)hourlyForecastLength {
    NSDictionary *defaultsDom = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.amm.ncwunderground"];
    NSNumber *hourlyLength = [defaultsDom objectForKey:@"hourlyLength"];
    if (hourlyLength) {
        return [hourlyLength integerValue];
    }
    else {
        NSLog(@"NCWunderground: user defaults contain no hourly forecast length field. Defaulting to 12 hours.");
        return 12;
    }
}

- (void)openForecastURL {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[self.model currentConditionsURL]]];
}

@end
