#import "BBWeeAppController-Protocol.h"
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UITableView.h>
#import "ASBSparkLineView.h"
#import "AMMNCWundergroundView.h"
#import <dispatch/dispatch.h>

static NSBundle *_ammNCWundergroundWeeAppBundle = nil;

@interface ammNCWundergroundController: NSObject <BBWeeAppController> {
	// view and model
	AMMNCWundergroundView *i_view;
	AMMNCWundergroundModel *i_model;

	// other things
	NSString *i_saveFile;
	CLLocationManager *i_locationManager;
	BOOL i_locationUpdated; // prevent location from updating more than once per refresh
	BOOL i_loadingData; // prevent reloading data while already doing so
	float i_baseWidth; // width our views are based on (min width it should ever display at)
	float i_currentWidth; // current width of the screen, orientation dependent
	NSDictionary *i_iconMap;
}

@property (nonatomic, readonly) NSString *saveFile;
@property (atomic, assign) BOOL locationUpdated;
@property (atomic, assign) BOOL loadingData;
@property (nonatomic, readonly) float baseWidth;
@property (nonatomic, readonly) float currentWidth;

- (void)init;

- (void)addSubviewsToView;

- (void)loadData:(id)caller;

@end