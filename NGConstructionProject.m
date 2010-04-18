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
#import "NGFileTreeItem.h"

@interface NGConstructionProject (Private)

- (NSArray *) projectRoots;
- (NSArray *) rootItems;

- (void)windowDidMoveResize:(NSNotification *)notification;
- (void)shouldSaveSoon:(id)sender;

@end

@implementation NGConstructionProject

- (NSString *) windowNibName
{
	return @"ProjectWindow";
}

- (void) makeWindowControllers
{
	[self addWindowController:[[NGProjectController alloc] initWithWindowNibName:[self windowNibName]]];
}

- (void) windowControllerDidLoadNib:(NSWindowController *) windowController
{
	NGProjectController *controller;
	id info;
	NSWindow *window;
	
	[super windowControllerDidLoadNib:windowController];
	if([windowController isKindOfClass:[NGProjectController class]])
	{
		controller = (NGProjectController *) windowController;
		[controller setProjectRoots:[self projectRoots]];
	}
	window = [windowController window];
	if((info = [userDictionary objectForKey:@"NSWindow Frame"]))
	{
		[window setFrameFromString:info];
	}
	if((info = [userDictionary objectForKey:@"NSToolbar"]))
	{
		[[window toolbar] setConfigurationFromDictionary:info];
	}
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidMoveResize:) name:NSWindowDidMoveNotification object:window];
	[windowController showWindow:self];
}	

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError
{
	id plist, dict, item;
	NSString *projectPlistPath, *userFileName;
	
	isNativeProject = YES;
	hintURL = [url retain];
	projectPlistPath = [[[url path] stringByAppendingPathComponent:@"Contents"] stringByAppendingPathComponent:@"Info.plist"];
	if((plist = [NSDictionary dictionaryWithContentsOfFile:projectPlistPath]))
	{
		if((dict = [plist objectForKey:NGConstructionProjectInfoPlistKey]) && [dict isKindOfClass:[NSDictionary class]])
		{
			if((item = [dict objectForKey:@"Version"]) && NSOrderedSame == [NGConstructionProjectVersion1 caseInsensitiveCompare:item])
			{						
				projectDictionary = [dict mutableCopy];
				userFileName = [NSString stringWithFormat:@"user-%@.plist", NSUserName()];
				projectPlistPath = [[[url path] stringByAppendingPathComponent:@"Contents"] stringByAppendingPathComponent:userFileName];
				url = nil;
				if((plist = [NSDictionary dictionaryWithContentsOfFile:projectPlistPath]))
				{
					userDictionary = [plist retain];
				}
				else
				{
					NSLog(@"Failed to load %@", userFileName);
				}

			}
			else
			{
				NSLog(@"Version key does not exist or is not %@", NGConstructionProjectVersion1);
			}
			
		}
		else
		{
			NSLog(@"Project Info.plist dictionary does not contain %@", NGConstructionProjectInfoPlistKey);
		}
	}
	if(!projectDictionary)
	{
		projectDictionary = [[NSMutableDictionary alloc] init];
	}
	return YES;
}

- (BOOL) writeToURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError
{
	NSString *contents, *userFileName;
	NSMutableDictionary *dict;
	NSEnumerator *e;
	NSArray *roots;
	NSMutableArray *rootList;
	NSData *data;
	NSWindow *window;
	id rootItem;
	BOOL changed;
	
	contents = [[url path] stringByAppendingPathComponent:@"Contents"];
	if(NO == [[NSFileManager defaultManager] createDirectoryAtPath:contents withIntermediateDirectories:YES attributes:nil error:outError])
	{
		return NO;
	}
	dict = [NSMutableDictionary dictionaryWithCapacity:10];
	[projectDictionary setObject:NGConstructionProjectVersion1 forKey:@"Version"];
	roots = [self rootItems];
	rootList = [NSMutableArray arrayWithCapacity:[roots count]];
	changed = NO;
	e = [roots objectEnumerator];
	while((rootItem = [e nextObject]))
	{
		[rootList addObject:[rootItem representationForPropertyList]];
	}
	[projectDictionary setObject:rootList forKey:@"Roots"];
	[dict setObject:projectDictionary forKey:NGConstructionProjectInfoPlistKey];
	if(nil == (data = [NSPropertyListSerialization dataWithPropertyList:dict format:NSPropertyListXMLFormat_v1_0 options:0 error:outError]))
	{
		return NO;
	}
	if(![data writeToFile:[contents stringByAppendingPathComponent:@"Info.plist"] options:0 error:outError])
	{
		return NO;
	}
	if(!userDictionary)
	{
		userDictionary = [[NSMutableDictionary alloc] init];
	}
	window = [[[self windowControllers] objectAtIndex:0] window];
	[userDictionary setObject:[window stringWithSavedFrame] forKey:@"NSWindow Frame"];
	[userDictionary setObject:[[window toolbar] configurationDictionary] forKey:@"NSToolbar"];
	userFileName = [NSString stringWithFormat:@"user-%@.plist", NSUserName()];
	if(nil == (data = [NSPropertyListSerialization dataWithPropertyList:userDictionary format:NSPropertyListXMLFormat_v1_0 options:0 error:outError]))
	{
		return NO;
	}
	if(![data writeToFile:[contents stringByAppendingPathComponent:userFileName] options:0 error:outError])
	{
		return NO;
	}
	hasSignificantChanges = NO;
	isNativeProject = YES;
	return YES;
}

- (void) saveDocument:(id) sender
{
	if(isNativeProject)
	{
		[super saveDocument:sender];
	}
	else
	{
		[super saveDocumentAs:sender];
	}
}

- (void)canCloseDocumentWithDelegate:(id)delegate shouldCloseSelector:(SEL)shouldCloseSelector contextInfo:(void *)contextInfo
{
	if(isNativeProject)
	{
		[self saveDocument:self];
	}
	[super canCloseDocumentWithDelegate:delegate shouldCloseSelector:shouldCloseSelector contextInfo:contextInfo];
}

- (void)shouldSaveSoon:(id)sender
{
	/* Do nothing, for the time being */	
}

- (void) windowDidMoveResize:(NSNotification *)notification
{
	[self shouldSaveSoon:self];
}

- (void) dealloc
{
	[projectDictionary release];
	[userDictionary release];
	[hintURL release];
	[super dealloc];
}

- (BOOL) isDocumentEdited
{
	if(hasSignificantChanges)
	{
		return YES;
	}
	return NO;
}

- (NSArray *) projectRoots
{
	NSArray *rootList;
	
	if((rootList = [projectDictionary objectForKey:@"Roots"]))
	{
		return rootList;
	}
	if(hintURL)
	{
		return [NSArray arrayWithObject:hintURL];
	}
	return [NSArray array];
}

- (NSArray *) rootItems
{
	NGProjectController *wc;
	
	if((wc = [[self windowControllers] objectAtIndex:0]))
	{
		return [wc rootItems];
	}
	return nil;
}

@end
