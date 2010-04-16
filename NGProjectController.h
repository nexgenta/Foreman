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
	IBOutlet NSWindow *controllingPanel;
	IBOutlet NSMenuItem *quickLookItem;	
	
	NSURL *projectURL;
	NSMutableArray *rootItems;
	BOOL showBundlesAsFolders;
	BOOL showInvisibles;
	NSPredicate *includeOnlyPredicate;
	NSPredicate *excludePredicate;
}

- (NSArray *) projectRoots;
- (NSURL *) projectURL;

- (void) setProjectRoots:(NSArray *) roots;
- (void) setProjectURL:(NSURL *) url;

@end
