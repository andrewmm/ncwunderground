@interface AMMNCWundergroundView: UIScrollView {
	int *i_pages; // number of pages in the scroll view
	// TODO: get rid of these two. use the controller's
	float *i_baseWidth; // screen width we design layout around (min)
	float *i_screenWidth; // current screen width
	//
	float *i_viewHeight;
	NSMutableArray *i_backgroundViews; // array of pages
	NSMutableArray *i_subviewContainers; // one for each page
	NSMutableArray *i_spinners; // loading spinner for each page

	// subview dictionary
	// key=pointer to page
	// value=NSMutableArray of subviews for that page
	NSMutableDictionary *i_subviews;
 
	NSMutableArray *i_refreshNeeded;
}

@property (nonatomic, assign) int *pages;
@property (nonatomic, assign) float *screenWidth;
@property (nonatomic, assign) float *viewHeight;
@property (nonatomic, readonly) NSMutableArray *backgroundViews;
@property (nonatomic, readonly) NSMutableDictionary *subviews;


// Takes: number of pages, base width, view height
// Does: initializes (calls setPages)
- (void)initWithPages:(int)n_pages width:(float)width height:(float)height;

// Override pages setter
// Takes: new number of pages
/* Does: sets pages
		 sets up background views, subview containers, and spiners */
- (void)setPages:(int)n_pages;

// Override screenWidth setter
// Takes: new width of screen
/* Does: sets screenWidth
		 calls setPages */
- (void)setScreenWidth:(int)width;

// Takes: BOOL indicating whether we're loading or now
// Does: activates or hides spinners
- (void)loading:(BOOL)status;

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
