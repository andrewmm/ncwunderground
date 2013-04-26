NCWunderground
==============

iPhone Notification Center Widget for Weather Underground.

Requires jailbroken iOS 6.

Add bug reports as issues on the GitHub repository, or email drewmm@gmail.com.

Installation
------------

### Download and Installation

There are two methods to install NCWunderground.

#### 1. Download from Cydia

Coming Soon.

#### 2. Compile from Source

Run the following commands on your command line to download the source:

```
git clone git://github.com/andrewmm/ncwunderground.git
cd ncwunderground
git submodule init
```

Then you can run `make` to compile the code or `make package` to compile and create a .deb package. You can also run:

```
export THEOS_DEVICE_IP=your.phone.ip.address
make package install
```

This will compile the code, create a .deb, SSH it over to your phone (you will need to have SSH installed and enabled), and respring.

### Enable and Configure

Navigate to `Settings > Notifications > Weather Underground`. Turn on the Notification Center switch to enable the widget. On the `Settings > Notifications` screen you can also drag entries around to sort them.

Configure the options. The widget will download data from the Weather Underground server whenever the Notification Center is opened, so long as it has not downloaded data in the last N minutes, where N is set by the Data Refresh Delay option.

Hourly Forecast Length controls the number of hours that are included in the sparkline display and the min/max calculations on one of the pages.

You will need to enter your own Weather Underground API key in order to use the widget. This enables me to release it for free. To get an API key, go to http://www.wunderground.com/weather/api/d/edit.html. Select the "Anvil Plan" and the "Developer" option. Then copy the API key into the relevant settings field.

License
-------

The MIT License (MIT) - http://opensource.org/licenses/MIT

Copyright (c) 2013 Andrew MacKie-Mason

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.