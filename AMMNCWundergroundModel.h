@interface AMMNCWundergroundModel: NSMutableDictionary {
	
}

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
- (NSString *)currentConditionsString;

- (BOOL)loadSaveData:(NSString *)saveFile;
- (void)downloadData;