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


#import "FileTypeItem.h"

@interface FileTypeItem(InternalMethods)

- (NSDictionary *) handlersForUTI:(NSString *)uti;
- (void) addHandlerWithBundleIdentifer:(NSString *)identifier forContentType:(NSString *)uti toList:(NSMutableDictionary *)dict;
- (NSMenuItem *) menuItemForBundleWithIdentifier:(NSString *)identifier andFormat:(NSString *)format;

@end

@implementation FileTypeItem

+ (id) fileTypeItemWithDictionary:(NSDictionary *)dict parent:(FileTypeItem *)parentItem
{
	return [[[FileTypeItem alloc] initWithDictionary:dict parent:parentItem] autorelease];
}

- (id) initWithDictionary:(NSDictionary *)dict parent:(FileTypeItem *)parentItem
{
	NSArray *supportedTypes;
	NSEnumerator *iter;
	id type, iterUTI;
	
	if((self = [super init]))
	{
		parent = parentItem;
		uti = [[dict objectForKey:@"uti"] retain];
		defaultDescription = [[dict objectForKey:@"defaultDescription"] retain];
		children = [[dict objectForKey:@"children"] retain];
		if(![children isKindOfClass:[NSArray class]])
		{
			[children release];
			children = nil;
		}
		bundleIdentifier = nil;
		if((supportedTypes = [[NSUserDefaults standardUserDefaults] arrayForKey:@"FileTypeHandlers"]))
		{
			iter = [supportedTypes objectEnumerator];
			while((type = [iter nextObject]))
			{
				if(![type isKindOfClass:[NSDictionary class]])
				{
					continue;
				}
				if(!(iterUTI = [type objectForKey:@"UTI"]) && [iterUTI isKindOfClass:[NSString class]])
				{
					continue;
				}
				if(NSOrderedSame != [iterUTI caseInsensitiveCompare:uti])
				{
					continue;
				}
				bundleIdentifier = [[type objectForKey:@"OpenWithBundle"] retain];
				NSLog(@"uti %@ always opens with %@", uti, bundleIdentifier);
				break;
			}
		}
		NSLog(@"-[FileTypeItem initWithDictionary:parent:] uti = %@, defaultDescription = %@, bundleIdentifier = %@", uti, defaultDescription, bundleIdentifier);

	}
	return self;
}

- (void) dealloc
{
	parent = nil;
	[uti release];
	[defaultDescription release];
	[children release];
	[childItems release];
	[bundleIdentifier release];
	[menu release];
	[selectedItem release];
	[super dealloc];
}

- (NSInteger) numberOfChildren
{
	return [children count];
}

- (NSString *) description
{
	return defaultDescription;
}

- (NSArray *) children
{
	NSEnumerator *iter;
	id dict, item;
	
	if(!childItems)
	{
		childItems = [[NSMutableArray alloc] initWithCapacity:[children count]];
		iter = [children objectEnumerator];
		while((dict = [iter nextObject]))
		{
			if((item = [FileTypeItem fileTypeItemWithDictionary:dict parent:self]))
			{
				[childItems addObject:item];
			}
		}
	}
	return childItems;
}

- (NSString *) handlerName
{
	NSLog(@"-[handlerName] of %@ = %@", uti, [[self selectedItem] title]);
	return [[self selectedItem] title];
}

- (NSString *) currentHandlerIdentifier
{
	if(bundleIdentifier)
	{
		return bundleIdentifier;
	}
	if(forceOpenWithFinder)
	{
		return @"com.apple.Finder";
	}
	if(parent)
	{
		return [parent currentHandlerIdentifier];
	}
	return @"com.apple.Finder";
}

- (BOOL) handlerIsEnforcedFinder
{
	return NO;
}

- (NSString *) uti
{
	return uti;
}

- (FileTypeItem *) parent
{
	return parent;
}

- (void) setHandlerName:(NSString *)name
{
	NSLog(@"setHandlerName: %@", name);
}

- (NSMenu *) menu
{
	BOOL first;
	NSDictionary *handlers, *entry;
	NSString *key, *path;
	NSEnumerator *iter;
	NSMenuItem *menuItem;
	NSImage *image;
	NSSize iconSize = { 16, 16 };
	
	if(!menu)
	{
		NSLog(@">>> Building menu for %@, opens with %@", uti, bundleIdentifier);
		[selectedItem release];
		handlers = [self handlersForUTI:uti];
		iter = [handlers keyEnumerator];
		menu = [[NSMenu alloc] initWithTitle:@"Opens With…"];
		if(parent)
		{
			menuItem = [self menuItemForBundleWithIdentifier:[parent currentHandlerIdentifier] andFormat:@"Same as %2$@ (currently %1$@)"];
			[menu addItem:menuItem];
			selectedItem = menuItem;
		}
		else
		{
			selectedItem = nil;
		}
		menuItem = [self menuItemForBundleWithIdentifier:nil andFormat:@"Always open with %@"];
		[menu addItem:menuItem];
		if(!selectedItem || (!bundleIdentifier && [self handlerIsEnforcedFinder]))
		{
			selectedItem = menuItem;
		}
		first = YES;
		while((key = [iter nextObject]))
		{
			entry = [handlers objectForKey:key];
			if(first)
			{
				first = NO;
				[menu addItem:[NSMenuItem separatorItem]];
			}
			path = [entry objectForKey:@"path"];
			menuItem = [[NSMenuItem alloc] initWithTitle:[[NSFileManager defaultManager] displayNameAtPath:path] action:NULL keyEquivalent:@""];
			[menuItem setRepresentedObject:key];
			image = [[NSWorkspace sharedWorkspace] iconForFile:path];
			[image setSize:iconSize];
			[menuItem setImage:image];
			[menu addItem:[menuItem autorelease]];
			if(NSOrderedSame == [key caseInsensitiveCompare:bundleIdentifier])
			{
				NSLog(@"Selected handler for %@ is %@", uti, key);
				selectedItem = menuItem;
			}
		}
		selectedItem = [selectedItem retain];
	}
	return menu;
}

- (NSMenuItem *) selectedItem
{
	[self menu];
	return selectedItem;
}

- (NSMenuItem *) menuItemForBundleWithIdentifier:(NSString *)identifier andFormat:(NSString *)format
{
	NSString *path, *displayName;
	NSMenuItem *item;
	NSImage *image;
	NSSize iconSize = { 16, 16 };
	
	if(!identifier)
	{
		identifier = @"com.apple.Finder";
	}
	path = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:identifier];
	displayName = [[NSFileManager defaultManager] displayNameAtPath:path];
	item = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:format, displayName, [parent description]] action:NULL keyEquivalent:@""];
	[item setRepresentedObject:identifier];
	image = [[NSWorkspace sharedWorkspace] iconForFile:path];
	[image setSize:iconSize];
	[item setImage:image];
	return [item autorelease];
}

- (NSDictionary *) handlersForUTI:(NSString *)aUTI
{
	NSDictionary *dict;
	NSMutableArray *utiList, *doneList;
	NSMutableDictionary *handlerList;
	NSArray *handlers;
	NSEnumerator *e;
	id conforming, s;
	
	utiList = [NSMutableArray arrayWithObject:aUTI];
	doneList = [NSMutableArray array];
	handlerList = [NSMutableDictionary dictionary];
	while([utiList count])
	{
		aUTI = [utiList lastObject];
		[doneList addObject:aUTI];
		[utiList removeLastObject];
		dict = (NSDictionary *) UTTypeCopyDeclaration((CFStringRef) aUTI);
		if((conforming = [dict objectForKey:@"UTTypeConformsTo"]))
		{
			if([conforming isKindOfClass:[NSString class]] && ![utiList containsObject:conforming])
			{
				[utiList addObject:conforming];
			}
			else if([conforming isKindOfClass:[NSArray class]])
			{
				e = [conforming objectEnumerator];
				while((s = [e nextObject]))
				{
					if([s isKindOfClass:[NSString class]] && ![utiList containsObject:s])
					{
						[utiList addObject:s];
					}
				}
			}
		}
		if((handlers = (NSArray *) LSCopyAllRoleHandlersForContentType((CFStringRef) aUTI, kLSRolesEditor|kLSRolesViewer|kLSRolesShell)))
		{
			e = [handlers objectEnumerator];
			while((s = [e nextObject]))
			{
				[self addHandlerWithBundleIdentifer:s forContentType:aUTI toList:handlerList];
			}
		}
	}
	NSLog(@"conforming types for %@ = %@", aUTI, doneList);
	return handlerList;
}

- (void) addHandlerWithBundleIdentifer:(NSString *)identifier forContentType:(NSString *)aUTI toList:(NSMutableDictionary *)dict
{
	NSDictionary *entry;
	
	if((entry = [dict objectForKey:identifier]))
	{
		[[entry objectForKey:@"types"] addObject:aUTI];
	}
	else
	{
		[dict setObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:[[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:identifier], @"path",
						 [NSMutableArray arrayWithObject:aUTI], @"types", nil] forKey:identifier];
	}
}

	

@end
