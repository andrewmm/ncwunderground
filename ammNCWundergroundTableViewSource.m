#import "ammNCWundergroundTableViewSource.h"

@implementation ammNCWundergroundTableViewSource

- (id)init {
	if ((self = [super init]) != nil) {
		_contents = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)dealloc {
	[_contents release];
	[super dealloc];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSInteger count = 0;
	if (_contents) {
		count = [_contents count];
	}
	return count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (_contents) {
		static NSString *CellIdentifier = @"Cell";
    	UITableViewCell *cell;
    
    	cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    	if (cell == nil) {
        	cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    	}
    	// Configure the cell... setting the text of our cell's label
    	cell.textLabel.text = [_contents objectAtIndex:indexPath.row];
   		return cell;
	}
	else {
		return nil;
	}
}

- (void)removeAllObjects {
	[_contents removeAllObjects];
}

- (void)addObject:(id)anObject {
	[_contents addObject:anObject];
}

@end
