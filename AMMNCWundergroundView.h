@interface AMMNCWundergroundView: UIScrollView

@property (nonatomic, assign) int pages;
@property (nonatomic, readonly, assign) float baseWidth;
@property (nonatomic, assign) float screenWidth;
@property (nonatomic, assign) float viewHeight;
@property (nonatomic, readonly, copy) NSArray *backgroundViews;
@property (nonatomic, readonly, copy) NSArray *subviewContainers;
@property (nonatomic, readonly, copy) NSArray *spinners;
@property (nonatomic, readonly, copy) NSArray *refreshNeeded;

- (void)setLogLevel:(int)level;


// Takes: number of pages, base width, view height
// Does: initializes (calls setPages)
- (id)initWithPages:(int)n_pages atPage:(int)cur_page width:(float)width height:(float)height;

// Override pages setter
// Takes: new number of pages
/* Does: sets pages
		 sets up background views, subview containers, and spiners */
- (void)setPages:(int)n_pages;

// Override screenWidth setter
// Takes: new width of screen
/* Does: sets screenWidth
		 calls setPages */
- (void)setScreenWidth:(float)width;
- (void)setScreenWidth:(float)width withCurrentPage:(int)cur_page;

// Takes: BOOL indicating whether we're loading or now
// Does: activates or hides spinners
- (void)setLoading:(BOOL)status;

// Takes: subview to add, page to add it to, (optional: tag, default 0) whether it needs manual refresh
/* Does: retains subview
		 adds it to appropriate array in i_subviews
		 adds it as a subview to the right subview container
		 marks it as refresh needed, if necessary */
// Returns: YES if successful, NO otherwise
- (BOOL)addSubview:(UIView *)subview toPage:(int)page withTag:(int)tag manualRefresh:(BOOL)refresh;
- (BOOL)addSubview:(UIView *)subview toPage:(int)page manualRefresh:(BOOL)refresh;

// Takes: page number, tag number
// Returns: subview
- (UIView *)getSubviewFromPage:(int)page withTag:(int)tag;

// Does: sets needsDisplay:YES on everything in i_refreshNeeded
- (void)refreshViews;

@end
