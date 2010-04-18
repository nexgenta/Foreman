/* Copyright (c) 2010 Mo McRoberts <mo.mcroberts@nexgenta.com>
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

#import "NGFileTreeItem.h"
#import "NGFileItem.h"
#import "NGGroupFolderItem.h"

@implementation NGFileTreeItem

+ (id) fileTreeItemWithData:(id)data parent:(id)parent matching:(NSPredicate *)matchPredicate notMatching:(NSPredicate *)antiPredicate includeFiles:(BOOL)files includeInvisibles:(BOOL)invisibles bundlesAsFolders:(BOOL)expandBundles
{
	id entry, kind;
	
	if([data isKindOfClass:[NSURL class]] || [data isKindOfClass:[NSString class]])
	{
		entry = [NGFileItem alloc];
	}
	else if([data isKindOfClass:[NSDictionary class]])
	{
		if((kind = [data objectForKey:@"kind"]))
		{
			entry = [NSClassFromString(kind) alloc];
		}
		else
		{
			entry = [NGGroupFolderItem alloc];
		}
	}
	if(entry)
	{
		entry = [[entry initWithData:data parent:parent matching:matchPredicate notMatching:antiPredicate includeFiles:files includeInvisibles:invisibles bundlesAsFolders:expandBundles] autorelease];
	}
	return entry;
}

+ (id) fileTreeItemWithData:(id)data
{
	return [NGFileTreeItem fileTreeItemWithData:data parent:nil matching:nil notMatching:nil includeFiles:YES includeInvisibles:NO bundlesAsFolders:NO];
}

+ (NSString *) builtInImageNameForType:(NSString *)name
{
	NSDictionary *dict;
	
	if((dict = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NGBuiltinIconDocumentTypeIcons"]))
	{
		/* XXX: In future, this may well be an NSDictionary containing both
		 * default and alternative state images.
		 */
		return [dict objectForKey:name];
	}
	return nil;
}

- (id) initWithData:(id)data parent:(id)parent matching:(NSPredicate *)matchPredicate notMatching:(NSPredicate *)antiPredicate includeFiles:(BOOL)files includeInvisibles:(BOOL)invisibles bundlesAsFolders:(BOOL)expandBundles
{
	id obj;
	
	if((self = [super init]))
	{
		mIncludeFiles = files;
		mIncludeInvisibles = invisibles;
		mBundlesAsFolders = expandBundles;
		mPredicate = [matchPredicate retain];
		mAntiPredicate = [antiPredicate retain];
		/* Allow the per-node dictionary to override the defaults */
		if([data isKindOfClass:[NSDictionary class]])
		{
			itemDictionary = [data retain];
			if((obj = [data objectForKey:@"includeFiles"]) && [obj isKindOfClass:[NSNumber class]])
			{
				mIncludeFiles = [obj boolValue];
			}
			if((obj = [data objectForKey:@"includeInvisibles"]) && [obj isKindOfClass:[NSNumber class]])
			{
				mIncludeInvisibles = [obj boolValue];
			}
			if((obj = [data objectForKey:@"showBundlesAsFolders"]) && [obj isKindOfClass:[NSNumber class]])
			{
				mBundlesAsFolders = [obj boolValue];
			}
		}
	}
	return self;
}

- (void) dealloc
{
	[mPredicate release];
	[mAntiPredicate release];
	[itemDictionary release];
	[super dealloc];
}

- (BOOL) isFile
{
	return NO;
}

- (BOOL) isFolder
{
	return NO;
}

- (BOOL) isBundle
{
	return NO;
}

- (BOOL) isVisible
{
	return YES;
}

- (BOOL) matchesPredicate
{
	return YES;
}

- (BOOL) conformsToType:(NSString *)type
{
	return NO;
}

- (NSURL *) url
{
	return nil;
}

- (NSString *) name
{
	NSString *name;
	
	if((name = [itemDictionary objectForKey:@"displayName"]))
	{
		return name;
	}
	if((name = [itemDictionary objectForKey:@"name"]))
	{
		return name;
	}
	return [self defaultName];
}

- (NSString *) defaultName
{
	return @"NGFileTreeInfo item";
}

- (NSImage *) icon
{
	NSString *n;
	
	if((n = [itemDictionary objectForKey:@"image"]))
	{
		return [NSImage imageNamed:n];
	}	
	return [self defaultIcon];
}

- (NSImage *) defaultIcon
{
	return nil;
}

- (NSArray *) fileTypes
{
	return nil;
}

- (NSArray *) children
{
	return nil;
}

- (unsigned) valence
{
	NSArray *c;
	
	if((c = [self children]))
	{
		return [c count];
	}
	return 0;
}

- (id) representationForPropertyList
{
	return itemDictionary;
}

@end

@implementation NGFileTreeItem (QLPreviewItem)

- (NSURL *)previewItemURL
{
    return [self url];
}

- (NSString *)previewItemTitle
{
    return [self name];
}

@end
