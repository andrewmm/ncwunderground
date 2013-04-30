#import <notify.h>

#import "AMMNCWundergroundDaemonManager.h"

@implementation AMMNCWundergroundDaemonManager

@synthesize didUpdate = i_didUpdate;
@synthesize locationManager = i_locationManager;
@synthesize saveFile = i_saveFile;
@synthesize saveDirectory = i_saveDirectory;

- (id)init {
    if ((self = [super init])) {
        i_didUpdate = YES;
        i_saveFile = @"weather.save.plist";
        i_saveDirectory = @"/var/mobile/Library/Application Support/NCWunderground/";
    }
    return self;
}

- (void)getLocation {
    NSLog(@"getLocation");
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    self.didUpdate = NO;
    if([CLLocationManager locationServicesEnabled]){
        NSLog(@"authorizationStatus: %d (%d/%d/%d)",[CLLocationManager authorizationStatus],kCLAuthorizationStatusRestricted,kCLAuthorizationStatusDenied,kCLAuthorizationStatusAuthorized);
        [self.locationManager startUpdatingLocation];
        NSLog(@"Asked %@ to update locations.",self.locationManager);
        [self performSelector:@selector(stopUpdates) withObject:nil afterDelay:5];
    }
    else {
        NSLog(@"Location services not enabled.");
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *location = [locations lastObject];
    if (-[location.timestamp timeIntervalSinceNow] > 20.0) {
        return;
    }

    if (self.didUpdate) {
        return;
    }
    [manager stopUpdatingLocation];
    self.didUpdate = YES;

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *fullPath = [self.saveDirectory stringByAppendingString:self.saveFile];

    NSMutableDictionary *saveData = [[NSMutableDictionary alloc] init];
    if ([fileManager fileExistsAtPath:fullPath]) {
        saveData = [[NSMutableDictionary alloc] initWithContentsOfFile:fullPath];
    }

    [saveData setObject:[NSString stringWithFormat:@"%.8f", [location coordinate].latitude]
                 forKey:@"latitude"];
    [saveData setObject:[NSString stringWithFormat:@"%.8f", [location coordinate].longitude]
                 forKey:@"longitude"];

    NSError *error;
    BOOL success = [fileManager createDirectoryAtPath:self.saveDirectory
                          withIntermediateDirectories:YES
                                           attributes:nil
                                                error:&error];
    if (!success) {
        NSLog(@"Could not save to disk because directory could not be created. Error: %@",[error localizedDescription]);
        return;
    }
    [saveData writeToFile:fullPath atomically:YES];
    notify_post("com.amm.ncwunderground.location_updated");
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"Location manager failed with error %@",error);
    [self.locationManager stopUpdatingLocation];
    self.locationManager = nil;
    notify_post("com.amm.ncwunderground.location_update_failed");
}

- (void)stopUpdates {
    NSLog(@"Location manager timed out.");
    [self.locationManager stopUpdatingLocation];
    self.locationManager = nil;
    notify_post("com.amm.ncwunderground.location_update_failed");
}

- (void)keepRunning:(NSTimer *)theTimer {
    NSLog(@"Keep running.");
}

@end
