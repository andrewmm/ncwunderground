/*
The i_saveData object must have the following structure. This should be inforced by downloadData. Other fields are permitted.

root
    current_observation
        display_location
            full (STRING)
            latitude (STRING)
            longitude (STRING)
        feelslike_f (STRING)
        forecast_url (STRING)
        icon_url (STRING)
        observation_location
            latitude (STRING)
            longitude (STRING)
        relative_humidity (STRING)
        temp_f (NUMBER)
        weather (STRING)
        wind_mph (NUMBER)
    forecastday (ARRAY)
        (for each)
            date
                weekday_short (STRING)
            high
                fahrenheit (STRING)
            icon_url (STRING)
            low
                fahrenheit (STRING)
            pop (NUMBER)
    hourly_forecast (ARRAY)
        (for each)
            FCTTIME
                ampm (STRING)
                hour (STRING)
            feelslike
                english (STRING)
                metric (STRING)
            pop (STRING)
            temp
                english (STRING)
                metric (STRING)
    last_request (NUMBER)
    latitude (STRING)
    longitude (STRING)

*/

#import <CoreLocation/CoreLocation.h>

#ifndef _AMMTypeDefs_
#define _AMMTypeDefs_
#define AMMTempTypeF 0
#define AMMTempTypeC 1
#define AMMDistTypeM 0
#define AMMDistTypeK 1
#define AMMWindTypeM 0
#define AMMWindTypeK 1
#define AMMWindTypeKt 2
#endif

@class AMMNCWundergroundController;

@interface AMMNCWundergroundModel: NSObject <CLLocationManagerDelegate>

@property (nonatomic, copy) NSDictionary *saveData;
@property (nonatomic, strong) dispatch_queue_t backgroundQueue;
@property (nonatomic, weak) AMMNCWundergroundController *controller;
@property (nonatomic, weak) NSBundle *ammNCWundergroundWeeAppBundle;

- (id)initWithController:(AMMNCWundergroundController *)controller;

// Returns: current latitude/longitude as a double
- (double)latitudeDouble;
- (double)longitudeDouble;

// Returns: observation latitude/longitude as a double
- (double)obsLatitudeDouble;
- (double)obsLongitudeDouble;

// Returns: last request date (seconds since 1970) as an int
- (int)lastRequestInt;

// Take: indices into hourly forecast arrays
// Return: formatted information from those arrays 
- (NSString *)hourlyTime12HrString:(int)forecastIndex;
- (NSString *)hourlyTempString:(int)forecastIndex ofType:(int)type;
- (NSString *)hourlyFeelsString:(int)forecastIndex ofType:(int)type;
- (NSMutableArray *)hourlyTempNumberArray:(int)startIndex length:(int)length ofType:(int)type;
- (NSMutableArray *)hourlyFeelsNumberArray:(int)startIndex length:(int)length ofType:(int)type;

// Return: formatted information about current conditions
- (NSString *)currentTempStringOfType:(int)type;
- (NSString *)currentFeelsStringOfType:(int)type;
- (NSString *)currentHumidityString;
- (NSString *)currentWindStringOfType:(int)type;
- (NSString *)currentLocationString;
- (NSString *)currentConditionsIconName;
- (NSString *)currentConditionsString;
- (NSString *)currentConditionsURL;

- (NSString *)dailyDayShortString:(int)forecastIndex; // TODO localize
- (NSString *)dailyHighString:(int)forecastIndex ofType:(int)type; // should not include type specifier
- (NSString *)dailyLowString:(int)forecastIndex ofType:(int)type; // should not include type specifier
- (NSString *)dailyPOPString:(int)forecastIndex; // includes %
- (NSString *)dailyConditionsIconName:(int)forecastIndex;

- (BOOL)loadSaveData:(NSString *)saveFile inDirectory:(NSString *)saveDirectory;
- (void)saveDataToFile:(NSString *)saveFile inDirectory:(NSString *)saveDirectory;
- (void)startURLRequestWithQuery:(NSString *)query;
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations;

@end
