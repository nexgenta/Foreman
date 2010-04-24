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

#import "FileTypesPrefsController.h"
#import "FileTypeItem.h"

@implementation FileTypesPrefsController

+ (NSArray *) preferencePanes
{
	return [NSArray arrayWithObjects:[[[FileTypesPrefsController alloc] init] autorelease], nil];
}

- (id) init
{
	NSEnumerator *iter;
	id dict, item;
	
	if((self = [super init]))
	{
		builtInTypes = [[[NSBundle bundleForClass:[self class]] objectForInfoDictionaryKey:@"NGBuiltInFileTypes"] retain];
		rootItems = [[NSMutableArray alloc] initWithCapacity:[builtInTypes count]];
		iter = [builtInTypes objectEnumerator];
		while((dict = [iter nextObject]))
		{
			if((item = [FileTypeItem fileTypeItemWithDictionary:dict parent:nil]))
			{
				[rootItems addObject:item];
			}
		}
	}
	return self;
}

- (void) dealloc
{
	[builtInTypes release];
	[rootItems release];
	[super dealloc];
}
		

- (NSView *) paneView
{
	if(prefsView)
	{
		return prefsView;
	}
	if([NSBundle loadNibNamed:@"FileTypesPrefs" owner:self])
	{
		return prefsView;
	}
	return nil;
}


- (NSString *) paneName
{
	return @"File Types";
}


- (NSImage *) paneIcon
{
	return [[[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForImageResource:@"FileTypes"]] autorelease];
}


- (NSString *) paneToolTip
{
	return @"File Types";
}


- (BOOL) allowsHorizontalResizing
{
	return YES;
}


- (BOOL) allowsVerticalResizing
{
	return YES;
}

- (BOOL) outlineView:(NSOutlineView *)outlineView isItemExpandable:(id) item
{
	(void)outlineView;
	
	if(nil == item)
	{
		return YES;
	}
	else
	{
		return [item numberOfChildren] > 0;
	}
}

- (NSInteger) outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id) item
{
	(void) outlineView;
	
	if(nil == item)
	{
		return [rootItems count];
	}
	else
	{
		return [item numberOfChildren];
	}
}

- (id) outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn*) tableColumn byItem:(id) item
{
	(void) outlineView;
	
	if(nil == item)
	{
		return [[rootItems objectAtIndex:0] valueForKey:[tableColumn identifier]];
	}
	return [item valueForKey:[tableColumn identifier]];
}

- (id) outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	if(nil == item)
	{
		return [rootItems objectAtIndex:index];
	}
	return [[item children] objectAtIndex:index];
}


@end
