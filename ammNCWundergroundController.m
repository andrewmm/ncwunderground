#import "ammNCWundergroundController.h"

@implementation ammNCWundergroundController
@synthesize view = _view;
@synthesize saveFile = _saveFile;

+ (void)initialize {
	_ammNCWundergroundWeeAppBundle = [[NSBundle bundleForClass:[self class]] retain];
}

- (id)init {
	if((self = [super init]) != nil) {
		_savedData = [[NSMutableDictionary alloc] init];
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		_saveFile = [[NSString alloc] initWithString:[[paths objectAtIndex:0] stringByAppendingString:@"/amm-wunderground-save.plist"]];
		
		_locationManager = [[CLLocationManager alloc] init];
		_locationUpdated = NO;
		
		_iconMap = [[NSDictionary alloc] initWithContentsOfFile:[_ammNCWundergroundWeeAppBundle pathForResource:@"amm-wunderground-icon-map" ofType:@"plist"]];
		
		//_temperatureViewContents = [[ammNCWundergroundTableViewSource alloc] init];
		//_moreInfoViewContents = [[ammNCWundergroundTableViewSource alloc] init];
	} return self;
}

- (void)dealloc {
	[_view release];
	[_backgroundLeftView2 release];
	[_backgroundLeftView release];
	[_backgroundView release];
	[_backgroundRightView release];

	[_savedData release];
	[_saveFile release];
	[_locationManager release];

	[_iconMap release];

	//[_temperatureViewContents release];
	//[_moreInfoViewContents release];

	[super dealloc];
}

- (void) clearLabelSmallWhiteText:(UILabel *)label {
	label.backgroundColor = [UIColor clearColor];
	label.textColor = [UIColor whiteColor];
	label.font = [UIFont systemFontOfSize:14.f];
}

- (void)loadBackgroundSubviews {
	// convenience pointer
	NSDictionary *current_observation = [_savedData objectForKey:@"current_observation"];

	float temperatureWidth = (316.f - 8 - [self viewHeight] - 1) / 2;
	_temperatureLabel = [[UILabel alloc] init];
	_temperatureLabel.text = [[[current_observation objectForKey:@"temp_f"] stringValue] stringByAppendingString:@"° F"];
	_temperatureLabel.frame = CGRectMake(2.f,0,temperatureWidth,46.f);
	[self clearLabelSmallWhiteText:_temperatureLabel];
	_temperatureLabel.font = [UIFont systemFontOfSize:30.f];

	_feelsLikeLabel = [[UILabel alloc] init];
	_feelsLikeLabel.text = [@"Feels Like: " stringByAppendingString:[[current_observation objectForKey:@"feelslike_f"] stringByAppendingString:@"° F"]];
	_feelsLikeLabel.frame = CGRectMake(2.f,48.f,temperatureWidth,23.f);
	[self clearLabelSmallWhiteText:_feelsLikeLabel];

	NSString *wundergroundIconName = [[[[_savedData objectForKey:@"current_observation"] objectForKey:@"icon_url"] lastPathComponent] stringByDeletingPathExtension];
	NSString *localIconName = [_iconMap objectForKey:wundergroundIconName];
	NSLog(@"NCWundergroud: iconMap: %@",_iconMap);
	NSLog(@"NCWunderground: Getting local icon %@ for wunderground icon %@",localIconName,wundergroundIconName);
	_weatherIcon = [UIImage imageWithContentsOfFile:[_ammNCWundergroundWeeAppBundle pathForResource:localIconName ofType:@"png"]];
	_iconView = [[UIImageView alloc] initWithImage:_weatherIcon];
	_iconView.frame = CGRectMake(4.f + temperatureWidth,0.f,[self viewHeight],[self viewHeight]);

	float moreInfoWidth = 316.f - 8.f - [self viewHeight] - temperatureWidth;
	_locationLabel = [[UILabel alloc] init];
	_locationLabel.text = [[current_observation objectForKey:@"display_location"] objectForKey:@"full"];
	_locationLabel.frame = CGRectMake(6.f + temperatureWidth + [self viewHeight],0,moreInfoWidth,22.f);
	[self clearLabelSmallWhiteText:_locationLabel];
	_locationLabel.textAlignment = NSTextAlignmentRight;

	_humidityLabel = [[UILabel alloc] init];
	_humidityLabel.text = [@"Humidity: " stringByAppendingString:[current_observation objectForKey:@"relative_humidity"]];
	_humidityLabel.frame = CGRectMake(6.f + temperatureWidth + [self viewHeight],24.f,moreInfoWidth,23.f);
	[self clearLabelSmallWhiteText:_humidityLabel];
	_humidityLabel.textAlignment = NSTextAlignmentRight;

	_windLabel = [[UILabel alloc] init];
	_windLabel.text = [[@"Wind: " stringByAppendingString:[[current_observation objectForKey:@"wind_mph"] stringValue]]  stringByAppendingString:@" mph"];
	_windLabel.frame = CGRectMake(6.f + temperatureWidth + [self viewHeight],49.f,moreInfoWidth,22.f);
	[self clearLabelSmallWhiteText:_windLabel];
	_windLabel.textAlignment = NSTextAlignmentRight;

	[_backgroundView addSubview:_temperatureLabel];
	[_backgroundView addSubview:_feelsLikeLabel];
	[_backgroundView addSubview:_iconView];
	[_backgroundView addSubview:_locationLabel];
	[_backgroundView addSubview:_humidityLabel];
	[_backgroundView addSubview:_windLabel];

	[_temperatureLabel release];
	[_feelsLikeLabel release];
	[_iconView release];
	[_locationLabel release];
	[_humidityLabel release];
	[_windLabel release];
}

- (void)loadFullView {
	// Add subviews to _backgroundView (or _view) here.
	[self loadData];
	[self loadBackgroundSubviews];
}

- (void)loadPlaceholderView {
	// This should only be a placeholder - it should not connect to any servers or perform any intense
	// data loading operations.
	//
	// All widgets are 316 points wide. Image size calculations match those of the Stocks widget.
	_view = [[UIScrollView alloc] initWithFrame:(CGRect){CGPointZero, {316.f, [self viewHeight]}}];
	_view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	_view.contentSize = CGSizeMake(1280.f,[self viewHeight]);
	_view.pagingEnabled = YES;
	_view.contentOffset = CGPointMake(640.f,0.f);
	_view.showsHorizontalScrollIndicator = NO;

	UIImage *bgImg = [UIImage imageWithContentsOfFile:@"/System/Library/WeeAppPlugins/StocksWeeApp.bundle/WeeAppBackground.png"];
	UIImage *stretchableBgImg = [bgImg stretchableImageWithLeftCapWidth:floorf(bgImg.size.width / 2.f) topCapHeight:floorf(bgImg.size.height / 2.f)];

	_backgroundLeftView2 = [[UIImageView alloc] initWithImage:stretchableBgImg];
	_backgroundLeftView2.frame = CGRectMake(2,0,312.f,[self viewHeight]);
	_backgroundLeftView2.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[_view addSubview:_backgroundLeftView2];

	_backgroundLeftView = [[UIImageView alloc] initWithImage:stretchableBgImg];
	_backgroundLeftView.frame = CGRectMake(322.f,0,312.f,[self viewHeight]);
	_backgroundLeftView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[_view addSubview:_backgroundLeftView];

	_backgroundView = [[UIImageView alloc] initWithImage:stretchableBgImg];
	_backgroundView.frame = CGRectMake(642.f,0, 312.f,[self viewHeight]);
	_backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[_view addSubview:_backgroundView];

	_backgroundRightView = [[UIImageView alloc] initWithImage:stretchableBgImg];
	_backgroundRightView.frame = CGRectMake(962.f,0,312.f,[self viewHeight]);
	_backgroundRightView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[_view addSubview:_backgroundRightView];
}

- (void)unloadView {
	[_view release];
	_view = nil;
	[_backgroundLeftView2 release];
	_backgroundLeftView2 = nil;
	[_backgroundLeftView release];
	_backgroundLeftView = nil;
	[_backgroundView release];
	_backgroundView = nil;
	[_backgroundRightView release];
	_backgroundRightView = nil;
	// Destroy any additional subviews you added here. Don't waste memory :(.
}

- (float)viewHeight {
	return 71.f;
}

// new functions

- (void)loadData {

	NSFileManager *fileManager = [NSFileManager defaultManager];

	if ([fileManager fileExistsAtPath:_saveFile]) {
		NSMutableDictionary *tempDict = [[NSMutableDictionary alloc] initWithContentsOfFile:[self saveFile]];
		[_savedData addEntriesFromDictionary:tempDict];
		[tempDict release];
	}
	
	if ([_savedData objectForKey:@"last request"] == nil) {
		NSLog(@"NCWunderground: No save file found, initializing.");

		// initialize some data
		[_savedData setObject:[NSNumber numberWithInteger:0] forKey:@"last request"];
		[_savedData setObject:@"41.7921" forKey:@"latitude"];
		[_savedData setObject:@"-87.599506" forKey:@"longitude"];
	}

	if ([[NSDate date] timeIntervalSince1970] - [[_savedData objectForKey:@"last request"] integerValue] >= 1200) {

		// It's been too long since we last queried the database. Let's do it again.
		[self downloadData];
	}
	else {
		NSLog(@"NCWunderground: Using save data");
	}
}

- (void) downloadData {
	NSLog(@"NCWunderground: downloadData");
	// Here we tell it to start looking for the location. Once we have the location, the locationManager:didUpdateToLocation method handles the rest of the download work
	_locationManager.delegate = self;
	_locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
	_locationUpdated = NO;
	[_locationManager startUpdatingLocation];
}

- (void) useUpdatedLoc {
	NSLog(@"NCWunderground: location has been updated, proceeding");

	// get data from website by HTTP GET request
	NSHTTPURLResponse * response;
	NSError * error;

	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	NSMutableString *urlString = [NSMutableString stringWithString:@"http://api.wunderground.com/api/8e4db8cccf9828e3/conditions/hourly/forecast10day/q/"];
	[urlString appendString:[_savedData objectForKey:@"latitude"]];
	[urlString appendString:@","];
	[urlString appendString:[_savedData objectForKey:@"longitude"]];
	[urlString appendString:@".json"];
	[request setURL:[NSURL URLWithString:urlString]];
	[request setHTTPMethod:@"GET"];

	NSData *resultJSON = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	[request release];
	
	if(NSClassFromString(@"NSJSONSerialization")) {
		NSError *error = nil;
		NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:resultJSON options:0 error:&error];
		if (error) {
			NSLog(@"NCWunderground: JSON was malformed. Bad.");
			return;
		}
		if ([jsonDict isKindOfClass:[NSDictionary class]]) {
			NSLog(@"NCWunderground: parsing data.");
			// update last-request time
			[_savedData setObject:[NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]] forKey:@"last request"];

			// convenience pointers
			NSDictionary *currentObservation = [jsonDict objectForKey:@"current_observation"];
			NSDictionary *dailyForecast = [[jsonDict objectForKey:@"forecast"] objectForKey:@"simpleforecast"];
			NSDictionary *displayLocation = [currentObservation objectForKey:@"display_location"];

			// Use Wunderground's parsing of lat/long into city/state/country
			[_savedData setObject:[displayLocation objectForKey:@"city"] forKey:@"city"];
			[_savedData setObject:[displayLocation objectForKey:@"state"] forKey:@"state"];
			[_savedData setObject:[displayLocation objectForKey:@"country"] forKey:@"country"];

			// import current observations, daily forecast, and hourly forecast
			[_savedData setObject:currentObservation forKey:@"current_observation"];
			[_savedData setObject:[dailyForecast objectForKey:@"forecastday"] forKey:@"forecastday"];
			[_savedData setObject:[jsonDict objectForKey:@"hourly_forecast"] forKey:@"hourly_forecast"];


			// save data to disk for later use
			[_savedData writeToFile:[self saveFile] atomically:YES];

			NSLog(@"NCWunderground: data saved to disk at %@",[self saveFile]);
		}
		else {
			NSLog(@"NCWunderground: JSON was non-dict. Bad.");
			return;
		}
	}
	else {
		NSLog(@"NCWunderground: We don't have NSJSONSerialization. Bad.");
		return;
	}
}

- (void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {

	NSLog(@"NCWunderground: didUpdateToLocation: %@", [locations lastObject]);
	if (locations != nil) {
		[_savedData setObject:[NSString stringWithFormat:@"%.8f", [[locations lastObject] coordinate].latitude] forKey:@"latitude"];
        [_savedData setObject:[NSString stringWithFormat:@"%.8f", [[locations lastObject] coordinate].longitude] forKey:@"longitude"];
        if (_locationUpdated == NO) {
        	_locationUpdated = YES;
        	[_locationManager stopUpdatingLocation];
        	[self useUpdatedLoc];
        }
    }
    else {
    	NSLog(@"NCWunderground: locationManager:didUpdateToLocation called but newLocation nil. Bad.");
    }
}

- (void) locationManager:(CLLocationManager *)manager didFailWithError:(NSError *) error {
	NSLog(@"NCWunderground: locationManager:didFailWithError: %@",error);
}

@end
