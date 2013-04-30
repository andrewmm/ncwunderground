#import "BBWeeAppController-Protocol.h"
@class CLLocationManager;
@class AMMNCWundergroundView;
@class AMMNCWundergroundModel;

@interface AMMNCWundergroundController: NSObject <BBWeeAppController>

@property (nonatomic, readonly, strong) AMMNCWundergroundView *view;
@property (nonatomic, readonly, strong) AMMNCWundergroundModel *model;
@property (nonatomic, readonly, copy) NSString *saveFile;
@property (atomic, readonly, strong) CLLocationManager *locationManager;
@property (atomic, assign) BOOL locationUpdated;
@property (nonatomic, readonly, assign) float baseWidth;
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

- (void)dataDownloaded;
- (void)dataDownloadFailed;

// Does: after data model has been updated, loads data into views
- (void)associateModelToView;

// Returns: number of days in daily forecast (4)
- (int)numberOfDays;

// Returns: user preferences for number of hours to display
- (int)hourlyForecastLength;

- (void)openForecastURL;

@end
