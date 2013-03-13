#import "BBWeeAppController-Protocol.h"
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UITableView.h>
//#import "ammNCWundergroundTableViewSource.h"

static NSBundle *_ammNCWundergroundWeeAppBundle = nil;

@interface ammNCWundergroundController: NSObject <BBWeeAppController,CLLocationManagerDelegate> {
	UIScrollView *_view;
	UIImageView *_backgroundLeftView2;
	UIImageView *_backgroundLeftView;
	UIImageView *_backgroundView;
	UIImageView *_backgroundRightView;

	//UITableView *_temperatureView;
	UILabel *_temperatureLabel;
	UILabel *_feelsLikeLabel;
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
- (void)loadBackgroundSubviews;

@end