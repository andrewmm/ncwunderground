#import <UIKit/UITableView.h>

@interface ammNCWundergroundTableViewSource: NSObject <UITableViewDataSource> {
	NSMutableArray *_contents;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;

- (void)removeAllObjects;
- (void)addObject:(id)anObject;

@end