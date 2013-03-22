#import "AMMNCWundergroundController-new.h"

@implementation AMMNCWundergroundController

@synthesize saveFile=i_saveFile;
@synthesize locationUpdated=i_locationUpdated;
@synthesize loadingData=i_loadingData;
@synthesize baseWidth=i_baseWidth;
@synthesize currentWidth=i_currentWidth;
@synthesize viewHeight=i_viewHeight;

+ (void)initialize {
    _ammNCWundergroundWeeAppBundle = [[NSBundle bundleForClass:[self class]] retain];
}

- (id)init {
    if ((self = [super init]) != nil) {
        i_viewHeight = 71;
        i_baseWidth = [UIScreen mainScreen].bounds.size.width;
        i_currentWidth = i_baseWidth;

        i_view = [[AMMNCWundergroundView alloc] initWithPages:4
            width:currentWidth height:i_viewHeight];
        i_model = [[AMMNCWundergroundModel alloc] init];

        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                             NSUserDomainMask, YES);
        i_saveFile = [[NSString alloc] initWithString:
            [[paths objectAtIndex:0] stringByAppendingString:
                @"/com.amm.ncwunderground.save.plist"]];

        i_locationManager = [[CLLocationManager alloc] init];
        i_locationUpdated = NO;

        i_loadingData = NO;

        i_iconMap = [[NSDictionary alloc] initWithContentsOfFile:
            [_ammNCWundergroundWeeAppBundle pathForResource:
                @"icons/com.amm.ncwunderground.iconmap" ofType:@"plist"]];
    }
    return self;
}

/* Does: adds all the specific subviews to i_view
         hooks subview values up to i_model */
- (void)addSubviewsToView {
    // -- details page -- //

    // labels
    for (int i=0; i < 3; ++i) {
        UILabel *newLabel = [[UILabel alloc] init];
        [newLabel setBackgroundColor:[UIColor clearColor]];
        [newLabel setTextColor:[UIColor whiteColor]];
        [newLabel setFont:[UIFont systemFontOfSize:14]];
        [newLabel setTextAlignment:NSTextAlignmentCenter];
        [newLabel setFrame:CGRectMake(0.2*[self baseWidth],5+23*i,
            0.6*[self baseWidth],15)]
        [i_view addSubview:newLabel toPage:0 withTag:i manualRefresh:NO];
        [newLabel release];
    }

    // refresh button
    UIButton *refreshButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *refreshImage = [UIImage imageWithContentsOfFile:
        [_ammNCWundergroundWeeAppBundle pathForResource:
                @"refresh" ofType:@"png"]];
    [refreshButton setBackgroundImage:refreshImage forState:UIControlStateNormal];
    [refreshButton addTarget:self action:@selector(loadData:) 
        forControlEvents:UIControlEventTouchUpInside];
    [refreshButton setFrame:CGRectMake(0.85*[self baseWidth],
        ([self viewHeight] - 0.1*[self baseWidth])/2,
        0.1*[self baseWidth],0.1*[self baseWidth])]
    [i_view addSubview:refreshButton toPage:0 withTag:3 manualRefresh:NO];
    // don't need to release refresh button

    // -- hourly forecast / sparklines page -- //

    // useful formatting constants
    float labelWidth = 0.14 * [self baseWidth];
    float colBuffer = 0.00625 * [self baseWidth];
    float sparkWidth = [self baseWidth] - labelWidth * 5 - colBuffer * 7;
    float rowHeight = 15;
    float rowFirstBuffer = 5;
    float rowBuffer = 8;

    for (int i=0; i < 3; ++i) { // rows
        float y = rowFirstBuffer + i * (rowHeight + rowBuffer);
        for (int j=0; j < 5; ++j) { // columns
            // create tag of form 1(i+1)(j+1)
            int tag = 100 + (i+1)*10 + (j+1);

            UILabel *newLabel = [[UILabel alloc] init];
            [newLabel setBackgroundColor:[UIColor clearColor]];
            [newLabel setTextColor:[UIColor whiteColor]];
            [newLabel setFont:[UIFont systemFontOfSize:14]];
            [newLabel setTextAlignment:NSTextAlignmentCenter];

            // calculate locations
            float x = colBuffer + (colBuffer + labelWidth) * j;
            if (j > 1)
                x += colBuffer + sparkWidth;
            [newLabel setFrame:CGRectMake(x,y,labelWidth,rowHeight)];

            [i_view addSubview:newLabel toPage:1 withTag:tag manualRefresh:NO];
            [newLabel release];
        }

        //sparkviews
        if (i > 0) {
            ASBSparkLineView *sparkView = [[ASBSparkLineView alloc] init];
            [sparkView setPenColor:[UIColor whiteColor]];
            [sparkView setBackgroundColor:[UIColor clearColor]];
            [sparkView setShowCurrentValue:NO];

            float x = colBuffer * 3 + labelWidth * 2;
            [sparkView setFrame:CGRectMake(x,y,sparkWidth,rowHeight)];

            [i_view addSubview:sparkView toPage:1 withTag:(100 + (i+1)*10)
                manualRefresh:YES];
            [sparkView release];
        }
        
    }

    // -- current conditions page -- //

    for (int i=0; i < 3; ++i) { // 
        // hrm
    }
}


