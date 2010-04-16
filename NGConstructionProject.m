/*
 * Based upon GCFolderBrowserController by Graham Cox <graham.cox[at]bigpond.com>
 * Copyright 2009 Apptree.net. All rights reserved.
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

#import "NGConstructionProject.h"
#import "GCIconTextFieldCell.h"
#import "NGProjectController.h"
#import "NGFileInfo.h"

@interface NGConstructionProject (Private)

- (void) windowWillClose:(NSNotification *)notification;
- (NSArray *) rootPathsForProjectWithHint:(NSURL *)specified;

@end

@implementation NGConstructionProject

- (id) initWithURL:(NSURL *)url
{
	id plist;
	NGFileInfo *info;
	NSString *projectPlistPath;
	NGProjectController *controller;
	
	if((self = [super init]))
	{
		if(!(controller = [[NGProjectController alloc] init]))
		{
			NSLog(@"Failed to create NGProjectController instance");
			[self dealloc];
			return nil;
		}
		info = [[NGFileInfo alloc] initWithURL:url];
		if([info conformsToType:NGConstructionProjectUTI])
		{
			projectPlistPath = [[[url path] stringByAppendingPathComponent:@"Contents"] stringByAppendingPathComponent:@"Info.plist"];
			if((plist = [NSDictionary dictionaryWithContentsOfFile:projectPlistPath]))
			{
				projectDictionary = [plist mutableCopy];
				projectFile = [url retain];
				url = nil;
			}
		}
		if(!projectDictionary)
		{
			projectDictionary = [[NSMutableDictionary alloc] init];
		}
		[controller setProjectRoots:[self rootPathsForProjectWithHint:url]];
		if(projectFile)
		{
			[controller setProjectURL:projectFile];
		}
		[controller showWindow:self];
	}
	return self;
}

- (void) dealloc
{
	[self setDelegate:nil];
	[projectDictionary release];
	[userDictionary release];
	[projectFile release];
	[super dealloc];
}

- (void) setDelegate:(id) aDel
{
	mDelegateRef = aDel;
}

- (id) delegate
{
	return mDelegateRef;
}

- (void) windowWillClose:(NSNotification *)notification
{
	NSLog(@"[NGConstructionProject windowWillClose]");
	[self dealloc];
}

- (IBAction) saveDocumentAs:(id)sender
{
	NSSavePanel *panel;
	
	panel = [NSSavePanel savePanel];
	[panel setTitle:@"Save Project"];
	[panel setCanCreateDirectories:YES];
	[panel runModal];
}

- (NSArray *) rootPathsForProjectWithHint:(NSURL *)specified
{
	NSArray *rootList;
	NSMutableArray *roots;
	NSEnumerator *e;
	NSString *s;
	NSURL *u;
	
	if(specified)
	{
		
		roots = [NSMutableArray arrayWithObject:[specified absoluteURL]];
		[projectDictionary setObject:roots forKey:@"Roots"];
	}
	else
	{
		rootList = [projectDictionary objectForKey:@"Roots"];
		roots = [NSMutableArray arrayWithCapacity:[rootList count]];
		e = [rootList objectEnumerator];
		while((s = [e nextObject]))
		{
			if(projectFile)
			{
				/* TODO: relative paths in the project file */
				u = [NSURL fileURLWithPath:[[s stringByExpandingTildeInPath] stringByStandardizingPath]];
				[roots addObject:u];
			}
		}
	}
	return roots;
}


/* - (void) selectPath:(NSString*) path
{
	// attempts to select the path. If the path isn't rooted at the current root, does nothing.
	// the outline view is expanded as necessary to display the selected item.
	
	NSString* rootPath = [self rootPath];
	
	// if the path is shorter it can't contain the root...
	
	if ([path length] >= [rootPath length])
	{
		NSRange cr = [path rangeOfString:rootPath];
		
		if( cr.location == 0 && cr.length == [rootPath length])
		{
			// given path is below the current root. Now check it's a directory.
			
			BOOL isDir;
			
			if([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir])
			{
				if( isDir )
				{
					// OK, all checks out, expand the table from the root down until the item can be viewed
					
					if([path isEqualToString:rootPath])
						[mFolderTable selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
					else
					{
						NSString*		ss = [path substringFromIndex:NSMaxRange(cr)];
						NSArray*		parts = [ss componentsSeparatedByString:@"/"];
						NSEnumerator*	iter = [parts objectEnumerator];
						NSString*		part;
						NGFileInfo*	fi = mRootInfo;
						
						while(( part = [iter nextObject]))
						{
							[mFolderTable expandItem:fi];
							
							// look through the subfolders for the folder having the name == part
							
							if([part length] > 0 )
							{
								NSEnumerator*	subIter = [[fi children] objectEnumerator];
								NGFileInfo*	sub;
								BOOL			found = NO;
								
								while(( sub = [subIter nextObject]))
								{
									if([part isEqualToString:[sub name]])
									{
										fi = sub;
										found = YES;
										break;
									}
								}
								
								if( !found )
									return;
							}
						}
						
						int rowIndex = [mFolderTable rowForItem:fi];
						[mFolderTable selectRowIndexes:[NSIndexSet indexSetWithIndex:rowIndex] byExtendingSelection:NO];
						[mFolderTable scrollRowToVisible:rowIndex];
					}
				}
			}
		}
	}
}
 */

@end
