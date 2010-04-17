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

#import "NGForemanDelegate.h"

@implementation NGForemanDelegate

/* - (void)openPath:(NSString *)path
{
	NGConstructionProject *controller;
	
	if((controller = [[NGConstructionProject alloc] initWithURL:[NSURL fileURLWithPath:path]]))
	{
		[controller setDelegate:self];
	}
}

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)path
{
	(void) sender;
	
	[self openPath:path];

	return true;
}

- (void) folderBrowser:(NGConstructionProject *) browser didSelectItem:(NGFileInfo*) item
{
}

- (void) openPanelDidEnd:(NSOpenPanel*) panel returnCode:(int) returnCode contextInfo:(void*) contextInfo
{
	if( returnCode == NSOKButton )
	{
		[self openPath:[panel filename]];
	}
}
*/

- (BOOL) applicationShouldOpenUntitledFile:(NSApplication *) sender
{
	(void) sender;
	
	return NO;
}

- (void) launchItem:(NGFileInfo *)item
{
	id type, uti, bundle;
	NSArray *supportedTypes, *urls;
	NSEnumerator *iter;
	
	if([item isFolder])
	{
		return;
	}
	if((supportedTypes = [[NSUserDefaults standardUserDefaults] arrayForKey:@"FileTypeHandlers"]))
	{
		iter = [supportedTypes objectEnumerator];
		while((type = [iter nextObject]))
		{
			if(![type isKindOfClass:[NSDictionary class]])
			{
				continue;
			}
			if(!(uti = [type objectForKey:@"UTI"]) && [uti isKindOfClass:[NSString class]])
			{
				continue;
			}
			if([item conformsToType:uti])
			{
				if((bundle = [type objectForKey:@"OpenWithBundle"]) && [bundle isKindOfClass:[NSString class]])
				{
					urls = [NSArray arrayWithObject:[NSURL fileURLWithPath:[item path]]];
					[[NSWorkspace sharedWorkspace] openURLs:urls withAppBundleIdentifier:bundle options:NSWorkspaceLaunchDefault additionalEventParamDescriptor:nil launchIdentifiers:NULL];
					return;
				}
				break;
			}

		}
	}
	[[NSWorkspace sharedWorkspace] openFile:[item path]];
}

/* File > New Project from Folder… */
- (IBAction) openFolder:(id)sender
{
	NSOpenPanel *openPanel;
	NSEnumerator *e;
	NSURL *u;
	NSError *err;
	
	openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseFiles:NO];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setAllowsMultipleSelection:YES];
	if(NSFileHandlingPanelOKButton == [openPanel runModal])
	{
		e = [[openPanel URLs] objectEnumerator];
		while((u = [e nextObject]))
		{
			if(nil == [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:u display:YES error:&err])
			{
				NSLog(@"openFolder: %@ - %@", u, err);
			}
		}
	}
}

@end
