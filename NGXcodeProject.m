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

#import "NGXcodeProject.h"

@interface NGXcodeProject (InternalMethods)

- (NSMutableDictionary *) dictionaryForPbxObject:(NSDictionary *)object fromObjects:(NSDictionary *)objects;

@end

@implementation NGXcodeProject

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError
{
	NSString *path;
	NSDictionary *plist;
	
	/* Load an Xcode project from the specified URL and construct a project
	 * window for it.
	 */
	path = [[url path] stringByAppendingPathComponent:@"project.pbxproj"];
	if((plist = [NSDictionary dictionaryWithContentsOfFile:path]))
	{
		pbxProject = [plist retain];
	}
	[self setFileType:NGConstructionProjectUTI];
	return YES;
}

- (NSArray *) projectRoots
{
	NSString *root;
	NSDictionary *objects;
	NSMutableDictionary *rootDict;
	id obj, mainGroup;
	
	root = [pbxProject objectForKey:@"rootObject"];
	objects = [pbxProject objectForKey:@"objects"];
	obj = [objects objectForKey:root];
	mainGroup = [objects objectForKey:[obj objectForKey:@"mainGroup"]];
	rootDict = [self dictionaryForPbxObject:mainGroup fromObjects:objects];
	[rootDict setObject:[NGFileTreeItem builtInImageNameForType:@"com.apple.xcode.project"] forKey:@"image"];
	return [NSMutableArray arrayWithObject:rootDict];
}

- (NSMutableDictionary *) dictionaryForPbxObject:(NSDictionary *)object fromObjects:(NSDictionary *)objects
{
	NSMutableDictionary *dict;
	NSMutableArray *childList;
	NSString *is, *lastKind, *name;
	NSEnumerator *e;
	id children, child;
	
	if(!object)
	{
		return nil;
	}
	dict = [NSMutableDictionary dictionaryWithDictionary:object];
	if((children = [object objectForKey:@"children"]))
	{
		if([children isKindOfClass:[NSArray class]])
		{
			childList = [NSMutableArray arrayWithCapacity:[children count]];
			e = [children objectEnumerator];
			while((child = [e nextObject]))
			{
				if((child = [self dictionaryForPbxObject:[objects objectForKey:child] fromObjects:objects]))
				{
					[childList addObject:child];
				}
			}
		}
		else
		{
			NSLog(@"NGXcodeProject -dictionaryForPbxObject:objects: children is not an array");
		}

	}
	else if((children = [dict objectForKey:@"mainGroup"]))
	{
		childList = [NSMutableArray arrayWithObject:[self dictionaryForPbxObject:[objects objectForKey:children] fromObjects:objects]];
	}
	else
	{
		childList = nil;
	}
	[dict removeObjectForKey:@"children"];
	if(childList)
	{
		[dict setObject:childList forKey:@"children"];
	}
	[dict setObject:@"NGGroupFolderItem" forKey:@"kind"];
	if((is = [object objectForKey:@"isa"]))
	{
		if(NSOrderedSame == [is caseInsensitiveCompare:@"pbxfilereference"])
		{
			[dict setObject:@"NGFileItem" forKey:@"kind"];
			if((lastKind = [object objectForKey:@"lastKnownFileType"]))
			{
				if((name = [NGFileTreeItem builtInImageNameForType:lastKind]))
				{
					[dict setObject:name forKey:@"image"];
				}
			}
		}
	}
	return dict;
}

@end
