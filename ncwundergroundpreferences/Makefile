include theos/makefiles/common.mk

BUNDLE_NAME = NCWundergroundPreferences
NCWundergroundPreferences_FILES = NCWundergroundPreferences.mm
NCWundergroundPreferences_INSTALL_PATH = /Library/PreferenceBundles
NCWundergroundPreferences_FRAMEWORKS = UIKit
NCWundergroundPreferences_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/NCWundergroundPreferences.plist$(ECHO_END)
