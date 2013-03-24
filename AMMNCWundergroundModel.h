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
            pop (STRING)
            temp
                english (STRING)
    last_request (NUMBER)
    latitude (STRING)
    longitude (STRING)

*/



@interface AMMNCWundergroundModel: NSObject {
    NSMutableDictionary *i_saveData;
}

- (id)init;
- (void)dealloc;

- (double)latitudeDouble;
- (double)longitudeDouble;

- (double)obsLatitudeDouble;
- (double)obsLongitudeDouble;

- (int)lastRequestInt;

- (int)hourlyTime12Hr:(int)forecastIndex;
- (NSString *)hourlyTempStringF:(int)forecastIndex;
- (NSString *)hourlyFeelsStringF:(int)forecastIndex;
- (NSMutableArray *)hourlyTempNumberArrayF:(int)startIndex to:(int)endIndex;
- (NSMutableArray *)hourlyFeelsNumberArrayF:(int)startIndex to:(int)endIndex;

- (NSString *)currentTempStringF;
- (NSString *)currentFeelsStringF;
- (NSString *)currentHumidityString;
- (NSString *)currentWindMPHString;
- (NSString *)currentLocationString;
- (NSString *)currentConditionsIconName;

- (NSString *)dailyDayShortString:(int)forecastIndex;
- (NSString *)dailyHighStringF:(int)forecastIndex; // should not include °F
- (NSString *)dailyLowStringF:(int)forecastIndex; // should not include °F
- (NSString *)dailyPOPString:(int)forecastIndex;
- (NSString *)dailyConditionsIconName:(int)forecastIndex;

- (BOOL)loadSaveData:(NSString *)saveFile;
- (void)downloadData;

@end
