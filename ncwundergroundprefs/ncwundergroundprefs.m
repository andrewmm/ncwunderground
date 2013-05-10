#import <Preferences/Preferences.h>
#import <Foundation/NSTask.h>

@interface AMMNCWundergroundPrefsPrincipal: NSObject {
}

- (void)github;
- (void)support;
- (void)license;
- (void)clearLocationPermissions;

@end

@implementation AMMNCWundergroundPrefsPrincipal

- (void)github {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/andrewmm/ncwunderground"]];
}

- (void)support {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=E7PRS3GFR2VR2&lc=US&item_name=Andrew%20MacKie%2dMason&item_number=NCWunderground&currency_code=USD&bn=PP%2dDonationsBF%3abtn_donateCC_LG%2egif%3aNonHosted"]];
}

- (void)license {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://opensource.org/licenses/MIT"]];
}

- (void)email {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"mailto://drewmm@gmail.com"]];
}

- (void)clearLocationPermissions {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *path = @"/var/mobile/Library/Application Support/NCWunderground/weather.save.plist";
    if ([fileManager fileExistsAtPath:path]) {
        NSMutableDictionary *saveFile = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
        [saveFile removeObjectForKey:@"locationPermissions"];
        [saveFile writeToFile:path atomically:YES];
        NSLog(@"NCWunderground Preferences: Location permissions cleared.");
    }
    else {
        NSLog(@"NCWunderground Preferences: Asked to clear location permissions, but %@ does not exist.",path);
    }
}

@end

@interface MyListController : PSListController {}
@end
@implementation MyListController
@end
