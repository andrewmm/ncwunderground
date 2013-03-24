#import "AMMNCWundergroundModel.h"

@implementation AMMNCWundergroundModel

- (id)init {
    i_saveData = [[NSMutableDictionary alloc] init];

    [super init];
}

- (void)dealloc {
    [i_saveData release];
    i_saveData = nil;
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

- (int)hourlyTime12Hr:(int)forecastIndex {
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    [f setNumberStyle:NSNumberFormatterDecimalStyle];
    int hour = [[f numberFromString:[[[[i_saveData objectForKey:
        @"hourly_forecast"] objectAtIndex:forecastIndex] objectForKey:
        @"FCTTIME"] objectForKey:@"hour"]] intValue];
    // TODO: not finished
}

@end
