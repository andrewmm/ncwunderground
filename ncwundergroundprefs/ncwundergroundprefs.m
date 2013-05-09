#import <Preferences/Preferences.h>
#import <Foundation/NSTask.h>

@interface AMMNCWundergroundPrefsPrincipal: NSObject {
}

- (void)support;
- (void)clearLocationPermissions;

@end

@implementation AMMNCWundergroundPrefsPrincipal

- (void)support {
	NSLog(@"Support pressed.");
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=E7PRS3GFR2VR2&lc=US&item_name=Andrew%20MacKie%2dMason&item_number=NCWunderground&currency_code=USD&bn=PP%2dDonationsBF%3abtn_donateCC_LG%2egif%3aNonHosted"]];
}

- (void)clearLocationPermissions {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *path = @"/var/root/Library/Caches/locationd/clients.plist";
	if ([fileManager fileExistsAtPath:path]) {
        NSMutableDictionary *permissionsDictionary = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
        [permissionsDictionary removeObjectForKey:@"com.apple.springboard"];
        [permissionsDictionary writeToFile:path atomically:YES];
        NSLog(@"NCWunderground: SpringBoard's location permissions have been cleared, restarting locationd.");
        [NSTask launchedTaskWithLaunchPath:@"/usr/bin/killall" arguments:[NSArray arrayWithObjects:@"locationd",nil]];
    }
    else {
    	NSLog(@"NCWunderground: Asked to clear location permissions, but %@ does not exist. Ignoring.",path);
    }
}

@end
