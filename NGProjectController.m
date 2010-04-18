/*
 * Copyright (c) 2010 Mo McRoberts <mo.mcroberts@nexgenta.com>
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. The names of the author(s) of this software may not be used to endorse
 *    or promote products derived from this software without specific prior
 *    written permission.
 *
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, 
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY 
 * AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * AUTHORS OF THIS SOFTWARE BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING 
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Quartz/Quartz.h>

#import "NGProjectController.h"
#import "NGFileTreeItem.h"
#import "GCIconTextFieldCell.h"

@interface NGProjectController (InternalMethods)

- (BOOL) validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)item;
- (NSArray*) sortedChildrenOfItem:(NGFileTreeItem *) fi usingSortDescriptors:(NSArray*) sortDescriptors;
- (void) expandRoots;
- (NSResponder *)nextResponder;

- (IBAction) doubleAction:(id)sender;
- (IBAction) keyDown:(NSEvent *)event;

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
	else if([rootItems count] && [[[rootItems objectAtIndex:0] url] path])
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
	id u, fi;
	
	[rootItems release];
	rootItems = [[NSMutableArray alloc] initWithCapacity:[roots count]];
	e = [roots objectEnumerator];
	while((u = [e nextObject]))
	{
		if((fi = [NGFileTreeItem fileTreeItemWithData:u parent:[self document] matching:nil notMatching:nil includeFiles:YES includeInvisibles:NO bundlesAsFolders:NO]))
		{
			[rootItems addObject:fi];
		}
		else
		{
			NSLog(@"+ filetreeItemWithData failed");
		}
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
	NGFileTreeItem *i;
	
	array = [NSMutableArray arrayWithCapacity:[rootItems count]];
	e = [rootItems objectEnumerator];
	while((i = [e nextObject]))
	{
		[array addObject:[i url]];
	}
	return array;
}

- (NSArray *) rootItems
{
	return rootItems;
}

- (void) expandRoots
{
	NSEnumerator *e;
	NGFileTreeItem *i;
	
	e = [rootItems objectEnumerator];
	while((i = [e nextObject]))
	{
		[mFolderTable expandItem:i];
	}
}

/* Return the children of a given node sorted by a set of descriptors (keys) */
- (NSArray*) sortedChildrenOfItem:(NGFileTreeItem *)fi usingSortDescriptors:(NSArray*)sortDescriptors
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
	NGFileTreeItem* fi = nil;
	
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
	NGFileTreeItem *item;
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
