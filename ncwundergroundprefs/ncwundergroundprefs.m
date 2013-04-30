#import <Preferences/Preferences.h>

@interface AMMNCWundergroundPrefsPrincipal: NSObject {
}
@end

@implementation AMMNCWundergroundPrefsPrincipal

- (void)support {
	NSLog(@"Support pressed.");
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=E7PRS3GFR2VR2&lc=US&item_name=Andrew%20MacKie%2dMason&item_number=NCWunderground&currency_code=USD&bn=PP%2dDonationsBF%3abtn_donateCC_LG%2egif%3aNonHosted"]];
}

@end
