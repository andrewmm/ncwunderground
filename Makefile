export ARCHS = armv7

include theos/makefiles/common.mk

TARGET_IPHONEOS_DEPLOYMENT_VERSION = 6.0
BUNDLE_NAME = ammNCWunderground
ammNCWunderground_FILES = AMMNCWundergroundController.m AMMNCWundergroundView.m AMMNCWundergroundModel.m Sparklines/Sparklines/ASBSparkLineView.m CocoaLumberjack/Lumberjack/DDLog.m CocoaLumberjack/Lumberjack/DDTTYLogger.m CocoaLumberjack/Lumberjack/DDFileLogger.m CocoaLumberjack/Lumberjack/DDASLLogger.m
ammNCWunderground_INSTALL_PATH = /Library/WeeLoader/Plugins
ammNCWunderground_FRAMEWORKS = UIKit CoreGraphics CoreLocation

TARGET_CC = xcrun -sdk iphoneos clang 
TARGET_CXX = xcrun -sdk iphoneos clang++
TARGET_LD = xcrun -sdk iphoneos clang++
ADDITIONAL_OBJCFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk

after-install::
	install.exec "killall -9 SpringBoard"

distribute: package
	ssh $(REPO_URL) "rm $(REPO_PATH)/deb/$(THEOS_PACKAGE_NAME)*" || echo "Nothing to delete"
	scp "$(THEOS_PACKAGE_DIR)/$(THEOS_PACKAGE_FILENAME).deb" "$(REPO_URL):$(REPO_PATH)/deb/"
	ssh $(REPO_URL) 'PATH=$$PATH:/sw/bin ; cd $(REPO_PATH) ; dpkg-scanpackages -m deb /dev/null > Packages ; sed -f fix_double_slash.sed < Packages > Packages.tmp ; mv Packages.tmp Packages ; bzip2 -fks Packages'

undistribute:
	ssh $(REPO_URL) "rm $(REPO_PATH)/deb/$(THEOS_PACKAGE_NAME)*"
	ssh $(REPO_URL) 'PATH=$$PATH:/sw/bin ; cd $(REPO_PATH) ; dpkg-scanpackages -m deb /dev/null > Packages ; sed -f fix_double_slash.sed < Packages > Packages.tmp ; mv Packages.tmp Packages ; bzip2 -fks Packages'

SUBPROJECTS += ncwundergroundprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
