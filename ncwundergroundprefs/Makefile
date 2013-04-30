include theos/makefiles/common.mk

BUNDLE_NAME = ncwundergroundprefs
ncwundergroundprefs_FILES = ncwundergroundprefs.m
ncwundergroundprefs_INSTALL_PATH = /Library/PreferenceBundles
ncwundergroundprefs_FRAMEWORKS = UIKit
ncwundergroundprefs_PRIVATE_FRAMEWORKS = Preferences

ADDITIONAL_OBJCFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/ncwundergroundprefs.plist$(ECHO_END)
