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

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

@interface NGFileTreeItem : NSObject {
	NSDictionary *itemDictionary;
	BOOL mIncludeInvisibles;
	BOOL mIncludeFiles;
	BOOL mBundlesAsFolders;
	NSPredicate *mPredicate;
	NSPredicate *mAntiPredicate;	
}

+ (id) fileTreeItemWithData:(id)data matching:(NSPredicate *)matchPredicate notMatching:(NSPredicate *)antiPredicate includeFiles:(BOOL)files includeInvisibles:(BOOL)invisibles bundlesAsFolders:(BOOL)expandBundles;
+ (id) fileTreeItemWithData:(id)data;

+ (NSString *) builtInImageNameForType:(NSString *)name;

- (id) initWithData:(id)data matching:(NSPredicate *)predicate notMatching:(NSPredicate *)antiPredicate includeFiles:(BOOL)files includeInvisibles:(BOOL)invisibles bundlesAsFolders:(BOOL)expandBundles;

- (BOOL) isFile;
- (BOOL) isFolder;
- (BOOL) isBundle;
- (BOOL) isVisible;
- (BOOL) matchesPredicate;
- (BOOL) conformsToType:(NSString *)type;
- (NSURL *) url;
- (NSString *) name;
- (NSString *) defaultName;
- (NSImage *) icon;
- (NSImage *) defaultIcon;
- (NSArray *) fileTypes;
- (NSArray *) children;
- (unsigned) valence;
- (id) representationForPropertyList;

@end

@interface NGFileTreeItem (QLPreviewItem) <QLPreviewItem>

@end
