#import "AMMNCWundergroundView.h"

@implementation AMMNCWundergroundView

@synthesize pages=i_pages;
@synthesize screenWidth=i_screenWidth;
@synthesize viewHeight=i_viewHeight;
@synthesize backgroundViews=i_backgroundViews;
@synthesize subviews=i_subviews;

- (void)initWithPages:(int)n_pages width:(float)width height:(float)height {
	CGRect frameRect = (CGRect){CGPointZero, {width, height}};
	if((self = [super initWithFrame:frameRect]) != nil) {
		i_pages = n_pages;
		i_baseWidth = width;
		i_screenWidth = width;
		i_viewHeight = height;

		// set up visual effects of top view
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		self.contentSize = CGSizeMake(n_pages * screenWidth,height);
		self.contentOffset = CGPointMake(0,0); // TODO make this come from NSUserDefaults
		self.pagingEnabled = YES;
		self.showsHorizontalScrollIndicator = NO;

		// images for background views
		UIImage *bgImg = [UIImage imageWithContentsOfFile:
			@"/System/Library/WeeAppPlugins/StocksWeeApp.bundle/WeeAppBackground.png"];
		UIImage *stretchableBgImg = [bgImg stretchableImageWithLeftCapWidth:
			floorf(bgImg.size.width / 2) topCapHeight:
			floorf(bgImg.size.height / 2)];

		// set up background views
		i_backgroundViews = [[NSMutableArray alloc] init];
		for (int i = 0; i < n_pages; ++i) {
			UIImageView *newBackgroundView = [[UIImageView alloc] initWithImage:stretchableBgImg];
        	[newBackgroundView setUserInteractionEnabled:YES]; // allow buttons to be pressed
        	[i_backgroundViews addObject:newBackgroundView];
        	[newBackgroundView setFrame:
            	CGRectMake(width*i+2,0,width-4,height)];
        	[newBackgroundView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        	[self addSubview:newBackgroundView];
        	[newBackgroundView release];
		}

		// set up subview containers
		i_subviewContainers = [[NSMutableArray alloc] init];
		for (int i = 0; i < n_pages; ++i) {
			UIView *newSubviewContainer = [[UIView alloc] init];
			[i_subviewContainers addObject:newSubviewContainer];
			[newSubviewContainer setFrame:
				CGRectMake(0,0,width-4,height)];
			[[i_backgroundViews objectAtIndex:i] addSubview:newSubviewContainer];
			[newSubviewContainer release];
		}

		// set up spinners
		i_spinners = [[NSMutableArray alloc] init];
		for (int i = 0; i < n_pages; ++i) {
			UIActivityIndicatorView *newSpinner = 
				[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:
            		UIActivityIndicatorViewStyleWhiteLarge];
			[i_spinners addObject:newSpinner];
			[newSpinner setCenter:CGPointMake((width-4)/2,height/2)];
			[newSpinner setHidden:YES];
			[[i_subviewContainers objectAtIndex:i] addSubview:newSpinner];
			[newSpinner release];
		}

		// alloc i_subviews and i_refreshNeeded for later use
		i_subviews = [[NSMutableDictionary alloc] init];
		i_refreshNeeded = [[NSMutableArray alloc] init];
	}
}