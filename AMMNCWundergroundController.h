#import "BBWeeAppController-Protocol.h"
@class CLLocationManager;
@class AMMNCWundergroundView;
@class AMMNCWundergroundModel;

@interface AMMNCWundergroundController: NSObject <BBWeeAppController, UIAlertViewDelegate>

@property (nonatomic, readonly, strong) AMMNCWundergroundView *view;
@property (nonatomic, readonly, strong) AMMNCWundergroundModel *model;
@property (nonatomic, readonly, copy) NSString *saveFile;
@property (atomic, readonly, strong) CLLocationManager *locationManager;
@property (atomic, assign) BOOL locationUpdated;
@property (nonatomic, readonly, assign) float currentWidth;
@property (nonatomic, readonly, assign) float viewHeight;
@property (nonatomic, readonly, copy) NSDictionary *iconMap;

@property (nonatomic, readonly, assign) int tempType;
@property (nonatomic, readonly, assign) int distType;
@property (nonatomic, readonly, assign) int windType;
@property (nonatomic, readonly, assign) BOOL useCustomLocation;
@property (nonatomic, readonly, copy) NSString *locationQuery;

+ (void)initialize;
- (id)init;

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
- (void)loadFullView;
- (void)loadPlaceholderView;
- (void)unloadView;

/* Does: adds all the specific subviews to i_view
         hooks subview values up to i_model */
- (void)addSubviewsToView;

/* Takes: object which is responsible for calling it
          SPECIAL: iff caller==nil, this will respect user's preferences re: delay on reloading data */
// Does: tells the model to reload the data
- (void)loadData:(id)caller;

// UIAlertViewDelegate method:
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;

- (void)startLocationUpdates;

- (void)dataDownloaded;
- (void)dataDownloadFailed;
- (void)timeoutUpdate;

// Does: after data model has been updated, loads data into views
- (void)associateModelToView;

// Returns: number of hours in hourly forecast
- (int)numberOfHours;
// Returns: number of days in daily forecast
- (int)numberOfDays;
// Returns: number of icons in forecast (4)
- (int)numberOfIcons;

// Returns: user preferences for number of hours to display
- (int)hourlyForecastLength;

- (void)openForecastURL;

@end
