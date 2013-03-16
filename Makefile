include theos/makefiles/common.mk

export ARCHS = armv7
BUNDLE_NAME = ammNCWunderground
ammNCWunderground_FILES = ammNCWundergroundController.m ASBSparkLineView.m
ammNCWunderground_INSTALL_PATH = /Library/WeeLoader/Plugins
ammNCWunderground_FRAMEWORKS = UIKit CoreGraphics CoreLocation

include $(THEOS_MAKE_PATH)/bundle.mk

after-install::
	install.exec "killall -9 SpringBoard"
