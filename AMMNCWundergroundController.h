#import "BBWeeAppController-Protocol.h"
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UITableView.h>
#import "ASBSparkLineView.h"
#import "AMMNCWundergroundView.h"
#import "AMMNCWundergroundModel.h"
#import <dispatch/dispatch.h>

@interface AMMNCWundergroundController: NSObject <BBWeeAppController> {
    // view and model
    AMMNCWundergroundView *i_view;
    AMMNCWundergroundModel *i_model;

    // other things
    NSString *i_saveFile;
    CLLocationManager *i_locationManager;
    BOOL i_locationUpdated; // prevent location from updating more than once per refresh
    float i_baseWidth; // width our views are based on (min width it should ever display at)
    float i_currentWidth; // current width of the screen, orientation dependent
    NSDictionary *i_iconMap;
    float i_viewHeight;
}

@property (readonly) AMMNCWundergroundView *view;
@property (nonatomic, readonly) NSString *saveFile;
@property (readonly) CLLocationManager *locationManager;
@property (assign) BOOL locationUpdated;
@property (nonatomic, readonly) float baseWidth;
@property (nonatomic, readonly) float currentWidth;
@property (nonatomic, readonly) float viewHeight;

+ (void)initialize;
- (id)init;
- (void)dealloc;

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
