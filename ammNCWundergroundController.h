#import "BBWeeAppController-Protocol.h"
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UITableView.h>
#import "ASBSparkLineView.h"
#import <dispatch/dispatch.h>

static NSBundle *_ammNCWundergroundWeeAppBundle = nil;

@interface ammNCWundergroundController: NSObject <BBWeeAppController,CLLocationManagerDelegate,NSURLConnectionDelegate> {
    // background
    dispatch_queue_t backgroundQueue;

    // base views
    UIScrollView *i_view;
    UIImageView *i_backgroundLeftView2;
    UIImageView *i_backgroundLeftView;
    UIImageView *i_backgroundView;
    UIImageView *i_backgroundRightView;

    // background left2 subviews
    UILabel *i_lastRefreshed;
    UILabel *i_distanceToStation;
    UILabel *i_configureInSettings;

    // background left subviews and related
    UILabel *i_titleNow;
    UILabel *i_titleLength;
    UILabel *i_titleEnd;
    UILabel *i_titleHigh;
    UILabel *i_titleLow;

    UILabel *i_realTempName;
    UILabel *i_realTempNow;
    ASBSparkLineView *i_realTempSparkView;
    UILabel *i_realTempEnd;
    UILabel *i_realTempHigh;
    UILabel *i_realTempLow;

    UILabel *i_feelsLikeName;
    UILabel *i_feelsLikeNow;
    ASBSparkLineView *i_feelsLikeSparkView;
    UILabel *i_feelsLikeEnd;
    UILabel *i_feelsLikeHigh;
    UILabel *i_feelsLikeLow;

    // background subviews
    UILabel *i_temperatureLabel;
    UILabel *i_feelsLikeLabel;
    UILabel *i_weatherTypeLabel;
    UIImageView *i_iconView;
    UILabel *i_locationLabel;
    UILabel *i_humidityLabel;
    UILabel *i_windLabel;

    // backgroundRight subview (containers)
    static const int i_numberOfDays = 5;
    NSMutableArray *i_dayNames;
    NSMutableArray *i_dayTemps;
    NSMutableArray *i_dayIconViews;

    NSString *i_saveFile;
    NSMutableDictionary *i_savedData;
    CLLocationManager *i_locationManager;
    BOOL i_locationUpdated;

    NSDictionary *i_iconMap;
}

@property (nonatomic, retain) UIView *view;

- (void)clearLabelSmallWhiteText:(UILabel *)label;

- (void)updateBackgroundLeft2SubviewValues;
- (void)updateBackgroundLeftSubviewValues;
- (void)updateBackgroundSubviewValues;
- (void)updateBackgroundRightSubviewValues;

- (void)positionSubviewsForBackgroundViewWidth:(float)width;

- (void)loadBackgroundLeft2Subviews;
- (void)loadBackgroundLeftSubviews;
- (void)loadBackgroundSubviews;
- (void)loadBackgroundRightSubviews;

- (void)updateSubviewValues; // calls all the update*Values methods above
- (void)loadSubviews; // calls all the load*Subviews methods above

- (void)willAnimateRotationToInterfaceOrientation:(int)arg1;
- (void)loadFullView;
- (void)loadPlaceholderView;
- (void)unloadView;

- (float)viewHeight;

- (void)loadData;
- (void)downloadData;
- (void)startURLRequest; // should only run inside backgroundQueue

- (void)locationManager:(CLLocationManager *)manage didUpdateLocations:(NSArray *)locations;
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *) error;



@end