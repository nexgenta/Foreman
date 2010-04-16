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

#import "NGQLOutlineView.h"

@interface NGQLOutlineView (InternalMethods)

- (void) handleSelectionChanged;
- (void) tableViewSelectionDidChange:(NSNotification *)notification;

@end

@implementation NGQLOutlineView

- (id)initWithCoder:(NSCoder *)decoder
{
	if((self = [super initWithCoder:decoder]))
	{
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tableViewSelectionDidChange:) name:NSOutlineViewSelectionDidChangeNotification object:self];
	}
	return self;
}

- (id) initWithFrame:(NSRect)frameRect
{
	if((self = [super initWithFrame:frameRect]))
	{
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tableViewSelectionDidChange:) name:NSOutlineViewSelectionDidChangeNotification object:self];
	}
	return self;
}
	
- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[selectedItems release];
	[super dealloc];
}

- (void) handleSelectionChanged;
{
	NSMutableArray *array;
	NSIndexSet *indexes;
	
	[selectedItems release];
	array = [NSMutableArray arrayWithCapacity:[self numberOfSelectedRows]];
	indexes = [self selectedRowIndexes];
	[indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
		[array addObject:[self itemAtRow:idx]];
	}];
	selectedItems = [array retain];
	if(previewPanel)
	{
		[previewPanel reloadData];
	}
}

- (void) tableViewSelectionDidChange:(NSNotification *)notification
{
	(void) notification;
	
	[self handleSelectionChanged];
}

- (void) keyDown:(NSEvent *)event
{
    if([@" " isEqual:[event charactersIgnoringModifiers]])
	{
		[[NSApplication sharedApplication] sendAction:@selector(toggleQuickLookPreview:) to:nil from:self];
    }
	else
	{
		[super keyDown:event];
    }
}

/* QLPreviewPanelController methods */

- (BOOL) acceptsPreviewPanelControl:(QLPreviewPanel *) panel;
{
    return YES;
}

- (void) beginPreviewPanelControl:(QLPreviewPanel *) panel
{
    previewPanel = [panel retain];
    [panel setDelegate:self];
    [panel setDataSource:self];
	[panel setFloatingPanel:YES];
	[panel setBecomesKeyOnlyIfNeeded:YES];
}

- (void) endPreviewPanelControl:(QLPreviewPanel *) panel
{
    [previewPanel release];
    previewPanel = nil;
}

/* QLPreviewPanelDataSource methods */

- (NSInteger) numberOfPreviewItemsInPreviewPanel:(QLPreviewPanel *) panel
{
	(void) panel;

	if(!selectedItems)
	{
		return 0;
	}
	return [selectedItems count];
}

- (id <QLPreviewItem>) previewPanel:(QLPreviewPanel *)panel previewItemAtIndex:(NSInteger)index
{
	(void) panel;
	
	if(!selectedItems)
	{
		return nil;
	}
	return [selectedItems objectAtIndex:index];
}

/* QLPreviewPanelDelegate methods */

- (BOOL) previewPanel:(QLPreviewPanel *)panel handleEvent:(NSEvent *)event
{
	(void) panel;
	
    if(NSKeyDown == [event type])
	{
        [self keyDown:event];
        return YES;
    }
    return NO;
}

@end
