@interface AMMNCWundergroundModel: NSMutableDictionary {
	
}

- (double)latitudeDouble;
- (double)longitudeDouble;

- (double)obsLatitudeDouble;
- (double)obsLongitudeDouble;

- (int)lastRequestInt;

- (BOOL)loadSaveData:(NSString *)saveFile;
- (void)downloadData;