#import "BBWeeAppController-Protocol.h"
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UITableView.h>
#import "ASBSparkLineView.h"

static NSBundle *_ammNCWundergroundWeeAppBundle = nil;

@interface ammNCWundergroundController: NSObject <BBWeeAppController,CLLocationManagerDelegate> {
    UIScrollView *_view;
    UIImageView *_backgroundLeftView2;
    UIImageView *_backgroundLeftView;
    UIImageView *_backgroundView;
    UIImageView *_backgroundRightView;

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
    ASBSparkLineView *_feelsLikeSparkView;
    UILabel *i_feelsLikeEnd;
    UILabel *i_feelsLikeHigh;
    UILabel *i_feelsLikeLow;

    // background subviews
    UILabel *_temperatureLabel;
    UILabel *_feelsLikeLabel;
    UILabel *_weatherTypeLabel;
    UIImage *_weatherIcon;
    UIImageView *_iconView;
    UILabel *_locationLabel;
    UILabel *_humidityLabel;
    UILabel *_windLabel;

    NSString *_saveFile;
    NSMutableDictionary *_savedData;
    CLLocationManager *_locationManager;
    BOOL _locationUpdated;

    NSDictionary *_iconMap;

    //ammNCWundergroundTableViewSource *_temperatureViewContents;
    //ammNCWundergroundTableViewSource *_moreInfoViewContents;
}
@property (nonatomic, retain) UIView *view;
@property (retain) NSString *saveFile;

// new functions
- (void)loadData;
- (void)downloadData;
- (void)useUpdatedLoc;
- (void)clearLabelSmallWhiteText:(UILabel *)label;
- (void)updateBackgroundLeftSubviewValues;
- (void)updateBackgroundSubviewValues;
- (void)loadBackgroundLeftSubviews;
- (void)loadBackgroundSubviews;

@end