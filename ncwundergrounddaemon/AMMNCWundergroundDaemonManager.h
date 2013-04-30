#import <CoreLocation/CoreLocation.h>

@interface AMMNCWundergroundDaemonManager : NSObject <CLLocationManagerDelegate>

@property (nonatomic, assign) BOOL didUpdate;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, copy) NSString *saveFile;
@property (nonatomic, copy) NSString *saveDirectory;

- (void)getLocation;

- (void)keepRunning:(NSTimer *)sender;

@end
