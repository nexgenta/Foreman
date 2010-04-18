//
//  NGProjectController.h
//  Foreman
//
//  Created by Mo McRoberts on 2010-04-16.
//  Copyright 2010 Nexgenta. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

@interface NGProjectController : NSWindowController {
	IBOutlet NSOutlineView *mFolderTable;
	IBOutlet NSMenuItem *quickLookItem;	
	
	NSMutableArray *rootItems;
	BOOL showBundlesAsFolders;
	BOOL showInvisibles;
	NSPredicate *includeOnlyPredicate;
	NSPredicate *excludePredicate;
}

- (NSArray *) projectRoots;
- (void) setProjectRoots:(NSArray *) roots;

- (IBAction) toggleQuickLookPreview:(id)sender;

@end
