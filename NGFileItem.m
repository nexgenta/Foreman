/*
 * Based upon GCFolderInfo from GCFBDemo, written by Graham Cox <graham.cox[at]bigpond.com>
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

#import "NGFileItem.h"

@implementation NGFileItem

- (id) initWithData:(id)data matching:(NSPredicate *)predicate notMatching:(NSPredicate *)antiPredicate includeFiles:(BOOL)files includeInvisibles:(BOOL)invisibles bundlesAsFolders:(BOOL)expandBundles;
{
	NSURL *aURL;
	NSString *path;
	OSStatus err;
	LSItemInfoRecord info;

	if([data isKindOfClass:[NSString class]])
	{
		aURL = [NSURL fileURLWithPath:[data stringByExpandingTildeInPath]];
	}
	else if([data isKindOfClass:[NSDictionary class]])
	{
		aURL = nil;
		if((path = [data objectForKey:@"path"]))
		{
			aURL = [NSURL fileURLWithPath:[path stringByExpandingTildeInPath]];
		}
	}
	else if([data isKindOfClass:[NSURL class]])
	{
		aURL = data;
	}
	if(!aURL)
	{
		NSLog(@"NGFileItem -initWithData: data object %@ could not be coalesced into a URL", data);
		[self dealloc];
		return nil;
	}
	if((self = [super initWithData:data matching:predicate notMatching:antiPredicate includeFiles:files includeInvisibles:invisibles bundlesAsFolders:expandBundles]))
	{
		url = [aURL retain];
		path = [aURL path];
		mName = [[path lastPathComponent] retain];
		displayName = [[[NSFileManager defaultManager] displayNameAtPath:path] retain];
		if([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&mIsFolder])
		{
			if(mIsFolder)
			{
				if([[NSWorkspace sharedWorkspace] isFilePackageAtPath:path])
				{
					mIsBundle = YES;
				}
			}
			mIsVisible = YES;
			if(!(err = LSCopyItemInfoForURL((CFURLRef) aURL, kLSRequestBasicFlagsOnly, &info)))
			{
				if(info.flags & kLSItemInfoIsInvisible)
				{
					mIsVisible = NO;
				}
			}			
		}
		else
		{
			NSLog(@"NGFileItem -initWithData: warning: no file exists at path %@", path);
		}
		if([mName characterAtIndex:0] == '.')
		{
			mIsVisible = NO;
		}		
	}
	return self;
}

- (void) dealloc
{
	[mName release];
	[displayName release];
	[url release];
	[mChildren release];
	[mPredicate release];
	[mAntiPredicate release];
	[fileTypes release];
	[super dealloc];
}

/* Return a human-readable description of this node for debugging purposes */
- (NSString*) description
{
	return [NSString stringWithFormat:@"<%@> %p = %@[%@]", NSStringFromClass([self class]), self, [self name], mChildren];
}

- (BOOL) matchesPredicate
{
	if(mPredicate && NO == [mPredicate evaluateWithObject:mName])
	{
		return NO;
	}
	if(mAntiPredicate && YES == [mAntiPredicate evaluateWithObject:mName])
	{
		return NO;
	}
	return YES;
}

- (BOOL) isFile
{
	return ((mBundlesAsFolders && mIsFolder) || !mIsFolder);
}

- (BOOL) isFolder
{
	return mIsFolder && (mBundlesAsFolders || !mIsBundle);
}

- (BOOL) isBundle
{
	return mIsBundle;
}

- (BOOL) isVisible
{
	return mIsVisible;
}

- (NSString*) defaultName
{
	return displayName;
}

- (NSURL *) url
{
	return url;
}

- (NSString*) path
{
	return [url path];
}

- (NSArray *) fileTypes
{
	NSDictionary *attributes;
	NSArray *attrNames;
	FSRef fileRef;
	Boolean dummyDir;
	id typeList;
	
	if(!fileTypes)
	{
		if(noErr == FSPathMakeRef((const UInt8 *)[[url path] fileSystemRepresentation], &fileRef, &dummyDir))
		{
			attrNames = [NSArray arrayWithObject:(NSString *)kLSItemContentType];
			if(noErr == LSCopyItemAttributes(&fileRef, kLSRolesViewer, (CFArrayRef) attrNames, (CFDictionaryRef *) &attributes))
			{
				if(attributes)
				{
					typeList = [attributes objectForKey:(NSString *)kLSItemContentType];
					if([typeList isKindOfClass:[NSArray class]])
					{
						fileTypes = [typeList retain];
					}
					else if([typeList isKindOfClass:[NSString class]])
					{
						fileTypes = [[NSMutableArray alloc] initWithObjects:typeList, nil];
					}
				}
			}
		}
	}
	return fileTypes;
}

- (BOOL) conformsToType:(NSString *)type
{
	NSEnumerator *e;
	NSArray *types;
	NSWorkspace *w;
	NSString *typeString;
	
	if(!(types = [self fileTypes]))
	{
		return NO;
	}
	w = [NSWorkspace sharedWorkspace];
	e = [types objectEnumerator];
	while((typeString = [e nextObject]))
	{
		if([w type:typeString conformsToType:type])
		{
			return YES;
		}
	}
	return NO;
}

- (NSArray*) children
{
	NSEnumerator *iter;
	NSString *sp;
	NSURL *fp;
	NGFileItem *fi;
	
	/* Lazily load the children of this entry */
	
	if( mChildren == nil && mIsFolder && (mBundlesAsFolders || !mIsBundle))
	{
		// search for subfolders at this path. Each one is stored in the array as a further GCFolderInfo object. Thus
		// this self-assembles a tree of the folders from the initial root path.
		
		iter = [[[NSFileManager defaultManager] directoryContentsAtPath:[self path]] objectEnumerator];		
		mChildren = [[NSMutableArray alloc] init];
		while((sp = [iter nextObject]))
		{
			fp = [[self url] URLByAppendingPathComponent:sp];
			if(!(fi = [[NGFileItem alloc] initWithData:fp matching:mPredicate notMatching:mAntiPredicate includeFiles:mIncludeFiles includeInvisibles:mIncludeInvisibles bundlesAsFolders:mBundlesAsFolders]))
			{
				continue;
			}
			if((NO == mIncludeFiles && NO == [fi isFolder]) ||
			   (NO == mIncludeInvisibles && NO == [fi isVisible]) ||
			   (NO == [fi matchesPredicate]))
		   {
				[fi release];
				continue;
			}
			[mChildren addObject:fi];
		}
	}	
	return mChildren;
}

/* Return the number of child items of the current path */
- (unsigned) valence
{
	if(mIsFolder)
	{
		return [[self children] count];
	}
	return 0;
}

/* Return the icon for the file represented by this instance as an NSImage */
- (NSImage*) defaultIcon
{
	return [[NSWorkspace sharedWorkspace] iconForFile:[url path]];
}

- (id) representationForPropertyList
{
	return [url path];
}

@end
