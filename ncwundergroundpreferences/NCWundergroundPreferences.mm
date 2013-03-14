#import <Preferences/Preferences.h>

@interface NCWundergroundPreferencesListController: PSListController {
}
@end

@implementation NCWundergroundPreferencesListController
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"NCWundergroundPreferences" target:self] retain];
	}
	return _specifiers;
}
@end

// vim:ft=objc
