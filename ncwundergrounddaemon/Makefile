include theos/makefiles/common.mk

TOOL_NAME = ncwundergrounddaemon
ncwundergrounddaemon_FILES = main.m AMMNCWundergroundDaemonManager.m
ncwundergrounddaemon_FRAMEWORKS = CoreLocation

ADDITIONAL_OBJCFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tool.mk

after-ncwundergrounddaemon-stage::
	$(ECHO_NOTHING)$(FAKEROOT) chown root:wheel $(THEOS_STAGING_DIR)/Library/LaunchDaemons/com.amm.ncwundergrounddaemon.plist$(ECHO_END)
