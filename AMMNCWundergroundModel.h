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
