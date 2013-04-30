#import <Preferences/Preferences.h>

@interface ncwundergroundprefsListController: PSListController {
}
@end

@implementation ncwundergroundprefsListController
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"ncwundergroundprefs" target:self] retain];
	}
	return _specifiers;
}
@end

// vim:ft=objc
