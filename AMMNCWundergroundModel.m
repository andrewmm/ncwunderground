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

@end
