#import "AMMNCWundergroundView.h"

@interface AMMNCWundergroundView ()

@property (nonatomic, assign) float baseWidth;
@property (nonatomic, copy) NSArray *backgroundViews;
@property (nonatomic, copy) NSArray *subviewContainers;
@property (nonatomic, copy) NSArray *spinners;
@property (nonatomic, copy) NSArray *refreshNeeded;

@end

@implementation AMMNCWundergroundView

@synthesize pages=i_pages;
@synthesize baseWidth=i_baseWidth;
@synthesize screenWidth=i_screenWidth;
@synthesize viewHeight=i_viewHeight;
@synthesize backgroundViews=i_backgroundViews;
@synthesize subviewContainers=i_subviewContainers;
@synthesize spinners=i_spinners;
@synthesize refreshNeeded=i_refreshNeeded;

// Takes: number of pages, base width, view height
// Does: initializes
- (id)initWithPages:(int)n_pages atPage:(int)cur_page width:(float)width height:(float)height {
    CGRect frameRect = (CGRect){CGPointZero, {width, height}};
    if((self = [super initWithFrame:frameRect]) != nil) {
        i_pages = n_pages;
        i_baseWidth = width;
        i_screenWidth = width;
        i_viewHeight = height;

        // set up visual effects of top view
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.contentSize = CGSizeMake(n_pages * width,height);
        self.contentOffset = CGPointMake(cur_page * width,0);
        self.pagingEnabled = YES;
        self.showsHorizontalScrollIndicator = NO;

        // set up pages
        [self setPages:n_pages];
    }
    return self;
}

- (id)init {
    return [self initWithPages:1 atPage:0 width:320 height:71];
}

// Override pages setter
// Takes: new number of pages
/* Does: sets pages
         removes current set of background views, if any
         creates new background views */
- (void)setPages:(int)n_pages {
    i_pages = n_pages;

    // remove old background views from self
    [[self subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];


    // images for background views
    UIImage *bgImg = [UIImage imageWithContentsOfFile:@"/System/Library/WeeAppPlugins/StocksWeeApp.bundle/WeeAppBackground.png"];
    UIImage *stretchableBgImg = [bgImg stretchableImageWithLeftCapWidth:floorf(bgImg.size.width / 2)
                                                           topCapHeight:floorf(bgImg.size.height / 2)];

    // set up background views
    // preserve old ones, if they exist
    NSMutableArray *workingArray = [[NSMutableArray alloc] init];
    for (int i = 0; i < self.pages; ++i) {
        // set up the background views
        UIImageView *newBackgroundView = [[UIImageView alloc] initWithImage:stretchableBgImg];
        [newBackgroundView setUserInteractionEnabled:YES]; // allow buttons to be pressed
        [workingArray addObject:newBackgroundView];
        [newBackgroundView setFrame:CGRectMake([self screenWidth]*i+2,0,[self screenWidth]-4,[self viewHeight])];
        [newBackgroundView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [self addSubview:newBackgroundView];
    }
    self.backgroundViews = workingArray;

    // set up subview containers
    // preserve old ones
    NSArray *old_subviewContainers;
    if (self.subviewContainers) {
        old_subviewContainers = self.subviewContainers;
    }
    workingArray = [[NSMutableArray alloc] init];
    for (int i = 0; i < self.pages; ++i) {
        UIView *newSubviewContainer = [[UIView alloc] init];
        [workingArray addObject:newSubviewContainer];
        [newSubviewContainer setFrame:CGRectMake((self.screenWidth - self.baseWidth) / 2,0,self.baseWidth-4,self.viewHeight)];
        [[self.backgroundViews objectAtIndex:i] addSubview:newSubviewContainer];

        // add the subviews, if they exist
        if (old_subviewContainers) {
            for (UIView *subview in [[old_subviewContainers objectAtIndex:i] subviews]) {
                [newSubviewContainer addSubview:subview];
            }
        }
    }
    self.subviewContainers = workingArray;

    // set up spinners
    workingArray = [[NSMutableArray alloc] init];
    for (int i = 0; i < self.pages; ++i) {
        UIActivityIndicatorView *newSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [workingArray addObject:newSpinner];
        [newSpinner setCenter:CGPointMake(([self screenWidth]-4)/2,[self viewHeight]/2)];
        [[self.subviewContainers objectAtIndex:i] addSubview:newSpinner];
    }
    self.spinners = workingArray;
}

// Override screenWidth setter
// Takes: new width of screen
/* Does: sets screenWidth
         calls setPages */
- (void)setScreenWidth:(float)width {
    i_screenWidth = width;
    self.contentSize = CGSizeMake(self.pages * width,self.viewHeight);
    [self setPages:self.pages];
}

- (void)setScreenWidth:(float)width withCurrentPage:(int)cur_page {
    self.screenWidth = width;
    self.contentOffset = CGPointMake(cur_page * width,0);
}

// Takes: BOOL indicating whether we're loading or now
// Does: activates or hides spinners
- (void)setLoading:(BOOL)status {
    if(status) {
        NSLog(@"NCWunderground: starting loading indicators");
        for(int i = 0; i < self.pages; ++i) {
            UIActivityIndicatorView *spinner = [self.spinners objectAtIndex:i];
            [[self.subviewContainers objectAtIndex:i] bringSubviewToFront:spinner];
            [spinner startAnimating];
        }
    }
    else {
        NSLog(@"NCWunderground: stopping loading indicators");
        for(UIActivityIndicatorView *spinner in self.spinners) {
            [spinner stopAnimating];
        }
    }
}

// Takes: subview to add, page to add it to, (optional: tag, default 0) whether it needs manual refresh
/* Does: adds subview to appropriate array in self.subviews
         adds it as a subview to the right subview container
         marks it as refresh needed, if necessary */
// Returns: YES if successful, NO otherwise
- (BOOL)addSubview:(UIView *)subview toPage:(int)page withTag:(int)tag manualRefresh:(BOOL)refresh {
    // lots of error checking
    UIImageView *t_backgroundView = [self.backgroundViews objectAtIndex:page];
    if (!t_backgroundView) {
        return NO;
    }
    UIView *t_subviewContainer = [self.subviewContainers objectAtIndex:page];
    if (!t_subviewContainer) {
        return NO;
    }

    [t_subviewContainer addSubview:subview];
    if(refresh) {
        NSMutableArray *workingArray = [NSMutableArray arrayWithArray:self.refreshNeeded];
        [workingArray addObject:subview];
        self.refreshNeeded = workingArray;
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

    UIView *subviewContainer = [self.subviewContainers objectAtIndex:page];
    if (subviewContainer) {
        UIView *subview = [subviewContainer viewWithTag:tag];
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

// Does: sets needsDisplay:YES on everything in self.refreshNeeded
- (void)refreshViews {
    for (UIView *view in self.refreshNeeded) {
        [view setNeedsDisplay];
    }
}

@end

