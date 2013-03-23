#import "AMMNCWundergroundView.h"

@implementation AMMNCWundergroundView

@synthesize pages=i_pages;
@synthesize screenWidth=i_screenWidth;
@synthesize viewHeight=i_viewHeight;
@synthesize backgroundViews=i_backgroundViews;
@synthesize subviews=i_subviews;

// Takes: number of pages, base width, view height
// Does: initializes
- (id)initWithPages:(int)n_pages width:(float)width height:(float)height {
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

        // set up pages
        [self setPages:n_pages];

        // alloc i_subviews and i_refreshNeeded for later use
        i_subviews = [[NSMutableDictionary alloc] init];
        i_refreshNeeded = [[NSMutableArray alloc] init];
    }
    return self;
}

- (id)init {
    return [self initWithPages:1 width:320 height:71];
}

- (void)dealloc {
    [i_backgroundViews release];
    [i_subviewContainers release];
    [i_spinners release];
    [i_subviews release];
    [i_refreshNeeded release];
    [super dealloc];
}

// Override pages setter
// Takes: new number of pages
/* Does: sets pages
         removes current set of background views, if any
         creates new background views */
- (void)setPages:(int)n_pages {
    i_pages = n_pages;

    // set up background views
    // preserve old ones, if they exist
    NSMutableArray *old_backgroundViews;
    if(i_backgroundViews) {
        old_backgroundViews = i_backgroundViews;
    }
    i_backgroundViews = [[NSMutableArray alloc] init];
    for (int i = 0; i < i_pages; ++i) {
        // set up the background views
        UIImageView *newBackgroundView = [[UIImageView alloc] initWithImage:stretchableBgImg];
        [newBackgroundView setUserInteractionEnabled:YES]; // allow buttons to be pressed
        [i_backgroundViews addObject:newBackgroundView];
        [newBackgroundView setFrame:
            CGRectMake([self screenWidth]*i+2,0,[self screenWidth]-4,[self viewHeight])];
        [newBackgroundView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [self addSubview:newBackgroundView];

        // switch over the subviews
        NSMutableArray *oldSubviewArray = [i_subviews objectForKey:
            [old_backgroundViews objectAtIndex:i]];
        if (oldSubviewArray) {
            [i_subviews setObject:oldSubviewArray forKey:newBackgroundView];
            [i_subviews removeObjectForKey:[old_backgroundViews objectAtIndex:i]];
        }
        else {
            [i_subviews setObject:[NSMutableArray arrayWithCapacity:1]
                forKey:newBackgroundView];
        }

        [newBackgroundView release];
    }

    // set up subview containers
    if (i_subviewContainers) {
        [i_subviewContainers release];
    }
    i_subviewContainers = [[NSMutableArray alloc] init];
    for (int i = 0; i < i_pages; ++i) {
        UIView *newSubviewContainer = [[UIView alloc] init];
        [i_subviewContainers addObject:newSubviewContainer];
        [newSubviewContainer setFrame:
            CGRectMake(0,0,[self screenWidth]-4,[self viewHeight])];
        [[i_backgroundViews objectAtIndex:i] addSubview:newSubviewContainer];

        // add the subviews, if they exist
        NSMutableArray *subviewArray = [i_subviews objectForKey:
            [i_backgroundViews objectAtIndex:i]];
        if (oldSubviewArray) {
            for (UIView *subview in oldSubviewArray) {
                [newSubviewContainer addSubview:subview];
            }
        }
        [newSubviewContainer release];
    }

    // set up spinners
    if (i_spinners) {
        [i_spinners release];
    }
    i_spinners = [[NSMutableArray alloc] init];
    for (int i = 0; i < i_pages; ++i) {
        UIActivityIndicatorView *newSpinner = 
            [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:
                UIActivityIndicatorViewStyleWhiteLarge];
        [i_spinners addObject:newSpinner];
        [newSpinner setCenter:CGPointMake(([self screenWidth]-4)/2,[self viewHeight]/2)];
        [[i_subviewContainers objectAtIndex:i] addSubview:newSpinner];
        [newSpinner release];
    }

    // release the old background views
    if (old_backgroundViews) {
        [old_backgroundViews release];
    }
}

// Override screenWidth setter
// Takes: new width of screen
/* Does: sets screenWidth
         calls setPages */
- (void)setScreenWidth:(int)width {
    i_screenWidth = width;
    [self setPages:i_pages];
}

// Takes: BOOL indicating whether we're loading or now
// Does: activates or hides spinners
- (void)setLoading:(BOOL)status {
    if(status) {
        for(UIActivityIndicatorView *spinner in i_spinners) {
            [spinner startAnimating];
        }
    }
    else {
        for(UIActivityIndicatorView *spinner in i_spinners) {
            [spinner stopAnimating];
        }
    }
}

// Takes: subview to add, page to add it to, (optional: tag, default 0) whether it needs manual refresh
/* Does: retains subview
         adds it to appropriate array in i_subviews
         adds it as a subview to the right subview container
         marks it as refresh needed, if necessary */
// Returns: YES if successful, NO otherwise
- (BOOL)addSubview:(UIView *)subview toPage:(int)page withTag:(int)tag manualRefresh:(BOOL)refresh {
    // lots of error checking
    UIImageView *t_backgroundView = [i_backgroundViews objectAtIndex:page];
    if (!t_backgroundView) {
        return NO;
    }
    NSMutableArray *t_subviewArray = [i_subviews objectForKey:t_backgroundView];
    if (!t_subviewArray) {
        return NO;
    }
    [t_subviewArray addObject:subview];
    UIView *t_subviewContainer = [i_subviewContainers objectAtIndex:page];
    if (!t_subviewContainer) {
        return NO;
    }

    [t_subviewContainer addSubview:subview];
    if(refresh) {
        [i_refreshNeeded addObject:subview];
    }
    [subview setTag:tag];

    return YES;
}
- (BOOL)addSubview:(UIView *)subview toPage:(int)page manualRefresh:(BOOL)refresh {
    return [self addSubview:subview toPage:page withTag:0 manualRefresh:refresh];
}

// Takes: page number, tag number
// Returns: subview
- (UIView *)getSubviewFromPage:(int)page withTag:(int)tag {
    UIView *subviewContainer = [i_subviewContainers objectAtIndex:page];
    if (subviewContainer) {
        subview = [subviewContainer viewWithTag:tag];
        if (subview) {
            return subview;
        }
        else {
            NSLog(@"NCWunderground: subview requested for non-existent tag; returning nil.");
            return nil;
        }
    }
    else {
        NSLog(@"NCWunderground: subview requested for non-existent page; returning nil.");
        return nil;
    }
}

// Does: sets needsDisplay:YES on everything in i_refreshNeeded
- (void)refreshViews {
    for (UIView *view in i_refreshNeeded) {
        [view setNeedsDisplay:YES];
    }
}


