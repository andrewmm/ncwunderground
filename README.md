NCWunderground
==============

iPhone Notification Center Widget for Weather Underground.

NOTE: This tweak is not affiliated with, sponsored, or approved in any way by Weather Underground. I am an independent developer.

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

Thanks
------

The widget is built on top of the BBWeeApp protocol.

This project was built using the theos build system by DHowett (https://github.com/DHowett/theos).

It uses Sparklines by abelsey to display houly forecasts (https://github.com/abelsey/Sparklines).

The settings menu is created using WeePreferenceLoader by aricha (https://github.com/aricha/WeePreferenceLoader).

Thanks to [maxps](https://github.com/maxps) and [newtux](https://github.com/newtux) for beta testing.

License
-------

### Main Widget Code

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

### Icon Set

The icon set distributed with this widget is available at http://weathericonsets.com/2011/05/28/droplets/. That site has the following to say about licensing:

I have collected the iconsets over a number of years when I was developing a weather widget for the KDE desktop. I was authorised by the owners to distribute the iconsets for personal and non-commercial use. Accordingly, this is the basis on which I am hosting the iconsets on this site. 

### Sparklines Submodule

The Sparklines project is distrubted with the following license information, which is also available in the source code:

Copyright (c) 2011 A. Belsey. All Rights Reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.

* Neither the name of the author nor the names of its contributors may be used
to endorse or promote products derived from this software without specific
prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
