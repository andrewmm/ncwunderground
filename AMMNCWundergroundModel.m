#import "AMMNCWundergroundModel.h"

@implementation AMMNCWundergroundModel

- (id)initWithController:(AMMNCWundergroundController *)controller {
    i_saveData = [[NSMutableDictionary alloc] init];
    backgroundQueue = dispatch_queue_create("com.amm.ncwunderground.backgroundqueue", NULL);
    i_controller = controller;
    [super init];
}

- (void)dealloc {
    [i_saveData release];
    i_saveData = nil;
    dispatch_release(backgroundQueue);
}

// Returns: current latitude as a double
- (double)latitudeDouble {
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    [f setNumberStyle:NSNumberFormatterDecimalStyle];
    NSNumber *latitude = [f numberFromString:[i_saveData objectForKey:
        @"latitude"]];
    [f release];
    return [latitude doubleValue];
}

// Returns: current longitude as a double
- (double)longitudeDouble {
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    [f setNumberStyle:NSNumberFormatterDecimalStyle];
    NSNumber *longitude = [f numberFromString:[i_saveData objectForKey:
        @"longitude"]];
    [f release];
    return [longitude doubleValue];
}

// Returns: last request date (seconds since 1970) as an int
- (int)lastRequestInt {
    return [last_request intValue];
}

// Takes: index into hourly forecast array
// Returns: time for that hour in 12 hour format, string
- (NSString *)hourlyTime12HrString:(int)forecastIndex {
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    [f setNumberStyle:NSNumberFormatterDecimalStyle];
    int hour = [[f numberFromString:[[[[i_saveData objectForKey:
        @"hourly_forecast"] objectAtIndex:forecastIndex] objectForKey:
        @"FCTTIME"] objectForKey:@"hour"]] intValue];
    if (hour > 12)
        hour -= 12;
    if (hour == 0)
        hour = 12;
    return [NSString stringWithFormat:@"%d %@",hour,[[[[i_saveData objectForKey:
        @"hourly_forecast"] objectAtIndex:forecastIndex] objectForKey:
        @"FCTTIME"] objectForKey:@"ampm"]];
}

// Takes: index into hourly forecast array
// Returns: Real temp string for that hour with °F
- (NSString *)hourlyTempStringF:(int)forecastIndex {
    return [NSString stringWithFormat:@"%@ °F",[[[[i_saveData objectForKey:
        @"hourly_forecast"] objectAtIndex:forecastIndex] objectForKey:
        @"temp"] objectForKey:@"english"]];
}

// Takes: index into hourly forecast array
// Returns: Feels like temp string for that hour with °F
- (NSString *)hourlyFeelsStringF:(int)forecastIndex {
    return [NSString stringWithFormat:@"%@ °F",[[[[i_saveData objectForKey:
        @"hourly_forecast"] objectAtIndex:forecastIndex] objectForKey:
        @"feelslike"] objectForKey:@"english"]];
}

// Takes: start index and length in hourly forecast array
// Returns: array of temps as NSNumber's in that range
- (NSMutableArray *)hourlyTempNumberArrayF:(int)startIndex length:(int)length {
    if (startIndex + length >= [[i_saveData objectForKey:
        @"hourly_forecast"] count]) {
        NSLog(@"NCWunderground: hourlyTempNumberArrayF requested past hourly_forecast length. Bad.");
        return nil;
    }
    NSMutableArray *theArray = [NSMutableArray array];
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    [f setNumberStyle:NSNumberFormatterDecimalStyle];
    for (int i = startIndex; i < startIndex + length; ++i) {
        NSNumber *theNumber = [f numberFromString:[[[[i_saveData objectForKey:
        @"hourly_forecast"] objectAtIndex:i] objectForKey:
        @"temp"] objectForKey:@"english"]];
        [theArray addObject:theNumber];
    }
    return theArray;
}

// Takes: start index and length in hourly forecast array
// Returns: array of feelslike as NSNumber's in that range
- (NSMutableArray *)hourlyFeelsNumberArrayF:(int)startIndex length:(int)length {
    if (startIndex + length >= [[i_saveData objectForKey:
        @"hourly_forecast"] count]) {
        NSLog(@"NCWunderground: hourlyTempNumberArrayF requested past hourly_forecast length. Bad.");
        return nil;
    }
    NSMutableArray *theArray = [NSMutableArray array];
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    [f setNumberStyle:NSNumberFormatterDecimalStyle];
    for (int i = startIndex; i < startIndex + length; ++i) {
        NSNumber *theNumber = [f numberFromString:[[[[i_saveData objectForKey:
        @"hourly_forecast"] objectAtIndex:i] objectForKey:
        @"feelslike"] objectForKey:@"english"]];
        [theArray addObject:theNumber];
    }
    return theArray;
}

// Returns: current temp string including °F
- (NSString *)currentTempStringF {
    return [NSString stringWithFormat:@"%@ °F",[[i_saveData objectForKey:
        @"current_observation"] objectForKey:@"temp_f"]];
}

// Returns: current feels string including °F
- (NSString *)currentFeelsStringF {
    return [NSString stringWithFormat:@"%@ °F",[[i_saveData objectForKey:
        @"current_observation"] objectForKey:@"feelslike_f"]];
}

// Returns: current humidity string, including %
- (NSString *)currentHumidityString {
    return [[i_saveData objectForKey:
        @"current_observation"] objectForKey:@"relative_humidity"];
}

// Returns: current wind speed, including mph
- (NSString *)currentWindMPHString {
    return [NSString stringWithFormat:@"%@ mph",[[[i_saveData objectForKey:
        @"current_observation"] objectForKey:@"wind_mph"] stringValue]];
}

// Returns: current location (city, state)
- (NSString *)currentLocationString {
    return [[[i_saveData objectForKey:@"current_observation"]
        objectForKey:@"display_location"] objectForKey:@"full"];
}

// Returns: current conditions icon name
- (NSString *)currentConditionsIconName {
    return [[[[i_saveData objectForKey:@"current_observation"] objectForKey:
        @"icon_url"] lastPathComponent] stringByDeletingPathExtension];
}

// Takes: index into daily forecast array
// Returns: short name of the corresponding day (Mon, Tue, etc)
- (NSString *)dailyDayShortString:(int)forecastIndex {
    return [[[[i_saveData objectForKey:@"forecastday"] objectAtIndex:
        forecastIndex] objectForKey:@"date"] objectForKey:@"weekday_short"];
}

// Takes: index into daily forecast array
// Returns: high temperature for that day, NOT including °F
- (NSString *)dailyHighStringF:(int)forecastIndex {
    return [[[[i_saveData objectForKey:@"forecastday"] objectAtIndex:
        forecastIndex] objectForKey:@"high"] objectForKey:@"fahrenheit"];
}

// Takes: index into daily forecast array
// Returns: low temperature for that day, NOT including °F
- (NSString *)dailyLowStringF:(int)forecastIndex {
    return [[[[i_saveData objectForKey:@"forecastday"] objectAtIndex:
        forecastIndex] objectForKey:@"low"] objectForKey:@"fahrenheit"];
}

// Takes: index into daily forecast array
// Returns: percentage of perciptation for that day, including %
- (NSString *)dailyPOPString:(int)forecastIndex {
    return [NSString stringWithFormat:@"%@%%",[[[[i_saveData objectForKey:@"forecastday"] objectAtIndex:
        forecastIndex] objectForKey:@"low"] stringValue]];
}

// Takes: index into daily forecast array
// Returns: name of icon for weather for that day
- (NSString *)dailyConditionsIconName:(int)forecastIndex {
    return [[[[[i_saveData objectForKey:@"forecastday"] objectAtIndex:
        forecastIndex] objectForKey:@"icon_url"] lastPathComponent] 
            stringByDeletingPathExtension];
}

// Takes: path to the save file
// Returns: YES if it was able to load data, NO otherwise
- (BOOL)loadSaveData:(NSString *)saveFile {
    NSFileManager *fileManager = [NSFileManager defaultManager];

    if ([fileManager fileExistsAtPath:i_saveFile]) {
        NSMutableDictionary *tempDict = [[NSMutableDictionary alloc] initWithContentsOfFile:i_saveFile];
        [i_savedData addEntriesFromDictionary:tempDict];
        [tempDict release];
        if ([i_savedData objectForKey:@"last_request"] == nil) {
            NSLog(@"NCWunderground: save file exists, but appears corrupted.");
            return NO;
        }
        return YES;
    }
    else {
        return NO;
    }
}

// This should only ever run inside the backgroundQueue
- (void) startURLRequest {
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
    NSString *urlString = [NSString stringWithFormat:
        @"http://api.wunderground.com/api/%@/conditions/hourly/forecast10day/q/%@,%@.json",
        apiKey,[i_savedData objectForKey:@"latitude"],
        [i_savedData objectForKey:@"longitude"]];
    [request setURL:[NSURL URLWithString:urlString]];
    [request setHTTPMethod:@"GET"];

    NSData *resultJSON = [NSURLConnection sendSynchronousRequest:
        request returningResponse:&response error:&error];
    [request release];
    if (!resultJSON) {
        NSLog(@"NCWunderground: Unsuccessful connection attempt. Data not updated.");
        // TOOD: Add a red dot somewhere to indicate last update failed?
        return;
    }
    else {
        // TODO: clear the red dot?
    }

    if(NSClassFromString(@"NSJSONSerialization")) {
        NSError *error = nil;
        NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:resultJSON options:0 error:&error];
        if (error) {
            NSLog(@"NCWunderground: JSON was malformed. Bad.");
            return;
        }

        if ([jsonDict objectForKey:@"error"]) {
            NSLog(@"NCWunderground: We got a well-formed JSON, but it's an error: %@ / %@",
                [[jsonDict objectForKey:@"error"] objectForKey:@"type"],
                [[jsonDict objectForKey:@"error"] objectForKey:@"description"]);
            return;
        }

        if ([jsonDict isKindOfClass:[NSDictionary class]]) {
            NSLog(@"NCWunderground: Data download succeeded. Parsing.");
            // update last-request time
            [i_savedData setObject:[NSNumber numberWithInteger:
                [[NSDate date] timeIntervalSince1970]] forKey:@"last_request"];

            // convenience pointers
            NSDictionary *currentObservation = [jsonDict objectForKey:
                @"current_observation"];
            NSDictionary *dailyForecast = [[jsonDict objectForKey:
                @"forecast"] objectForKey:@"simpleforecast"];
            NSDictionary *displayLocation = [currentObservation objectForKey:
                @"display_location"];

            // import current observations, daily forecast, and hourly forecast
            [i_savedData setObject:currentObservation forKey:
                @"current_observation"];
            [i_savedData setObject:[dailyForecast objectForKey:
                @"forecastday"] forKey:@"forecastday"];
            [i_savedData setObject:[jsonDict objectForKey:
                @"hourly_forecast"] forKey:@"hourly_forecast"];

            // Tell the controller that the data has been updated
            dispatch_async(dispatch_get_main_queue(),^(void) {
                [i_controller dataDownloaded];
            });
        }
        else {
            NSLog(@"NCWunderground: JSON was non-dict. Bad.");
            i_loadingData = NO;
            return;
        }
    }
    else {
        NSLog(@"NCWunderground: We don't have NSJSONSerialization. Bad.");
        i_loadingData = NO;
        return;
    }
}

// Does: Takes in updated location and sets it.
//       Then starts the URL request on the background queue.
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    NSLog(@"NCWunderground: didUpdateToLocation: %@", [locations lastObject]);
    if (i_locationUpdated == NO) {
        if (locations != nil) {
            [i_savedData setObject:[NSString stringWithFormat:
                @"%.8f", [[locations lastObject] coordinate].latitude] forKey:
                @"latitude"];
            [i_savedData setObject:[NSString stringWithFormat:
                @"%.8f", [[locations lastObject] coordinate].longitude] forKey:
                @"longitude"];
        
            i_locationUpdated = YES;
            [i_locationManager stopUpdatingLocation];

            // start a URL request in the backgroundQueue
            dispatch_async(backgroundQueue, ^(void) {
                [self startURLRequest];
            });
        }
        else {
            NSLog(@"NCWunderground: didUpdateToLocation called but newLocation nil. Bad.");
        }
    }
}


// save data to disk for later use
//[i_savedData writeToFile:i_saveFile atomically:YES];
//NSLog(@"NCWunderground: data saved to disk at %@",i_saveFile);

@end
