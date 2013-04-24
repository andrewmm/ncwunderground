include theos/makefiles/common.mk

export ARCHS = armv7
BUNDLE_NAME = ammNCWunderground
ammNCWunderground_FILES = AMMNCWundergroundController.m AMMNCWundergroundView.m AMMNCWundergroundModel.m ASBSparkLineView.m
ammNCWunderground_INSTALL_PATH = /Library/WeeLoader/Plugins
ammNCWunderground_FRAMEWORKS = UIKit CoreGraphics CoreLocation
ADDITIONAL_OBJCFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk

after-install::
	install.exec "killall -9 SpringBoard"

AWESOME_REPO_PATH=/Library/WebServer/Documents/repo
distribute: package
	ssh box@awesome.cs.uchicago.edu "rm $(AWESOME_REPO_PATH)/deb/$(THEOS_PACKAGE_NAME)*"
	scp "$(THEOS_PACKAGE_DIR)/$(THEOS_PACKAGE_FILENAME).deb" "box@awesome.cs.uchicago.edu:$(AWESOME_REPO_PATH)/deb/"
	ssh box@awesome.cs.uchicago.edu 'PATH=$$PATH:/sw/bin ; cd $(AWESOME_REPO_PATH) ; dpkg-scanpackages -m deb /dev/null > Packages ; sed -f fix_double_slash.sed < Packages > Packages.tmp ; mv Packages.tmp Packages ; bzip2 -fks Packages'
