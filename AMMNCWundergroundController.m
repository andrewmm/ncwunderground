#import <CoreLocation/CoreLocation.h>
#import "Sparklines/Sparklines/ASBSparkLineView.h"
#import "AMMNCWundergroundView.h"
#import "AMMNCWundergroundModel.h"
#import <dispatch/dispatch.h>

#import "AMMNCWundergroundController.h"
#import "CocoaLumberjack/Lumberjack/DDLog.h"
#import "CocoaLumberjack/Lumberjack/DDFileLogger.h"
#import "CocoaLumberjack/Lumberjack/DDASLLogger.h"
#import "CocoaLumberjack/Lumberjack/DDTTYLogger.h"

#define MK_TAG(x, y, z) ((x) * 1000 + (y) * 100 + (z))

static NSBundle *_ammNCWundergroundWeeAppBundle = nil;
static int ddLogLevel = LOG_LEVEL_OFF;

@interface AMMNCWundergroundController ()

@property (nonatomic, strong) AMMNCWundergroundView *view;
@property (nonatomic, strong) AMMNCWundergroundModel *model;
@property (nonatomic, copy) NSString *saveDirectory;
@property (nonatomic, copy) NSString *saveFile;
@property (atomic, strong) CLLocationManager *locationManager;
@property (nonatomic, assign) float currentWidth;
@property (nonatomic, assign) float viewHeight;
@property (nonatomic, copy) NSDictionary *iconMap;

@property (nonatomic, assign) int tempType;
@property (nonatomic, assign) int distType;
@property (nonatomic, assign) int windType;
@property (nonatomic, assign) BOOL useCustomLocation;
@property (nonatomic, copy) NSString *locationQuery;

@end

@implementation AMMNCWundergroundController

@synthesize view=i_view;
@synthesize model=i_model;
@synthesize saveDirectory = i_saveDirectory;
@synthesize saveFile=i_saveFile;
@synthesize locationManager=i_locationManager;
@synthesize locationUpdated=i_locationUpdated;
@synthesize currentWidth=i_currentWidth;
@synthesize viewHeight=i_viewHeight;
@synthesize iconMap=i_iconMap;

@synthesize tempType = i_tempType;
@synthesize distType = i_distType;
@synthesize windType = i_windType;
@synthesize useCustomLocation = i_useCustomLocation;
@synthesize locationQuery = i_locationQuery;

+ (void)initialize {
    _ammNCWundergroundWeeAppBundle = [NSBundle bundleForClass:[self class]];
}

- (id)init {
    if ((self = [super init]) != nil) {
        i_viewHeight = 71;
        i_currentWidth = 320;

        i_model = [[AMMNCWundergroundModel alloc] initWithController:self];

        i_saveDirectory = @"/var/mobile/Library/Application Support/NCWunderground/";
        i_saveFile = @"weather.save.plist";

        i_locationManager = [[CLLocationManager alloc] init];
        i_locationUpdated = NO;

        i_iconMap = [[NSDictionary alloc] initWithContentsOfFile:[_ammNCWundergroundWeeAppBundle pathForResource:@"icons/com.amm.ncwunderground.iconmap"
                                                                                                          ofType:@"plist"]];
        DDFileLogger *fileLogger = [[DDFileLogger alloc] init];
        fileLogger.rollingFrequency = 60 * 60 * 2; // 2 hour rolling
        fileLogger.logFileManager.maximumNumberOfLogFiles = 2;
        [DDLog addLogger:fileLogger];
        NSLog(@"NCWunderground: DDLog files saved in %@",[fileLogger.logFileManager logsDirectory]);
    }
    return self;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    NSDictionary *defaultsDom = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.amm.ncwunderground"];
    int cur_page = [(NSNumber *)[defaultsDom objectForKey:@"cur_page"] intValue] + 2;
    [self.view setScreenWidth:[self.view superview].frame.size.width withCurrentPage:cur_page];
    self.currentWidth = [self.view superview].frame.size.width;
}

- (void)loadFullView {
    NSDictionary *defaultsDom = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.amm.ncwunderground"];
    self.tempType = [(NSNumber *)[defaultsDom objectForKey:@"tempType"] intValue];
    self.distType = [(NSNumber *)[defaultsDom objectForKey:@"distType"] intValue];
    self.windType = [(NSNumber *)[defaultsDom objectForKey:@"windType"] intValue];
    self.useCustomLocation = [(NSNumber *)[defaultsDom objectForKey:@"useCustomLocation"] boolValue];
    self.locationQuery = (NSString *)[defaultsDom objectForKey:@"locationQuery"];
    DDLogVerbose(@"NCWunderground: preferences = %d, %d, %d",self.tempType,self.distType,self.windType);
    [self addSubviewsToView];
    [self loadData:nil];
}

- (void)loadPlaceholderView {
    NSDictionary *defaultsDom = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.amm.ncwunderground"];
    int debugPref = [(NSNumber *)[defaultsDom objectForKey:@"debugLevel"] intValue];
    switch (debugPref) {
        case 1:
            ddLogLevel = LOG_LEVEL_ERROR;
            break;
        case 2:
            ddLogLevel = LOG_LEVEL_WARN;
            break;
        case 3:
            ddLogLevel = LOG_LEVEL_INFO;
            break;
        case 4:
            ddLogLevel = LOG_LEVEL_VERBOSE;
            break;
        default:
            ddLogLevel = LOG_LEVEL_OFF;
            break;
    }
    [self.model setLogLevel:ddLogLevel];
    [self.view setLogLevel:ddLogLevel];
    int cur_page = [(NSNumber *)[defaultsDom objectForKey:@"cur_page"] intValue] + 2;
    // We store it as -2 so 0 corresponds to default

    self.view = [[AMMNCWundergroundView alloc] initWithPages:5
                                                      atPage:cur_page
                                                       width:self.currentWidth
                                                      height:self.viewHeight];
}

- (void)unloadView {
    DDLogInfo(@"NCWunderground: unloadView"); // debugging
    if (self.view) { // apparently unloadView can get called more than once without loadPlaceholderView or loadFullView being called again. Don't want that.
        NSDictionary *oldDefaultsDom = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.amm.ncwunderground"];
        NSMutableDictionary *newDefaultsDom = [NSMutableDictionary dictionaryWithDictionary:oldDefaultsDom];
        [newDefaultsDom setObject:[NSNumber numberWithFloat:([self.view contentOffset].x / self.currentWidth - 2)]
                                                     forKey:@"cur_page"]; // We store it as -2 so that 0 corresponds to main page
        [[NSUserDefaults standardUserDefaults] setPersistentDomain:newDefaultsDom
                                                           forName:@"com.amm.ncwunderground"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        self.locationManager = nil; // maybe this will help?
        self.view = nil;
    }
}

/* Does: adds all the specific subviews to self.view
         hooks subview values up to self.model */
- (void)addSubviewsToView {
    // -- details page -- //

    float rowFirstBuffer = 8;//0.025 * self.baseWidth;
    float rowBuffer = 4;//0.0125 * self.baseWidth;
    float rowHeight = (self.viewHeight - 2 * rowFirstBuffer - 2 * rowBuffer)/3;

    UIImage *wundergroundLogo = [UIImage imageWithContentsOfFile:[_ammNCWundergroundWeeAppBundle pathForResource:@"wundergroundLogo_white"
                                                                                                          ofType:@"png"]];
    wundergroundLogo = [wundergroundLogo resizableImageWithCapInsets:UIEdgeInsetsZero resizingMode:UIImageResizingModeStretch];
    UIImageView *wundergroundLogoView = [[UIImageView alloc] initWithImage:wundergroundLogo];
    wundergroundLogoView.contentMode = UIViewContentModeScaleAspectFit;
    wundergroundLogoView.frame = CGRectMake((0.1875*self.currentWidth - 54) / 2, (self.viewHeight - 32.16)/2, 54, 32.16);
    [self.view addSubview:wundergroundLogoView toPage:0 withTag:MK_TAG(0, 0, 0) manualRefresh:NO];

    // labels
    for (int i=0; i < 3; ++i) {
        UILabel *newLabel = [[UILabel alloc] init];
        [newLabel setBackgroundColor:[UIColor clearColor]];
        [newLabel setTextColor:[UIColor whiteColor]];
        [newLabel setFont:[UIFont systemFontOfSize:14]];
        [newLabel setTextAlignment:NSTextAlignmentCenter];
        newLabel.adjustsFontSizeToFitWidth = YES;
        newLabel.minimumScaleFactor = 0.1;
        [newLabel setFrame:CGRectMake(0.1875*self.currentWidth,rowFirstBuffer + (rowHeight + rowBuffer)*i,0.625*self.currentWidth,rowHeight)];
        if (i == 2) {
            [newLabel setText:[_ammNCWundergroundWeeAppBundle localizedStringForKey:@"CONFIGURE_OPTIONS"
                                                                              value:@"Configure options in Settings."
                                                                              table:nil]];
        }
        [self.view addSubview:newLabel toPage:0 withTag:MK_TAG(0, 0, i+1) manualRefresh:NO];
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
    [refreshButton setFrame:CGRectMake(0.859375*self.currentWidth, (self.viewHeight - 0.1*self.currentWidth)/2,
                                       0.09375*self.currentWidth,0.09375*self.currentWidth)];
    [self.view addSubview:refreshButton toPage:0 withTag:MK_TAG(0, 0, 4) manualRefresh:NO];

    // -- hourly forecast / sparklines page -- //

    // useful formatting constants
    float labelWidth = 0.14 * self.currentWidth;
    float colBuffer = 0.00625 * self.currentWidth;
    float sparkWidth = self.currentWidth - labelWidth * 5 - colBuffer * 7;
    rowFirstBuffer = 8;//0.025 * self.baseWidth;
    rowBuffer = 4;//0.0125 * self.baseWidth;
    rowHeight = (self.viewHeight - 2 * rowFirstBuffer - 2 * rowBuffer)/3;

    for (int i=0; i < 3; ++i) { // rows
        float y = rowFirstBuffer + i * (rowHeight + rowBuffer);
        for (int j=0; j < 5; ++j) { // columns
            // create tag of form 1(i+1)(j+1)
            int tag = MK_TAG(1, i+1, j+1);

            UILabel *newLabel = [[UILabel alloc] init];
            [newLabel setBackgroundColor:[UIColor clearColor]];
            [newLabel setTextColor:[UIColor whiteColor]];
            [newLabel setFont:[UIFont systemFontOfSize:13]];
            newLabel.adjustsFontSizeToFitWidth = YES;
            newLabel.minimumScaleFactor = 0.1;
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
                          withTag:MK_TAG(1, i+1, 0)
                    manualRefresh:YES];
        }
        
    }

    // -- current conditions page -- //
    float mainColBuffer = 0.025 * self.currentWidth;
    rowFirstBuffer = 8;//0.025 * self.baseWidth;
    rowBuffer = 3;

    labelWidth = (self.currentWidth - 4 - 4 * mainColBuffer - self.viewHeight) / 2;
    float leftHeight = (self.viewHeight - rowFirstBuffer * 2 - rowBuffer * 2) / 4;
    float rightHeight = leftHeight * 4 / 3;

    float xArray[] = {mainColBuffer,mainColBuffer * 3 + labelWidth + self.viewHeight};
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
            newLabel.adjustsFontSizeToFitWidth = YES;
            newLabel.minimumScaleFactor = 0.1;
            [newLabel setFrame:CGRectMake(xArray[j],yArray[i][j],labelWidth,heightArray[i][j])];

            [self.view addSubview:newLabel
                        toPage:2
                       withTag:MK_TAG(2, i+1, j+1)
                 manualRefresh:NO];
        }
    }

    CGRect iconRect = CGRectMake(mainColBuffer * 2 + labelWidth,2,
                                 self.viewHeight - 2 * 2,self.viewHeight - 2 * 2);

    UIImageView *iconBackView = [[UIImageView alloc] init];
    [iconBackView setFrame:iconRect];
    [self.view addSubview:iconBackView toPage:2 withTag:MK_TAG(2, 0, 0) manualRefresh:YES];

    UIImageView *iconFrontView = [[UIImageView alloc] init];
    [iconFrontView setFrame:iconRect];
    [self.view addSubview:iconFrontView toPage:2 withTag:MK_TAG(2, 0, 1) manualRefresh:YES];

    // put a transparent button on top of the icon to open the url
    UIButton *urlButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [urlButton addTarget:self
                  action:@selector(openForecastURL)
        forControlEvents:UIControlEventTouchUpInside];
    [urlButton setFrame:iconRect];
    [self.view addSubview:urlButton toPage:2 withTag:MK_TAG(2, 0, 2) manualRefresh:NO];

    // -- daily forecast page -- //

    int numberOfIcons = [self numberOfDays];
    float dayWidth = (self.currentWidth - 4 - colBuffer * ((float)numberOfIcons + 1)) / (float)numberOfIcons;
    rowHeight = 13;
    float iconDims = self.viewHeight - rowHeight * 2 - rowBuffer * 2 - rowFirstBuffer * 2;
    if (dayWidth < iconDims)
        iconDims = dayWidth;
    float iconY = rowHeight * 2 + rowBuffer * 2 + rowFirstBuffer + (self.viewHeight - rowHeight * 2 - rowBuffer * 2 - rowFirstBuffer * 2 - iconDims) / 2;

    for (int j = 0; j < [self dailyForecastLength]; ++j) { // columns
        for (int i = 0; i < 2; ++i) { // rows
            UILabel *newLabel = [[UILabel alloc] init];
            [newLabel setBackgroundColor:[UIColor clearColor]];
            [newLabel setTextColor:[UIColor whiteColor]];
            if (i == 0)
                [newLabel setFont:[UIFont systemFontOfSize:13]];
            else
                [newLabel setFont:[UIFont systemFontOfSize:13]];
            newLabel.adjustsFontSizeToFitWidth = YES;
            newLabel.minimumScaleFactor = 0.1;
            [newLabel setTextAlignment:NSTextAlignmentCenter];
            [newLabel setFrame:CGRectMake(colBuffer + j * (colBuffer + dayWidth), rowFirstBuffer + (rowBuffer + rowHeight) * i, dayWidth, rowHeight)];
            [self.view addSubview:newLabel
                           toPage:3
                          withTag:MK_TAG(3, i+1, j+1)
                    manualRefresh:NO];
        }

        CGRect iconRect = CGRectMake(colBuffer + j * (colBuffer + dayWidth) + (dayWidth - iconDims) / 2,
            iconY, iconDims, iconDims);

        UIImageView *dayIconView = [[UIImageView alloc] init];
        UIImageView *dayIconViewBack = [[UIImageView alloc] init];
        [dayIconView setFrame:iconRect];
        [self.view addSubview:dayIconViewBack
                       toPage:3
                      withTag:MK_TAG(3, 3, j+1)
                manualRefresh:YES];
        [self.view addSubview:dayIconView
                       toPage:3
                      withTag:MK_TAG(3, 4, j+1)
                manualRefresh:YES];
    }
    [self.view increaseWidthOfPage:3 with:(([self dailyForecastLength] - [self numberOfIcons]) * (colBuffer + dayWidth))];

    // -- hourly forecast page -- //

    numberOfIcons = [self numberOfHours];
    dayWidth = (self.currentWidth - 4 - colBuffer * ((float)numberOfIcons + 1)) / (float)numberOfIcons;
    iconDims = self.viewHeight - rowHeight * 2 - rowBuffer * 2 - rowFirstBuffer * 2;
    if (dayWidth < iconDims)
        iconDims = dayWidth;
    iconY = rowHeight * 2 + rowBuffer * 2 + rowFirstBuffer + (self.viewHeight - rowHeight * 2 - rowBuffer * 2 - rowFirstBuffer * 2 - iconDims) / 2;

    for (int j = 0; j < [self hourlyForecastLength]; ++j) { // columns
        for (int i = 0; i < 2; ++i) { // rows
            UILabel *newLabel = [[UILabel alloc] init];
            [newLabel setBackgroundColor:[UIColor clearColor]];
            [newLabel setTextColor:[UIColor whiteColor]];
            if (i == 0)
                [newLabel setFont:[UIFont systemFontOfSize:13]];
            else
                [newLabel setFont:[UIFont systemFontOfSize:13]];
            newLabel.adjustsFontSizeToFitWidth = YES;
            newLabel.minimumScaleFactor = 0.1;
            [newLabel setTextAlignment:NSTextAlignmentCenter];
            [newLabel setFrame:CGRectMake(colBuffer + j * (colBuffer + dayWidth), rowFirstBuffer + (rowBuffer + rowHeight) * i, dayWidth, rowHeight)];
            [self.view addSubview:newLabel
                           toPage:4
                          withTag:MK_TAG(4, i+1, j+1)
                    manualRefresh:NO];
        }

        CGRect iconRect = CGRectMake(colBuffer + j * (colBuffer + dayWidth) + (dayWidth - iconDims) / 2,
            iconY, iconDims, iconDims);

        UIImageView *dayIconView = [[UIImageView alloc] init];
        UIImageView *dayIconViewBack = [[UIImageView alloc] init];
        [dayIconView setFrame:iconRect];
        [self.view addSubview:dayIconViewBack
                       toPage:4
                      withTag:MK_TAG(4, 3, j+1)
                manualRefresh:YES];
        [self.view addSubview:dayIconView
                       toPage:4
                      withTag:MK_TAG(4, 4, j+1)
                manualRefresh:YES];
    }
    [self.view increaseWidthOfPage:4 with:(([self hourlyForecastLength] - [self numberOfIcons]) * (colBuffer + dayWidth))];
}

/* Takes: object which is responsible for calling it
          SPECIAL: iff caller==nil, this will respect user's preferences re: delay on reloading data */
// Does: tells the model to reload the data
- (void)loadData:(id)caller {
    DDLogInfo(@"NCWunderground: Loading data.");
    [self.view setLoading:YES];

    // Try to load in save data
    if ([self.model loadSaveData:self.saveFile inDirectory:self.saveDirectory]) {
        // loading the save file succeeded
        DDLogInfo(@"NCWunderground: Save file loaded, updating views.");
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
                DDLogWarn(@"NCWunderground: User's defaults contain no update delay. Defaulting to 5 minutes.");
                updateLength = 300; // default to 5 minutes
            }

            // 9999 is a special value that indicates that we never automatically refresh the data
            if ([[NSDate date] timeIntervalSince1970] - [self.model lastRequestInt] <= updateLength || updateLength == 9999) {
                DDLogInfo(@"NCWunderground: Too soon to download data again. Done updating.");
                [self.view setLoading:NO];
                return;
            }
        }
    }
    else {
        DDLogInfo(@"NCWunderground: No save file found.");
    }

    if (!self.useCustomLocation) {
        DDLogInfo(@"NCWunderground: Attempting to start location updates.");
        self.locationManager = [[CLLocationManager alloc] init];
        BOOL authorized = [self.model haveLocationPermissions];
        if (authorized != YES) {
            UIAlertView *permissionRequest = [[UIAlertView alloc] initWithTitle:[_ammNCWundergroundWeeAppBundle localizedStringForKey:@"ALLOW_LOCATION"
                                                                                                                                value:@"Allow SpringBoard Widgets To Access Your Location?"
                                                                                                                                table:nil]
                                                                        message:[_ammNCWundergroundWeeAppBundle localizedStringForKey:@"ALLOW_LOCATION_MESSAGE"
                                                                                                                                value:@"This will apply to any tweak that runs inside of SpringBoard. You may undo this action by turning off Location Access in the Weather Underground Widget settings, and then attempting to update the widget's data again."
                                                                                                                                table:nil]
                                                                        
                                                                       delegate:self
                                                              cancelButtonTitle:[_ammNCWundergroundWeeAppBundle localizedStringForKey:@"ALLOW"
                                                                                                                                value:@"Allow"
                                                                                                                                table:nil]
                                                              otherButtonTitles:[_ammNCWundergroundWeeAppBundle localizedStringForKey:@"DONT_ALLOW"
                                                                                                                                value:@"Don't Allow"
                                                                                                                                table:nil],nil];
            [permissionRequest show];
        }
        else {
            [CLLocationManager setAuthorizationStatus:YES forBundleIdentifier:@"com.apple.springboard"];
            [self startLocationUpdates];
        }
    }
    else {
        if (self.locationQuery && ![self.locationQuery isEqualToString:@""]) {
            [self.model startURLRequestWithQuery:self.locationQuery];
        }
        else {
            UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:[_ammNCWundergroundWeeAppBundle localizedStringForKey:@"NO_LOCATION_ENTERED"
                                                                                                                         value:@"No Location Entered"
                                                                                                                         table:nil]
                                                            message:[_ammNCWundergroundWeeAppBundle localizedStringForKey:@"PLEASE_ENTER_LOCATION"
                                                                                                                    value:@"Please turn off \"Use Custom Location\" or enter a location query in Settings."
                                                                                                                    table:nil]
                                                           delegate:nil
                                                  cancelButtonTitle:[_ammNCWundergroundWeeAppBundle localizedStringForKey:@"OK"
                                                                                                                    value:@"OK"
                                                                                                                    table:nil]
                                                  otherButtonTitles:nil];
            [errorAlert show];
            [self.view setLoading:NO];
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        NSLog(@"NCWunderground: Setting location authorization status to YES.");
        [self.model setLocationPermissions:YES];
        [CLLocationManager setAuthorizationStatus:YES forBundleIdentifier:@"com.apple.springboard"];
    }
    [self startLocationUpdates];
}

- (void)startLocationUpdates {
    self.locationManager.delegate = self.model;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    self.locationUpdated = NO;
    [self.locationManager startUpdatingLocation];
    [self performSelector:@selector(timeoutUpdate) withObject:nil afterDelay:10];
}

- (void)dataDownloaded {
    [self.model saveDataToFile:self.saveFile inDirectory:self.saveDirectory];
    if (self.view) {
        [self associateModelToView];
        [self.view setLoading:NO];
    }
    else {
        DDLogWarn(@"NCWunderground: Didn't update view, because it no longer exists.");
    }
}

- (void)dataDownloadFailed {
    DDLogWarn(@"NCWunderground: dataDownloadFailed");
    [self.view setLoading:NO];
}

- (void)timeoutUpdate {
    if (self.locationUpdated) {
        return;
    }
    self.locationUpdated = YES;
    DDLogWarn(@"NCWunderground: Location update is timing out.");
    if ([self.model latitudeDouble] && [self.model longitudeDouble]) {
        // TODO: come up with a way to display this other than a UIAlertView?
        /*UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:[_ammNCWundergroundWeeAppBundle localizedStringForKey:@"LOCATION_UPDATE_FAILED"
                                                                                                                     value:@"Location Update Failed"
                                                                                                                     table:nil]
                                                             message:[_ammNCWundergroundWeeAppBundle localizedStringForKey:@"NO_UPDATE_USING_LAST"
                                                                                                                     value:@"Unable to update to current location; using last known location."
                                                                                                                     table:nil]
                                                            delegate:nil
                                                   cancelButtonTitle:[_ammNCWundergroundWeeAppBundle localizedStringForKey:@"OK"
                                                                                                                     value:@"OK"
                                                                                                                     table:nil]
                                                   otherButtonTitles:nil];
        [errorAlert show];*/
        [self.model startURLRequestWithQuery:nil];
    }
    else if (self.locationQuery && ![self.locationQuery isEqualToString:@""]) {
        // TODO: Come up with a way to display this other than a UIAlertView?
        /*UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:[_ammNCWundergroundWeeAppBundle localizedStringForKey:@"LOCATION_UPDATE_FAILED"
                                                                                                                     value:@"Location Update Failed"
                                                                                                                     table:nil]
                                                             message:[_ammNCWundergroundWeeAppBundle localizedStringForKey:@"NO_UPDATE_USING_QUERY"
                                                                                                                     value:@"Unable to update to current location; using saved query."
                                                                                                                     table:nil]
                                                            delegate:nil
                                                   cancelButtonTitle:[_ammNCWundergroundWeeAppBundle localizedStringForKey:@"OK"
                                                                                                                     value:@"OK"
                                                                                                                     table:nil]
                                                   otherButtonTitles:nil];
        [errorAlert show];*/
        [self.model startURLRequestWithQuery:self.locationQuery];
    }
    else {
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:[_ammNCWundergroundWeeAppBundle localizedStringForKey:@"LOCATION_UPDATE_FAILED"
                                                                                                                     value:@"Location Update Failed"
                                                                                                                     table:nil]
                                                             message:[_ammNCWundergroundWeeAppBundle localizedStringForKey:@"NO_UPDATE_NO_FALLBACK"
                                                                                                                     value:@"Unable to update current location; no fallback options available."
                                                                                                                     table:nil]
                                                            delegate:nil
                                                   cancelButtonTitle:[_ammNCWundergroundWeeAppBundle localizedStringForKey:@"OK"
                                                                                                                     value:@"OK"
                                                                                                                     table:nil]
                                                   otherButtonTitles:nil];
        [errorAlert show];
        [self.view setLoading:NO];
    }
}

// Does: after data model has been updated, loads data into views
- (void)associateModelToView {
    // -- details page -- //

    // "Last Refreshed"
    int last = [self.model lastRequestInt];
    NSDate *lastRefreshedDate = [NSDate dateWithTimeIntervalSince1970:last];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDoesRelativeDateFormatting:YES];
    if (time(NULL) > last + 24 * 60 * 60) {
	[dateFormatter setDateStyle:NSDateFormatterShortStyle];
	[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    } else {
	[dateFormatter setDateStyle:NSDateFormatterNoStyle];
	[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    }
    UILabel *lastRefreshedLabel = (UILabel *)[self.view getSubviewFromPage:0
                                                                   withTag:MK_TAG(0, 0, 1)];
    lastRefreshedLabel.text = [NSString stringWithFormat:@"%@: %@",[_ammNCWundergroundWeeAppBundle localizedStringForKey:@"LAST_REFRESHED"
                                                                                                                   value:@"Last Refreshed"
                                                                                                                   table:nil],
                                                                   [dateFormatter stringFromDate:lastRefreshedDate]];

    // "Distance From Station"
    UILabel *distanceLabel = (UILabel *)[self.view getSubviewFromPage:0 withTag:MK_TAG(0, 0, 2)];
    if (!self.useCustomLocation) {
        CLLocation *userLocation = [[CLLocation alloc] initWithLatitude:[self.model latitudeDouble]
                                                              longitude:[self.model longitudeDouble]];
        CLLocation *stationLocation = [[CLLocation alloc] initWithLatitude:[self.model obsLatitudeDouble]
                                                                 longitude:[self.model obsLongitudeDouble]];
        // TODO: mi versus km
        float distance = [stationLocation distanceFromLocation:userLocation]; // meters
        NSString *distTypeString;
        switch (self.distType) {
            case AMMDistTypeM:
                distance = distance / 1609.344;
                distTypeString = [_ammNCWundergroundWeeAppBundle localizedStringForKey:@"mi"
                                                                                     value:@"mi"
                                                                                     table:nil];
                break;
            case AMMDistTypeK:
                distance = distance / 1000;
                distTypeString = [_ammNCWundergroundWeeAppBundle localizedStringForKey:@"km"
                                                                                     value:@"km"
                                                                                     table:nil];
                break;
        }
        distanceLabel.text = [NSString stringWithFormat:@"%@: %.2lf %@",[_ammNCWundergroundWeeAppBundle localizedStringForKey:@"DISTANCE_FROM_STATION"
                                                                                                                        value:@"Distance From Station"
                                                                                                                        table:nil],
                                                                        distance, distTypeString];
    }
    else {
        distanceLabel.text = [NSString stringWithFormat:@"%@: %@",[_ammNCWundergroundWeeAppBundle localizedStringForKey:@"DISTANCE_FROM_STATION"
                                                                                                                  value:@"Distance From Station"
                                                                                                                  table:nil],
                                                                  [_ammNCWundergroundWeeAppBundle localizedStringForKey:@"N/A"
                                                                                                                  value:@"N/A"
                                                                                                                  table:nil]];
    }

    // -- hourly forecast page -- //
    int intervalLength = [self hourlyForecastLength];

    NSMutableArray *realTempSparkData = [self.model hourlyTempNumberArray:0
                                                                   length:intervalLength
                                                                   ofType:self.tempType];
    NSMutableArray *feelsLikeSparkData = [self.model hourlyFeelsNumberArray:0
                                                                     length:intervalLength
                                                                     ofType:self.tempType];

    ASBSparkLineView *realTempSparkView = (ASBSparkLineView *)[self.view getSubviewFromPage:1 withTag:MK_TAG(1, 2, 0)];
    ASBSparkLineView *feelsLikeSparkView = (ASBSparkLineView *)[self.view getSubviewFromPage:1 withTag:MK_TAG(1, 3, 0)];

    [realTempSparkView setDataValues:realTempSparkData];
    [feelsLikeSparkView setDataValues:feelsLikeSparkData];
    
    NSString *tempTypeString;
    switch (self.tempType) {
        case AMMTempTypeF:
            tempTypeString = @"°F";
            break;
        case AMMTempTypeC:
            tempTypeString = @"°C";
            break;
        default:
            tempTypeString = @"";
            break;
    }
    NSArray *page1TextArray = [NSArray arrayWithObjects:[self.model hourlyTimeLocalizedString:0],
                                                        [_ammNCWundergroundWeeAppBundle localizedStringForKey:[NSString stringWithFormat:@"%d hr",intervalLength]
                                                                                                        value:[NSString stringWithFormat:@"%d hr",intervalLength]
                                                                                                        table:nil],
                                                        [self.model hourlyTimeLocalizedString:(intervalLength - 1)],
                                                        [_ammNCWundergroundWeeAppBundle localizedStringForKey:@"HIGH"
                                                                                                        value:@"High"
                                                                                                        table:nil],
                                                        [_ammNCWundergroundWeeAppBundle localizedStringForKey:@"LOW"
                                                                                                        value:@"Low"
                                                                                                        table:nil],
                                                        [_ammNCWundergroundWeeAppBundle localizedStringForKey:@"TEMP"
                                                                                                        value:@"Temp"
                                                                                                        table:nil],
                                                        [self.model hourlyTempString:0 ofType:self.tempType],
                                                        [self.model hourlyTempString:(intervalLength-1) ofType:self.tempType],
                                                        [NSString stringWithFormat:@"%@ %@",[[realTempSparkView dataMaximum] stringValue],tempTypeString],
                                                        [NSString stringWithFormat:@"%@ %@",[[realTempSparkView dataMinimum] stringValue],tempTypeString],
                                                        [_ammNCWundergroundWeeAppBundle localizedStringForKey:@"LIKE"
                                                                                                        value:@"Like"
                                                                                                        table:nil],
                                                        [self.model hourlyFeelsString:0 ofType:self.tempType],
                                                        [self.model hourlyFeelsString:(intervalLength-1) ofType:self.tempType],
                                                        [NSString stringWithFormat:@"%@ %@",[[feelsLikeSparkView dataMaximum] stringValue],tempTypeString],
                                                        [NSString stringWithFormat:@"%@ %@",[[feelsLikeSparkView dataMinimum] stringValue],tempTypeString],nil];

    for (int i = 0; i < 3; ++i) {
        for (int j = 0; j < 5; ++j) {
            UILabel *label = (UILabel *)[self.view getSubviewFromPage:1
                                                              withTag:MK_TAG(1, i+1, j+1)];
            [label setText:[page1TextArray objectAtIndex:(i * 5 + j)]];
        }
    }

    // -- current conditions page -- //

    NSArray *page2TextArray = [NSArray arrayWithObjects:[self.model currentTempStringOfType:self.tempType],[self.model currentLocationString],
                                                        [NSString stringWithFormat:@"%@: %@",[_ammNCWundergroundWeeAppBundle localizedStringForKey:@"LIKE"
                                                                                                                                             value:@"Like"
                                                                                                                                             table:nil],
                                                                                             [self.model currentFeelsStringOfType:self.tempType]],
                                                        [NSString stringWithFormat:@"%@: %@",[_ammNCWundergroundWeeAppBundle localizedStringForKey:@"HUM"
                                                                                                                                             value:@"Hum"
                                                                                                                                             table:nil],
                                                                                             [self.model currentHumidityString]],
                                                        [self.model currentConditionsString],[self.model currentWindStringOfType:self.windType],nil]; // TODO MPH versus KPH

    for (int i = 0; i < 3; ++i) {
        for (int j = 0; j < 2; ++j) {
            UILabel *label = (UILabel *)[self.view getSubviewFromPage:2
                                                              withTag:MK_TAG(2, i+1, j+1)];
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
    [(UIImageView *)[self.view getSubviewFromPage:2 withTag:MK_TAG(2, 0, 0)] setImage:weatherIconBack];
    [(UIImageView *)[self.view getSubviewFromPage:2 withTag:MK_TAG(2, 0, 1)] setImage:weatherIconFront];

    // -- daily forecast page -- //

    for (int j = 0; j < [self dailyForecastLength]; ++j) {
        UILabel *dayLabel = (UILabel *)[self.view getSubviewFromPage:3 withTag:MK_TAG(3, 1, j+1)];
        UILabel *tempLabel = (UILabel *)[self.view getSubviewFromPage:3 withTag:MK_TAG(3, 2, j+1)];
        [dayLabel setText:[self.model dailyDayShortString:j]];
        [tempLabel setText:[NSString stringWithFormat:@"%@/%@ (%@)",[self.model dailyHighString:j ofType:self.tempType],
                                                                    [self.model dailyLowString:j ofType:self.tempType],
                                                                    [self.model dailyPOPString:j]]];

        remoteIconName = [self.model dailyConditionsIconName:j];
        localIconInfo = [self.iconMap objectForKey:remoteIconName];
        weatherIconBack = [UIImage imageWithContentsOfFile:[_ammNCWundergroundWeeAppBundle pathForResource:[NSString stringWithFormat:@"icons/%@",[localIconInfo objectForKey:@"back"]]
                                                                                                    ofType:@"png"]];
        weatherIconFront = [UIImage imageWithContentsOfFile:[_ammNCWundergroundWeeAppBundle pathForResource:[NSString stringWithFormat:@"icons/%@",[localIconInfo objectForKey:@"front"]]
                                                                                                     ofType:@"png"]];
        [(UIImageView *)[self.view getSubviewFromPage:3 withTag:MK_TAG(3, 3, j+1)] setImage:weatherIconBack];
        [(UIImageView *)[self.view getSubviewFromPage:3 withTag:MK_TAG(3, 4, j+1)] setImage:weatherIconFront];
    }

    // -- hourly forecast page -- //

    for (int j = 0; j < [self hourlyForecastLength]; ++j) {
        UILabel *dayLabel = (UILabel *)[self.view getSubviewFromPage:4 withTag:MK_TAG(4, 1, j+1)];
        UILabel *tempLabel = (UILabel *)[self.view getSubviewFromPage:4 withTag:MK_TAG(4, 2, j+1)];
        [dayLabel setText:[self.model hourlyTimeLocalizedString:j]];
        [tempLabel setText:[NSString stringWithFormat:@"%@ (%@)",[self.model hourlyTempString:j ofType:self.tempType],
                                                                 [self.model hourlyPOPString:j]]];

        remoteIconName = [self.model hourlyConditionsIconName:j];
        localIconInfo = [self.iconMap objectForKey:remoteIconName];
        weatherIconBack = [UIImage imageWithContentsOfFile:[_ammNCWundergroundWeeAppBundle pathForResource:[NSString stringWithFormat:@"icons/%@",[localIconInfo objectForKey:@"back"]]
                                                                                                    ofType:@"png"]];
        weatherIconFront = [UIImage imageWithContentsOfFile:[_ammNCWundergroundWeeAppBundle pathForResource:[NSString stringWithFormat:@"icons/%@",[localIconInfo objectForKey:@"front"]]
                                                                                                     ofType:@"png"]];
        [(UIImageView *)[self.view getSubviewFromPage:4 withTag:MK_TAG(4, 3, j+1)] setImage:weatherIconBack];
        [(UIImageView *)[self.view getSubviewFromPage:4 withTag:MK_TAG(4, 4, j+1)] setImage:weatherIconFront];
    }

}

// Returns: number of icons in hourly forecast
- (int)numberOfHours {
    int n = [self hourlyForecastLength];
    int i = [self numberOfIcons];
    if (n > i) {
        return i;
    }
    return n;
}

// Returns: number of icons in daily forecast
- (int)numberOfDays {
    int n = [self dailyForecastLength];
    int i = [self numberOfIcons];
    if (n > i) {
        return i;
    }
    return n;
}

// Returns: number of icons that can be displayed with current width
- (int)numberOfIcons {
    return (self.currentWidth > 320) ? 6 : 4;
}

// Returns: user preferences for number of hours to display
- (int)hourlyForecastLength {
    NSDictionary *defaultsDom = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.amm.ncwunderground"];
    NSNumber *hourlyLength = [defaultsDom objectForKey:@"hourlyLength"];
    if (hourlyLength) {
        return [hourlyLength integerValue];
    }
    else {
        DDLogWarn(@"NCWunderground: user defaults contain no hourly forecast length field. Defaulting to 12 hours.");
        return 12;
    }
}

// Returns: user preferences for number of days to display
- (int)dailyForecastLength {
    NSDictionary *defaultsDom = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.amm.ncwunderground"];
    NSNumber *dailyLength = [defaultsDom objectForKey:@"dailyLength"];
    if (dailyLength) {
        return [dailyLength integerValue];
    }
    else {
        DDLogWarn(@"NCWunderground: user defaults contain no daily forecast length field. Defaulting to 4 days.");
        return 4;
    }
}

- (void)openForecastURL {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[self.model currentConditionsURL]]];
}

@end
