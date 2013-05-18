#import "AMMNCWundergroundModel.h"
#import "AMMNCWundergroundController.h"
#import "AMMNCWundergroundView.h"
#import "CocoaLumberjack/Lumberjack/DDLog.h"

@implementation AMMNCWundergroundModel

@synthesize saveData = i_saveData;
@synthesize backgroundQueue = i_backgroundQueue;
@synthesize controller = i_controller;
@synthesize ammNCWundergroundWeeAppBundle = i_ammNCWundergroundWeeAppBundle;

static int ddLogLevel = LOG_LEVEL_OFF;

- (id)initWithController:(AMMNCWundergroundController *)controller {
    if ((self = [super init])) {
        i_saveData = [[NSMutableDictionary alloc] init];
        i_backgroundQueue = dispatch_queue_create("com.amm.ncwunderground.backgroundqueue", NULL);
        i_controller = controller;
        i_ammNCWundergroundWeeAppBundle = [NSBundle bundleForClass:[self class]];
    }
    return self;
}

- (void)setLocationPermissions:(BOOL)value {
    NSNumber *authorizationValue = [NSNumber numberWithBool:value];
    NSMutableDictionary *workingDict = [NSMutableDictionary dictionaryWithDictionary:self.saveData];
    [workingDict setObject:authorizationValue forKey:@"locationPermissions"];
    self.saveData = workingDict;
}

- (BOOL)haveLocationPermissions {
    NSNumber *authorizationValue = [self.saveData objectForKey:@"locationPermissions"];
    return [authorizationValue boolValue];
}

- (void)setLogLevel:(int)level {
    ddLogLevel = level;
}

// Returns: current latitude as a double
- (double)latitudeDouble {
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    [f setNumberStyle:NSNumberFormatterDecimalStyle];
    NSNumber *latitude = [f numberFromString:[self.saveData objectForKey:@"latitude"]];
    return [latitude doubleValue];
}

// Returns: current longitude as a double
- (double)longitudeDouble {
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    [f setNumberStyle:NSNumberFormatterDecimalStyle];
    NSNumber *longitude = [f numberFromString:[self.saveData objectForKey:@"longitude"]];
    return [longitude doubleValue];
}

// Returns: longitude of the observation station
- (double)obsLatitudeDouble {
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    [f setNumberStyle:NSNumberFormatterDecimalStyle];
    NSNumber *latitude = [f numberFromString:[[[self.saveData objectForKey:@"current_observation"] objectForKey:@"observation_location"] objectForKey:@"latitude"]];
    return [latitude doubleValue];
}

// Returns: latitude of the observation station
- (double)obsLongitudeDouble {
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    [f setNumberStyle:NSNumberFormatterDecimalStyle];
    NSNumber *latitude = [f numberFromString:[[[self.saveData objectForKey:@"current_observation"] objectForKey:@"observation_location"] objectForKey:@"longitude"]];
    return [latitude doubleValue];
}

// Returns: last request date (seconds since 1970) as an int
- (int)lastRequestInt {
    return [[self.saveData objectForKey:@"last_request"] intValue];
}

// Takes: index into hourly forecast array
// Returns: time for that hour in 12 hour format, string
- (NSString *)hourlyTimeLocalizedString:(int)forecastIndex {
    // http://stackoverflow.com/questions/1929958/how-can-i-determine-if-iphone-is-set-for-12-hour-or-24-hour-time-display
    NSString *formatStringForHours = [NSDateFormatter dateFormatFromTemplate:@"j" options:0 locale:[NSLocale currentLocale]];
    NSRange containsA = [formatStringForHours rangeOfString:@"a"];
    BOOL hasAMPM = containsA.location != NSNotFound;

    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    [f setNumberStyle:NSNumberFormatterDecimalStyle];
    int hour = [[f numberFromString:[[[[self.saveData objectForKey:@"hourly_forecast"] objectAtIndex:forecastIndex] objectForKey:@"FCTTIME"] objectForKey:@"hour"]] intValue];
    
    if (hasAMPM) {
        if (hour > 12)
            hour -= 12;
        if (hour == 0)
            hour = 12;
        return [NSString stringWithFormat:@"%d %@",hour,[[[[self.saveData objectForKey:@"hourly_forecast"] objectAtIndex:forecastIndex] objectForKey:@"FCTTIME"] objectForKey:@"ampm"]];
    }
    else { // 24 hour time. What is this nonsense? :)
        return [NSString stringWithFormat:@"%d:00",hour];
    }
}

// Takes: index into hourly forecast array
// Returns: Real temp string for that hour with °F
- (NSString *)hourlyTempString:(int)forecastIndex ofType:(int)type {
    NSString *typeString;
    switch (type) {
        case AMMTempTypeF:
            typeString = @"°F";
            break;
        case AMMTempTypeC:
            typeString = @"°C";
            break;
        default:
            typeString = @"";
            break;
    }
    NSDictionary *temps = (NSDictionary *)[[[self.saveData objectForKey:@"hourly_forecast"] objectAtIndex:forecastIndex] objectForKey:@"temp"];
    NSString *tempString;
    switch (type) {
        case AMMTempTypeF:
            tempString = [temps objectForKey:@"english"];
            break;
        case AMMTempTypeC:
            tempString = [temps objectForKey:@"metric"];
            break;
    }
    return [NSString stringWithFormat:@"%@ %@",tempString,typeString];
}

// Takes: index into hourly forecast array
// Returns: Feels like temp string for that hour with °F
- (NSString *)hourlyFeelsString:(int)forecastIndex ofType:(int)type{
    NSString *typeString;
    switch (type) {
        case AMMTempTypeF:
            typeString = @"°F";
            break;
        case AMMTempTypeC:
            typeString = @"°C";
            break;
        default:
            typeString = @"";
            break;
    }
    NSDictionary *temps = (NSDictionary *)[[[self.saveData objectForKey:@"hourly_forecast"] objectAtIndex:forecastIndex] objectForKey:@"feelslike"];
    NSString *tempString;
    switch (type) {
        case AMMTempTypeF:
            tempString = [temps objectForKey:@"english"];
            break;
        case AMMTempTypeC:
            tempString = [temps objectForKey:@"metric"];
            break;
    }
    return [NSString stringWithFormat:@"%@ %@",tempString,typeString];
}

// Takes: start index and length in hourly forecast array
// Returns: array of temps as NSNumber's in that range
- (NSMutableArray *)hourlyTempNumberArray:(int)startIndex length:(int)length ofType:(int)type {
    if (startIndex + length >= [[self.saveData objectForKey:@"hourly_forecast"] count]) {
        DDLogError(@"NCWunderground: hourlyTempNumberArray requested past hourly_forecast length. Bad.");
        return nil;
    }
    NSMutableArray *theArray = [NSMutableArray array];
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    [f setNumberStyle:NSNumberFormatterDecimalStyle];
    for (int i = startIndex; i < startIndex + length; ++i) {
        NSDictionary *temps = (NSDictionary *)[[[self.saveData objectForKey:@"hourly_forecast"] objectAtIndex:i] objectForKey:@"temp"];
        NSString *tempString;
        switch (type) {
            case AMMTempTypeF:
                tempString = [temps objectForKey:@"english"];
                break;
            case AMMTempTypeC:
                tempString = [temps objectForKey:@"metric"];
                break;
        }
        NSNumber *theNumber = [f numberFromString:tempString];
        [theArray addObject:theNumber];
    }
    return theArray;
}

// Takes: start index and length in hourly forecast array
// Returns: array of feelslike as NSNumber's in that range
- (NSMutableArray *)hourlyFeelsNumberArray:(int)startIndex length:(int)length ofType:(int)type {
    if (startIndex + length >= [[self.saveData objectForKey:@"hourly_forecast"] count]) {
        DDLogError(@"NCWunderground: hourlyTempNumberArrayF requested past hourly_forecast length. Bad.");
        return nil;
    }
    NSMutableArray *theArray = [NSMutableArray array];
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    [f setNumberStyle:NSNumberFormatterDecimalStyle];
    for (int i = startIndex; i < startIndex + length; ++i) {
        NSDictionary *temps = (NSDictionary *)[[[self.saveData objectForKey:@"hourly_forecast"] objectAtIndex:i] objectForKey:@"feelslike"];
        NSString *tempString;
        switch (type) {
            case AMMTempTypeF:
                tempString = [temps objectForKey:@"english"];
                break;
            case AMMTempTypeC:
                tempString = [temps objectForKey:@"metric"];
                break;
        }
        NSNumber *theNumber = [f numberFromString:tempString];
        [theArray addObject:theNumber];
    }
    return theArray;
}

// Returns: current temp string including type specifier
- (NSString *)currentTempStringOfType:(int)type {
    NSString *typeString;
    switch (type) {
        case AMMTempTypeF:
            typeString = @"°F";
            break;
        case AMMTempTypeC:
            typeString = @"°C";
            break;
        default:
            typeString = @"";
            break;
    }
    NSDictionary *curObs = (NSDictionary *)[self.saveData objectForKey:@"current_observation"];
    float tempFloat = 0;
    switch (type) {
        case AMMTempTypeF:
            tempFloat = [[curObs objectForKey:@"temp_f"] floatValue];
            break;
        case AMMTempTypeC:
            tempFloat = [[curObs objectForKey:@"temp_c"] floatValue];
            break; 
    }
    return [NSString stringWithFormat:@"%.1f %@",tempFloat,typeString];
}

// Returns: current feels string including type specifier
- (NSString *)currentFeelsStringOfType:(int)type {
    NSString *typeString;
    switch (type) {
        case AMMTempTypeF:
            typeString = @"°F";
            break;
        case AMMTempTypeC:
            typeString = @"°C";
            break;
        default:
            typeString = @"";
            break;
    }
    NSDictionary *curObs = (NSDictionary *)[self.saveData objectForKey:@"current_observation"];
    float tempFloat = 0;
    switch (type) {
        case AMMTempTypeF:
            tempFloat = [[curObs objectForKey:@"feelslike_f"] floatValue];
            break;
        case AMMTempTypeC:
            tempFloat = [[curObs objectForKey:@"feelslike_c"] floatValue];
            break; 
    }
    return [NSString stringWithFormat:@"%.1f %@",tempFloat,typeString];
}

// Returns: current humidity string, including %
- (NSString *)currentHumidityString {
    return [[self.saveData objectForKey:@"current_observation"] objectForKey:@"relative_humidity"];
}

// Returns: current wind speed, including mph
- (NSString *)currentWindStringOfType:(int)type {
    NSString *typeString;
    NSString *speedString;
    NSDictionary *curObs = (NSDictionary *)[self.saveData objectForKey:@"current_observation"];
    switch (type) {
        case AMMWindTypeM:
            typeString = [self.ammNCWundergroundWeeAppBundle localizedStringForKey:@"MPH"
                                                                             value:@"MPH"
                                                                             table:nil];
            speedString = [[curObs objectForKey:@"wind_mph"] stringValue];
            break;
        case AMMWindTypeK:
            typeString = [self.ammNCWundergroundWeeAppBundle localizedStringForKey:@"KPH"
                                                                             value:@"KPH"
                                                                             table:nil];
            speedString = [[curObs objectForKey:@"wind_kph"] stringValue];
            break;
        case AMMWindTypeKt:
            typeString = [self.ammNCWundergroundWeeAppBundle localizedStringForKey:@"kt"
                                                                             value:@"kt"
                                                                             table:nil];
            speedString = [NSString stringWithFormat:@"%.1f",([[curObs objectForKey:@"wind_kph"] floatValue] * 0.539957)];
            break;
    }
    return [NSString stringWithFormat:@"%@ %@",speedString,typeString];
}

// Returns: current location (city, state)
- (NSString *)currentLocationString {
    return [[[self.saveData objectForKey:@"current_observation"] objectForKey:@"display_location"] objectForKey:@"full"];
}

// Returns: current conditions icon name
- (NSString *)currentConditionsIconName {
    return [[[[self.saveData objectForKey:@"current_observation"] objectForKey:@"icon_url"] lastPathComponent] stringByDeletingPathExtension];
}

- (NSString *)currentConditionsString {
    return [[self.saveData objectForKey:@"current_observation"] objectForKey:@"weather"];
}

- (NSString *)currentConditionsURL {
    return [[[self.saveData objectForKey:@"current_observation"] objectForKey:@"forecast_url"] stringByReplacingOccurrencesOfString:@"www.wunderground.com"
                                                                                                                         withString:@"i.wund.com"];
}

// Takes: index into daily forecast array
// Returns: short name of the corresponding day (Mon, Tue, etc)
// TODO localize
- (NSString *)dailyDayShortString:(int)forecastIndex {
    return [[[[self.saveData objectForKey:@"forecastday"] objectAtIndex:forecastIndex] objectForKey:@"date"] objectForKey:@"weekday_short"];
}

// Takes: index into daily forecast array
// Returns: high temperature for that day, NOT including °F
- (NSString *)dailyHighString:(int)forecastIndex ofType:(int)type {
    NSDictionary *highDict = (NSDictionary *)[[[self.saveData objectForKey:@"forecastday"] objectAtIndex:forecastIndex] objectForKey:@"high"];
    switch (type) {
        case AMMTempTypeF:
            return [highDict objectForKey:@"fahrenheit"];
        case AMMTempTypeC:
            return [highDict objectForKey:@"celsius"];
    }
    return @"";
}

// Takes: index into daily forecast array
// Returns: low temperature for that day, NOT including °F
- (NSString *)dailyLowString:(int)forecastIndex ofType:(int)type{
    NSDictionary *lowDict = (NSDictionary *)[[[self.saveData objectForKey:@"forecastday"] objectAtIndex:forecastIndex] objectForKey:@"low"];
    switch (type) {
        case AMMTempTypeF:
            return [lowDict objectForKey:@"fahrenheit"];
        case AMMTempTypeC:
            return [lowDict objectForKey:@"celsius"];
    }
    return @"";
}

// Takes: index into daily forecast array
// Returns: percentage of perciptation for that day, including %
- (NSString *)dailyPOPString:(int)forecastIndex {
    return [NSString stringWithFormat:@"%@%%",[[[[self.saveData objectForKey:@"forecastday"] objectAtIndex:forecastIndex] objectForKey:@"pop"] stringValue]];
}

// Takes: index into daily forecast array
// Returns: name of icon for weather for that day
- (NSString *)dailyConditionsIconName:(int)forecastIndex {
    return [[[[[self.saveData objectForKey:@"forecastday"] objectAtIndex:forecastIndex] objectForKey:@"icon_url"] lastPathComponent] stringByDeletingPathExtension];
}

// Takes: path to the save file
// Returns: YES if it was able to load data, NO otherwise
- (BOOL)loadSaveData:(NSString *)saveFile inDirectory:(NSString *)saveDirectory {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *fullPath = [saveDirectory stringByAppendingString:saveFile];

    if ([fileManager fileExistsAtPath:fullPath]) {
        NSMutableDictionary *tempDict = [[NSMutableDictionary alloc] initWithContentsOfFile:fullPath];
        self.saveData = tempDict;
        if ([self.saveData objectForKey:@"last_request"] == nil) {
            DDLogError(@"NCWunderground: save file exists, but appears corrupted.");
            return NO;
        }
        return YES;
    }
    else {
        return NO;
    }
}

- (void)saveDataToFile:(NSString *)saveFile inDirectory:(NSString *)saveDirectory {
    NSError *error;
    BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:saveDirectory
                                             withIntermediateDirectories:YES
                                                              attributes:nil
                                                                   error:&error];
    if (!success) {
        DDLogError(@"NCWunderground: Could not save to disk because directory could not be created. Error: %@",[error localizedDescription]);
        return;
    }
    [self.saveData writeToFile:[saveDirectory stringByAppendingString:saveFile] atomically:YES];
}

- (void) startURLRequestWithQuery:(NSString *)query {
    // start a URL request in the backgroundQueue
    dispatch_async(self.backgroundQueue,^(void) {
	    // get data from website by HTTP GET request
	    NSHTTPURLResponse * response;
	    NSError * error;
        
	    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	    NSDictionary *defaultsDom = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.amm.ncwunderground"];
	    NSString *apiKey = [defaultsDom objectForKey:@"APIKey"];
	    if (apiKey == nil) {
            DDLogError(@"NCWunderground: got null APIKey, not updating data.");
            dispatch_async(dispatch_get_main_queue(),^(void) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[self.ammNCWundergroundWeeAppBundle localizedStringForKey:@"NO_API_KEY"
                                                                                                                            value:@"No API Key"
                                                                                                                            table:nil]
                                                                message:[self.ammNCWundergroundWeeAppBundle localizedStringForKey:@"ENTER_API_KEY"
                                                                                                                            value:@"Please enter a Weather Underground API Key in Settings/Notifications/Weather Underground Widget."
                                                                                                                            table:nil]
                                                               delegate:nil
                                                      cancelButtonTitle:[self.ammNCWundergroundWeeAppBundle localizedStringForKey:@"OK"
                                                                                                                            value:@"OK"
                                                                                                                            table:nil]
                                                      otherButtonTitles:nil];
                [alert show];
                [self.controller dataDownloadFailed];
		    });
            return;
	    }
	    NSString *urlString = [NSString stringWithFormat:@"http://api.wunderground.com/api/%@/conditions/hourly/forecast10day/lang:%@/pws:%d/q",
                               apiKey,[self.ammNCWundergroundWeeAppBundle localizedStringForKey:@"WU_LANG_CODE"
                                                                                          value:@"EN"
                                                                                          table:nil],
                               [[defaultsDom objectForKey:@"allowPWS"] boolValue]];
	    if (query) {
            urlString = [NSString stringWithFormat:@"%@/%@.json",urlString,query];
	    }
	    else {
            urlString = [NSString stringWithFormat:@"%@/%@,%@.json",urlString,[self.saveData objectForKey:@"latitude"],[self.saveData objectForKey:@"longitude"]];
	    }
	    [request setURL:[NSURL URLWithString:urlString]];
	    [request setHTTPMethod:@"GET"];
	    [request setTimeoutInterval:10];
        
	    NSData *resultJSON = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	    if (!resultJSON) {
            DDLogWarn(@"NCWunderground: Unsuccessful connection attempt. Data not updated.");
            dispatch_async(dispatch_get_main_queue(),^(void) {
                /*UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[self.ammNCWundergroundWeeAppBundle localizedStringForKey:@"CONNECTION_FAILED"
                                                                                                                            value:@"Connection Failed"
                                                                                                                            table:nil]
                                                                message:[self.ammNCWundergroundWeeAppBundle localizedStringForKey:@"FAILED_TO_CONNECT"
                                                                                                                            value:@"Weather widget failed to connect to server."
                                                                                                                            table:nil]
                                                               delegate:nil
                                                      cancelButtonTitle:[self.ammNCWundergroundWeeAppBundle localizedStringForKey:@"OK"
                                                                                                                            value:@"OK"
                                                                                                                            table:nil]
                                                      otherButtonTitles:nil];
                [alert show];*/
                [self.controller dataDownloadFailed];
		    });
            return;
	    }
        
	    if(NSClassFromString(@"NSJSONSerialization")) {
            NSError *error = nil;
            NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:resultJSON options:0 error:&error];
            if (error) {
                DDLogError(@"NCWunderground: JSON was malformed. Bad.");
                dispatch_async(dispatch_get_main_queue(),^(void) {
                    /*UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[self.ammNCWundergroundWeeAppBundle localizedStringForKey:@"DATA_CORRUPTED"
                                                                                                                                value:@"Data Corrupted"
                                                                                                                                table:nil]
                                                                    message:[self.ammNCWundergroundWeeAppBundle localizedStringForKey:@"DATA_CORRUPTED_LONG"
                                                                                                                                value:@"Weather widget received data from the server, but it was corrupted."
                                                                                                                                table:nil]
                                                                   delegate:nil
                                                          cancelButtonTitle:[self.ammNCWundergroundWeeAppBundle localizedStringForKey:@"OK"
                                                                                                                                value:@"OK"
                                                                                                                                table:nil]
                                                          otherButtonTitles:nil];
                    [alert show];*/
                    [self.controller dataDownloadFailed];
                });
                return;
            }
            
            if ([[jsonDict objectForKey:@"response"] objectForKey:@"error"]) {
                DDLogError(@"NCWunderground: We got a well-formed JSON, but it's an error: %@ / %@",
                           [[[jsonDict objectForKey:@"response"] objectForKey:@"error"] objectForKey:@"type"],
                           [[[jsonDict objectForKey:@"response"] objectForKey:@"error"] objectForKey:@"description"]);
                dispatch_async(dispatch_get_main_queue(),^(void) {
                    /*UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@ (%@)",[self.ammNCWundergroundWeeAppBundle localizedStringForKey:@"SERVER_ERROR"
                                                                                                                                                                      value:@"Server Error"
                                                                                                                                                                      table:nil],
                                                                             [[[jsonDict objectForKey:@"response"] objectForKey:@"error"] objectForKey:@"type"]]
                                                                    message:[NSString stringWithFormat:@"%@: %@.",[self.ammNCWundergroundWeeAppBundle localizedStringForKey:@"SERVER_RETURNED_ERROR"
                                                                                                                                                                      value:@"The weather server returned an error"
                                                                                                                                                                      table:nil],
                                                                             [[[jsonDict objectForKey:@"response"] objectForKey:@"error"] objectForKey:@"description"]]
                                                                   delegate:nil
                                                          cancelButtonTitle:[self.ammNCWundergroundWeeAppBundle localizedStringForKey:@"OK"
                                                                                                                                value:@"OK"
                                                                                                                                table:nil]
                                                          otherButtonTitles:nil];
                    [alert show];*/
                    [self.controller dataDownloadFailed];
                });
                return;
            }
            
            if ([jsonDict isKindOfClass:[NSDictionary class]]) {
                dispatch_async(dispatch_get_main_queue(),^(void) { // We're changing a lot of things. Let's do it in the main thread for safety
                    DDLogInfo(@"NCWunderground: Data download succeeded. Parsing.");
                    // update last-request time
                    NSMutableDictionary *workingDict = [NSMutableDictionary dictionaryWithDictionary:self.saveData];
                    [workingDict setObject:[NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]]
                                    forKey:@"last_request"];
                    
                    // convenience pointers
                    NSDictionary *currentObservation = [jsonDict objectForKey:@"current_observation"];
                    NSDictionary *dailyForecast = [[jsonDict objectForKey:@"forecast"] objectForKey:@"simpleforecast"];
                    
                    // import current observations, daily forecast, and hourly forecast
                    [workingDict setObject:currentObservation forKey:@"current_observation"];
                    [workingDict setObject:[dailyForecast objectForKey:@"forecastday"] forKey:@"forecastday"];
                    [workingDict setObject:[jsonDict objectForKey:@"hourly_forecast"] forKey:@"hourly_forecast"];
                    
                    self.saveData = workingDict;
                    
                    [self.controller dataDownloaded];
                });
            }
            else {
                DDLogError(@"NCWunderground: JSON was non-dict. Bad.");
                dispatch_async(dispatch_get_main_queue(),^(void) {
                    /*UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[self.ammNCWundergroundWeeAppBundle localizedStringForKey:@"DATA_CORRUPTED"
                                                                                                                                value:@"Data Corrupted"
                                                                                                                                table:nil]
                                                                    message:[self.ammNCWundergroundWeeAppBundle localizedStringForKey:@"DATA_CORRUPTED_LONG"
                                                                                                                                value:@"Weather widget received data from the server, but it was corrupted."
                                                                                                                                table:nil]
                                                                   delegate:nil
                                                          cancelButtonTitle:[self.ammNCWundergroundWeeAppBundle localizedStringForKey:@"OK"
                                                                                                                                value:@"OK"
                                                                                                                                table:nil]
                                                          otherButtonTitles:nil];
                    [alert show];*/
                    [self.controller dataDownloadFailed];
                });
                return;
            }
	    }
	    else {
            DDLogError(@"NCWunderground: We don't have NSJSONSerialization. Bad.");
            dispatch_async(dispatch_get_main_queue(),^(void) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[self.ammNCWundergroundWeeAppBundle localizedStringForKey:@"INVALID_IOS"
                                                                                                                            value:@"Invalid iOS Version"
                                                                                                                            table:nil]
                                                                message:[self.ammNCWundergroundWeeAppBundle localizedStringForKey:@"DOES_NOT_SUPPORT"
                                                                                                                            value:@"Your version of iOS does not support NSJSONSerialization. Please contact the developer at <drewmm@gmail.com>."
                                                                                                                            table:nil]
                                                               delegate:nil
                                                      cancelButtonTitle:[self.ammNCWundergroundWeeAppBundle localizedStringForKey:@"OK"
                                                                                                                            value:@"OK"
                                                                                                                            table:nil]
                                                      otherButtonTitles:nil];
                [alert show];
                [self.controller dataDownloadFailed];
		    });
            return;
	    }
	});
}

// Does: Takes in updated location and sets it.
//       Then starts the URL request on the background queue.
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    DDLogVerbose(@"NCWunderground: didUpdateToLocation: %@", [locations lastObject]);
    if ([self.controller locationUpdated] == NO) {
        if (locations != nil) {
            [self.controller setLocationUpdated:YES];
            [[self.controller locationManager] stopUpdatingLocation];
            NSMutableDictionary *workingDict = [NSMutableDictionary dictionaryWithDictionary:self.saveData];
            [workingDict setObject:[NSString stringWithFormat:@"%.8f", [[locations lastObject] coordinate].latitude]
                            forKey:@"latitude"];
            [workingDict setObject:[NSString stringWithFormat:@"%.8f", [[locations lastObject] coordinate].longitude]
                            forKey:@"longitude"];
            self.saveData = workingDict;
	    [self startURLRequestWithQuery:nil];
        }
        else {
            DDLogError(@"NCWunderground: didUpdateToLocation called but newLocation nil. Bad.");
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    DDLogError(@"NCWunderground: location manager failed with error %@",error);
    if (error.code == kCLErrorDenied) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[self.ammNCWundergroundWeeAppBundle localizedStringForKey:@"LOCATION_DENIED"
                                                                                                                    value:@"Location Denied"
                                                                                                                    table:nil]
                                                        message:[error localizedDescription]
                                                       delegate:nil
                                              cancelButtonTitle:[self.ammNCWundergroundWeeAppBundle localizedStringForKey:@"OK"
                                                                                                                    value:@"OK"
                                                                                                                    table:nil]
                                              otherButtonTitles:nil];
        [alert show];
        [self.controller.view setLoading:NO];
        [self.controller.locationManager stopUpdatingLocation];
    }
}

@end
