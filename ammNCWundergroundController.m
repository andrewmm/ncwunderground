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

	[super dealloc];
}

- (void) clearLabelSmallWhiteText:(UILabel *)label {
	label.backgroundColor = [UIColor clearColor];
	label.textColor = [UIColor whiteColor];
	label.font = [UIFont systemFontOfSize:14.f];
}

- (void)updateBackgroundLeftSubviewValues {
	NSDictionary *defaultsDom = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.amm.ncwunderground"];
	NSNumber *hourlyLength = [defaultsDom objectForKey:@"hourlyLength"];
	static const int intervalLength;
	if (hourlyLength) {
		intervalLength = [hourlyLength integerValue];
	}
	else {
		NSLog(@"NCWunderground: user defaults contain no hourly forecast length field. Defaulting to 12 hours.");
		intervalLength = 12;
	}

	// convenience pointers
	NSArray *hourly_forecast = [_savedData objectForKey:@"hourly_forecast"];
	NSDictionary *first_forecast = [hourly_forecast objectAtIndex:0];
	NSDictionary *last_forecast = [hourly_forecast objectAtIndex:(intervalLength-1)];

	int nowTime = [[[first_forecast objectForKey:@"FCTTIME"] objectForKey:@"hour"] intValue];
	NSString *nowAMPM = [[first_forecast objectForKey:@"FCTTIME"] objectForKey:@"ampm"];
	if ([nowAMPM isEqualToString:@"PM"]) {
		nowTime -= 12;
	}
	i_titleNow.text = [[[NSString stringWithFormat:@"%d",nowTime] stringByAppendingString:@" "] stringByAppendingString:nowAMPM];
	
	int endTime = [[[last_forecast objectForKey:@"FCTTIME"] objectForKey:@"hour"] intValue];
	NSString *endAMPM = [[last_forecast objectForKey:@"FCTTIME"] objectForKey:@"ampm"];
	if ([endAMPM isEqualToString:@"PM"]) {
		endTime -= 12;
	}
	i_titleEnd.text = [[[NSString stringWithFormat:@"%d",endTime] stringByAppendingString:@" "] stringByAppendingString:endAMPM];

	i_titleLength.text = [[NSString stringWithFormat:@"%d",intervalLength] stringByAppendingString:@" hr"]; 
	i_titleHigh.text = @"High";
	i_titleLow.text = @"Low";

	i_realTempName.text = @"Temp:";
	i_realTempNow.text = [[[first_forecast objectForKey:@"temp"] objectForKey:@"english"] stringByAppendingString:@"° F"];
	NSMutableArray *realTempSparkData = [NSMutableArray array];
	for(int i = 0; i <= 17; ++i) {
		// numer formatter code from http://stackoverflow.com/questions/1448804/how-to-convert-an-nsstring-into-an-nsnumber
		NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
		[f setNumberStyle:NSNumberFormatterDecimalStyle];
		NSString *numberString = [[[hourly_forecast objectAtIndex:i] objectForKey:@"temp"] objectForKey:@"english"];
		NSNumber *myNumber = [f numberFromString:numberString];
		[f release];
		if (myNumber) {
			[realTempSparkData addObject:myNumber];
		}
		else {
			NSLog(@"NCWunderground: Got bad number string at position %d in hourly forecast. Bad.",i);
		}
	}
	[i_realTempSparkView setDataValues:realTempSparkData];
	i_realTempEnd.text = [[[last_forecast objectForKey:@"temp"] objectForKey:@"english"] stringByAppendingString:@"° F"];
	i_realTempHigh.text = [[[i_realTempSparkView dataMaximum] stringValue] stringByAppendingString:@"° F"];
	i_realTempLow.text = [[[i_realTempSparkView dataMinimum] stringValue] stringByAppendingString:@"° F"];

	i_feelsLikeName.text = @"Feels:";
	i_feelsLikeNow.text = [[[first_forecast objectForKey:@"feelslike"] objectForKey:@"english"] stringByAppendingString:@"° F"];
	NSMutableArray *feelsLikeSparkData = [NSMutableArray array];
	for(int i = 0; i <= intervalLength; ++i) {
		// numer formatter code from http://stackoverflow.com/questions/1448804/how-to-convert-an-nsstring-into-an-nsnumber
		NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
		[f setNumberStyle:NSNumberFormatterDecimalStyle];
		NSString *numberString = [[[hourly_forecast objectAtIndex:i] objectForKey:@"feelslike"] objectForKey:@"english"];
		NSNumber *myNumber = [f numberFromString:numberString];
		[f release];
		if (myNumber) {
			[feelsLikeSparkData addObject:myNumber];
		}
		else {
			NSLog(@"NCWunderground: Got bad number string at position %d in hourly forecast. Bad.",i);
		}
	}
	[_feelsLikeSparkView setDataValues:feelsLikeSparkData];
	i_feelsLikeEnd.text = [[[last_forecast objectForKey:@"feelslike"] objectForKey:@"english"] stringByAppendingString:@"° F"];
	i_feelsLikeHigh.text = [[[_feelsLikeSparkView dataMaximum] stringValue] stringByAppendingString:@"° F"];
	i_feelsLikeLow.text = [[[_feelsLikeSparkView dataMinimum] stringValue] stringByAppendingString:@"° F"];
}

- (void)updateBackgroundSubviewValues {
	// convenience pointer
	NSDictionary *current_observation = [_savedData objectForKey:@"current_observation"];

	_temperatureLabel.text = [[[current_observation objectForKey:@"temp_f"] stringValue] stringByAppendingString:@"° F"];
	_feelsLikeLabel.text = [@"Feels Like: " stringByAppendingString:[[current_observation objectForKey:@"feelslike_f"] stringByAppendingString:@"° F"]];
	_locationLabel.text = [[current_observation objectForKey:@"display_location"] objectForKey:@"full"];
	_humidityLabel.text = [@"Humidity: " stringByAppendingString:[current_observation objectForKey:@"relative_humidity"]];
	_windLabel.text = [[@"Wind: " stringByAppendingString:[[current_observation objectForKey:@"wind_mph"] stringValue]]  stringByAppendingString:@" mph"];
	
	NSString *wundergroundIconName = [[[[_savedData objectForKey:@"current_observation"] objectForKey:@"icon_url"] lastPathComponent] stringByDeletingPathExtension];
	NSString *localIconName;
	localIconName = [[_iconMap objectForKey:wundergroundIconName] objectForKey:@"icon"];
	_weatherTypeLabel.text = [[_iconMap objectForKey:wundergroundIconName] objectForKey:@"word"];
	if (localIconName == nil) {
		wundergroundIconName = [[_savedData objectForKey:@"current_observation"] objectForKey:@"icon"];
		localIconName = [[_iconMap objectForKey:wundergroundIconName] objectForKey:@"icon"];
	}
	_weatherIcon = [UIImage imageWithContentsOfFile:[_ammNCWundergroundWeeAppBundle pathForResource:localIconName ofType:@"png"]];
	_iconView.image=_weatherIcon;
}

- (void)loadBackgroundLeftSubviews {

	static const float r1off = 5.f; static const float r1height = 15.f; static const float r1y = r1off;
	static const float r2off = 8.f; static const float r2height = 15.f; static const float r2y = r1y+r1height+r2off;
	static const float r3off = 8.f; static const float r3height = 15.f; static const float r3y = r2y+r2height+r3off;
	static const float c0off = 2.f; static const float c0width = 45.f; static const float c0x = c0off;
	static const float c1off = 2.f; static const float c1width = 45.f; static const float c1x = c0x+c0width+c1off;
	static const float c2off = 2.f; static const float c2x = c1x+c1width+c2off;
	static const float c3off = 2.f; static const float c3width = 45.f;
	static const float c4off = 2.f; static const float c4width = 45.f;
	static const float c5off = 2.f; static const float c5width = 45.f;
	static const float rightbuff = 2.f;
	static const float c2width = 316 - c0off - c0width - c1off - c1width - c2off - c3off - c3width - c4off - c4width - c5off - c5width - rightbuff;
	static const float c3x = c2x+c2width+c3off;
	static const float c4x = c3x+c3width+c4off;
	static const float c5x = c4x+c4width+c5off;

	NSArray *backgroundLeftLabelArray = [NSArray arrayWithObjects:
		(i_titleNow = [[UILabel alloc] init]),
		(i_titleLength = [[UILabel alloc] init]),
		(i_titleEnd = [[UILabel alloc] init]),
		(i_titleHigh = [[UILabel alloc] init]),
		(i_titleLow = [[UILabel alloc] init]),
		(i_realTempName = [[UILabel alloc] init]),
		(i_realTempNow = [[UILabel alloc] init]),
		(i_realTempEnd = [[UILabel alloc] init]),
		(i_realTempHigh = [[UILabel alloc] init]),
		(i_realTempLow = [[UILabel alloc] init]),
		(i_feelsLikeName = [[UILabel alloc] init]),
		(i_feelsLikeNow = [[UILabel alloc] init]),
		(i_feelsLikeEnd = [[UILabel alloc] init]),
		(i_feelsLikeHigh = [[UILabel alloc] init]),
		(i_feelsLikeLow = [[UILabel alloc] init]),nil];

	// Initialize all the labels
	for (UILabel *iterView in backgroundLeftLabelArray) {
		[self clearLabelSmallWhiteText:iterView];
		iterView.textAlignment = NSTextAlignmentCenter;
	}

	// row 1
	i_titleNow.frame = CGRectMake(c1x,r1y,c1width,r1height);
	i_titleLength.frame = CGRectMake(c2x,r1y,c2width,r1height);
	i_titleEnd.frame = CGRectMake(c3x,r1y,c3width,r1height);
	i_titleHigh.frame = CGRectMake(c4x,r1y,c4width,r1height);
	i_titleLow.frame = CGRectMake(c5x,r1y,c5width,r1height);

	// row 2
	i_realTempName.frame = CGRectMake(c0x,r2y,c0width,r2height);
	i_realTempNow.frame = CGRectMake(c1x,r2y,c1width,r2height);
	i_realTempSparkView = [[ASBSparkLineView alloc] initWithFrame:CGRectMake(c2x,r2y,c2width,r2height)];
	i_realTempEnd.frame = CGRectMake(c3x,r2y,c3width,r2height);
	i_realTempHigh.frame = CGRectMake(c4x,r2y,c4width,r2height);
	i_realTempLow.frame = CGRectMake(c5x,r2y,c5width,r2height);

	// row 3
	i_feelsLikeName.frame = CGRectMake(c0x,r3y,c0width,r3height);
	i_feelsLikeNow.frame = CGRectMake(c1x,r3y,c1width,r3height);
	_feelsLikeSparkView = [[ASBSparkLineView alloc] initWithFrame:CGRectMake(c2x,r3y,c2width,r3height)];
	i_feelsLikeEnd.frame = CGRectMake(c3x,r3y,c3width,r3height);
	i_feelsLikeHigh.frame = CGRectMake(c4x,r3y,c4width,r3height);
	i_feelsLikeLow.frame = CGRectMake(c5x,r3y,c5width,r3height);

	NSArray *backgroundLeftSparkArray = [NSArray arrayWithObjects: 
		i_realTempSparkView,_feelsLikeSparkView,nil];
	// Color all of the spark views
	for (ASBSparkLineView *iterView in backgroundLeftSparkArray) {
		iterView.penColor = [UIColor whiteColor];
		iterView.backgroundColor = [UIColor clearColor];
		iterView.showCurrentValue = NO;
	}

	if([_savedData objectForKey:@"last request"]) {
		[self updateBackgroundLeftSubviewValues];
	}


	// add and release all the views
	for (UILabel *iterView in backgroundLeftLabelArray) {
		[_backgroundLeftView addSubview:iterView];
		[iterView release];
	}
	for (ASBSparkLineView *iterView in backgroundLeftSparkArray) {
		[_backgroundLeftView addSubview:iterView];
		[iterView release];
	}
}

- (void)loadBackgroundSubviews {
	NSArray *backgroundLabelArrayLeftCol = [NSArray arrayWithObjects:
		(_temperatureLabel = [[UILabel alloc] init]),
		(_feelsLikeLabel = [[UILabel alloc] init]),
		(_weatherTypeLabel = [[UILabel alloc] init]),nil];
	NSArray *backgroundLabelArrayRightCol = [NSArray arrayWithObjects:
		(_locationLabel = [[UILabel alloc] init]),
		(_humidityLabel = [[UILabel alloc] init]),
		(_windLabel = [[UILabel alloc] init])]

	float temperatureWidth = (316.f - 8 - [self viewHeight] - 1) / 2;
	float moreInfoWidth = 316.f - 8.f - [self viewHeight] - temperatureWidth;

	_temperatureLabel.frame = CGRectMake(2.f,2.f,temperatureWidth,30.f);
	_temperatureLabel.font = [UIFont systemFontOfSize:30.f];
	_feelsLikeLabel.frame = CGRectMake(2.f,34.f,temperatureWidth,14.f);
	_weatherTypeLabel.frame = CGRectMake(2.f,50.f,temperatureWidth,14.f);
	_locationLabel.frame = CGRectMake(6.f + temperatureWidth + [self viewHeight],5.f,moreInfoWidth,15.f);
	_humidityLabel.frame = CGRectMake(6.f + temperatureWidth + [self viewHeight],28.f,moreInfoWidth,15.f);
	_windLabel.frame = CGRectMake(6.f + temperatureWidth + [self viewHeight],51.f,moreInfoWidth,15.f);

	_iconView = [[UIImageView alloc] init];
	_iconView.frame = CGRectMake(4.f + temperatureWidth,0.f,[self viewHeight],[self viewHeight]);

	if([_savedData objectForKey:@"last request"]) {
		[self updateBackgroundSubviewValues];
	}

	for (UIView *iterView in backgroundLabelArrayRightCol) {
		[iterView setTextAlignment:NSTextAlignmentRight];
	}
	for (UIView *iterView in [backgroundLabelArrayLeftCol arrayByAddingObjectsFromArray:backgroundLabelArrayRightCol]) {
		[self clearLabelSmallWhiteText:iterView];
		[_backgroundView addSubview:iterView];
		[iterView relesae];
	}
	
	[_backgroundView addSubview:_iconView];
	[_iconView release];
}

- (void)loadFullView {
	// Add subviews to _backgroundView (or _view) here.
	[self loadData];
	[self loadBackgroundSubviews];
	[self loadBackgroundLeftSubviews];
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
		NSLog(@"NCWunderground: No save file found.");
	}

	NSDictionary *defaultsDom = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.amm.ncwunderground"];
	NSNumber *updateSeconds = [defaultsDom objectForKey:@"updateSeconds"];
	static const int updateLength;
	if (updateSeconds) {
		updateLength = [updateSeconds integerValue];
	}
	else {
		NSLog(@"NCWunderground: User's defaults contain no update delay. Defaulting to 5 minutes.");
		updateLength = 300; // default to 5 minutes
	}

	if ([[NSDate date] timeIntervalSince1970] - [[_savedData objectForKey:@"last request"] integerValue] >= updateLength) {
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
	// get data from website by HTTP GET request
	NSHTTPURLResponse * response;
	NSError * error;

	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	NSDictionary *defaultsDom = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.amm.ncwunderground"];
	NSString *apiKey = [defaultsDom objectForKey:@"APIKey"];
	if (apiKey == nil) {
		NSLog(@"NCWunderground: got null APIKey, not updating data.");
		[request release];

		// TODO
		// We shouldn't silently fail here. We should overwrite the
		// views with something instructing the user to enter the API key.

		return;
	}
	NSMutableString *urlString = [NSMutableString stringWithString:@"http://api.wunderground.com/api/"];
	[urlString appendString:apiKey];
	[urlString appendString:@"/conditions/hourly/forecast10day/q/"];
	[urlString appendString:[_savedData objectForKey:@"latitude"]];
	[urlString appendString:@","];
	[urlString appendString:[_savedData objectForKey:@"longitude"]];
	[urlString appendString:@".json"];
	NSLog(@"NCWunderground: Making request with url %@",urlString);
	[request setURL:[NSURL URLWithString:urlString]];
	[request setHTTPMethod:@"GET"];

	NSData *resultJSON = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	if (!resultJSON) {
		NSLog(@"NCWunderground: Unsuccessful connection attempt. Data not updated.");
		[request release];
		return;
	}
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
	[self updateBackgroundLeftSubviewValues];
	[self updateBackgroundSubviewValues];
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
