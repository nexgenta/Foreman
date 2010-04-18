//
//  NGProjectController.m
//  Foreman
//
//  Created by Mo McRoberts on 2010-04-16.
//  Copyright 2010 Nexgenta. All rights reserved.
//

#import <Quartz/Quartz.h>

#import "NGProjectController.h"
#import "NGFileInfo.h"
#import "GCIconTextFieldCell.h"

@interface NGProjectController (InternalMethods)

- (BOOL) validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)item;
- (NSArray*) sortedChildrenOfItem:(NGFileInfo*) fi usingSortDescriptors:(NSArray*) sortDescriptors;
- (void) expandRoots;
- (NSResponder *)nextResponder;

- (IBAction) doubleAction:(id)sender;
- (IBAction) keyDown:(NSEvent *)event;
- (IBAction) toggleQuickLookPreview:(id)sender;

@end

@implementation NGProjectController

- (id) initWithWindow:(NSWindow *) window
{
	if((self = [super initWithWindow:window]))
	{
		rootItems = [[NSMutableArray alloc] init];		
	}
	return self;
}

- (void) dealloc
{
	[mFolderTable setDataSource:nil];
	[mFolderTable setDelegate:nil];
	[rootItems release];
	[super dealloc];
}

- (void) awakeFromNib
{
	NSTableColumn* col;
	
	[super awakeFromNib];
	col = [mFolderTable tableColumnWithIdentifier:@"name"];
	[mFolderTable setSortDescriptors:[NSArray arrayWithObject:[col sortDescriptorPrototype]]];
	[mFolderTable setTarget:self];
	[mFolderTable setDoubleAction:@selector(doubleAction:)];
	if([self document])
	{
		[[self document] windowControllerDidLoadNib:self];
	}
}

- (void) windowDidLoad
{
	[super windowDidLoad];
	[[self window] setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
	[self synchronizeWindowTitleWithDocumentName];
	[self expandRoots];
}

- (void) showWindow:(id) sender
{
	[[self window] makeKeyAndOrderFront:sender];
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)item
{
	NSMenuItem *menuItem;
	
	menuItem = [(id)item isKindOfClass:[NSMenuItem class]] ? (NSMenuItem *) item : nil;
	if([item action] == @selector(quickLookItem:) || [item action] == @selector(toggleQuickLookPreview:))
	{
		if ([QLPreviewPanel sharedPreviewPanelExists] && [[QLPreviewPanel sharedPreviewPanel] isVisible])
		{
			/* XXX i18n */
			[menuItem setTitle:@"Hide Quick Look"];
			return YES;
		}
		/* XXX i18n */
		[menuItem setTitle:@"Quick Look"];
		if([mFolderTable selectedRow] == -1)
		{
			return NO;
		}
	}
	return YES;
}

- (void)synchronizeWindowTitleWithDocumentName
{
	if([[self document] fileURL])
	{
		[[self window] setTitleWithRepresentedFilename:[[[self document] fileURL] path]];
	}
	else if([rootItems count])
	{
		[[self window] setTitleWithRepresentedFilename:[[[rootItems objectAtIndex:0] url] path]];
	}
	else
	{
		[super synchronizeWindowTitleWithDocumentName];
	}
}

- (IBAction) doubleAction:(id)sender
{
	id selected;
	
	selected = [mFolderTable itemAtRow:[mFolderTable selectedRow]];
	[[NSApplication sharedApplication] sendAction:@selector(launchItem:) to:nil from:selected];
}

- (void) setProjectRoots:(NSArray *)roots
{
	NSEnumerator *e;
	NSURL *u;
	
	[rootItems release];
	rootItems = [[NSMutableArray alloc] initWithCapacity:[roots count]];
	e = [roots objectEnumerator];
	while((u = [e nextObject]))
	{
		[rootItems addObject:[[NGFileInfo alloc] initWithURL:u]];
	}
	if([self isWindowLoaded])
	{
		[mFolderTable reloadData];
		[mFolderTable selectRowIndexes:[NSIndexSet indexSetWithIndex:-1] byExtendingSelection:NO];
		[self expandRoots];
		[self synchronizeWindowTitleWithDocumentName];
	}
}

- (NSArray *) projectRoots
{
	NSMutableArray *array;
	NSEnumerator *e;
	NGFileInfo *i;
	
	array = [NSMutableArray arrayWithCapacity:[rootItems count]];
	e = [rootItems objectEnumerator];
	while((i = [e nextObject]))
	{
		[array addObject:[i url]];
	}
	return array;
}

- (void) expandRoots
{
	NSEnumerator *e;
	NGFileInfo *i;
	
	e = [rootItems objectEnumerator];
	while((i = [e nextObject]))
	{
		[mFolderTable expandItem:i];
	}
}

/* Return the children of a given node sorted by a set of descriptors (keys) */
- (NSArray*) sortedChildrenOfItem:(NGFileInfo*)fi usingSortDescriptors:(NSArray*)sortDescriptors
{
	NSMutableArray *children;
	
	children = [[fi children] mutableCopy];
	[children sortUsingDescriptors:sortDescriptors];
	return [children autorelease];
}

- (id) outlineView:(NSOutlineView*) outlineView child:(NSInteger) idx ofItem:(id) item
{
	NSArray *items;
	
	(void) outlineView;
	
	if( item == nil )
	{
		return [rootItems objectAtIndex:idx];
	}
	items = [self sortedChildrenOfItem:item usingSortDescriptors:[mFolderTable sortDescriptors]];
	return [items objectAtIndex:idx];
}

- (BOOL) outlineView:(NSOutlineView*) outlineView isItemExpandable:(id) item
{
	(void)outlineView;
	
	if(nil == item)
	{
		return YES;
	}
	else
	{
		return [item valence] > 0;
	}
}

- (NSInteger) outlineView:(NSOutlineView*) outlineView numberOfChildrenOfItem:(id) item
{
	(void) outlineView;
	
	if(nil == item)
	{
		return [rootItems count];
	}
	else
	{
		return [item valence];
	}
}

- (id) outlineView:(NSOutlineView*) outlineView objectValueForTableColumn:(NSTableColumn*) tableColumn byItem:(id) item
{
	(void) outlineView;
	
	if(nil == item)
	{
		return [[rootItems objectAtIndex:0] valueForKey:[tableColumn identifier]];
	}
	return [item valueForKey:[tableColumn identifier]];
}

- (void) outlineView:(NSOutlineView*) outlineView sortDescriptorsDidChange:(NSArray*) oldDescriptors
{
		// maintain the selection
	
	int rowIndex = [outlineView selectedRow];
	NGFileInfo* fi = nil;
	
	if( rowIndex != -1 )
		fi = [outlineView itemAtRow:rowIndex];
	
	[outlineView reloadData];
	
	if( fi )
	{
		rowIndex = [outlineView rowForItem:fi];
		[outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:rowIndex] byExtendingSelection:NO];
		[outlineView scrollRowToVisible:rowIndex];
	}
}


- (void) outlineViewSelectionDidChange:(NSNotification*) notification
{
	NGFileInfo *item;
	int rowIndex;
	
	(void) notification;
	
	if(-1 == (rowIndex = [mFolderTable selectedRow]))
	{
		item = nil;
	}
	else
	{
		item = [mFolderTable itemAtRow:rowIndex];
	}
	[[NSApplication sharedApplication] sendAction:@selector(didSelectProjectItem:) to:nil from:item];
}

- (void) outlineView:(NSOutlineView*) olv willDisplayCell:(NSCell*) cell forTableColumn:(NSTableColumn*) tableColumn item:(id) item
{    
    (void) olv;
	if ([[tableColumn identifier] isEqualToString:@"name"] && [cell respondsToSelector:@selector(setTextFieldIcon:)])
		[(GCIconTextFieldCell*) cell setTextFieldIcon:[item icon]];
}

/* Quick Look preview panel support */

- (IBAction) quickLookItem:(id)sender
{
	[self toggleQuickLookPreview:sender];
}

- (IBAction) toggleQuickLookPreview:(id)sender
{
    if([QLPreviewPanel sharedPreviewPanelExists] && [[QLPreviewPanel sharedPreviewPanel] isVisible])
	{
        [[QLPreviewPanel sharedPreviewPanel] orderOut:nil];
    }
	else
	{
        [[QLPreviewPanel sharedPreviewPanel] makeKeyAndOrderFront:nil];
    }
}

@end
