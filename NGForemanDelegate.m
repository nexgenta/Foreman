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

+ (void) setupDefaults
{
	NSString *path;
	NSDictionary *dict;
	
	path = [[NSBundle mainBundle] pathForResource:@"UserDefaults" ofType:@"plist"];
    dict = [NSDictionary dictionaryWithContentsOfFile:path];
    [[NSUserDefaults standardUserDefaults] registerDefaults:dict];
}

+ (void) initialize
{
	[self setupDefaults];
}

- (BOOL) applicationShouldOpenUntitledFile:(NSApplication *) sender
{
	(void) sender;
	
	return NO;
}

- (void) launchItem:(NGFileTreeItem *)item
{
	id type, uti, bundle;
	NSArray *supportedTypes, *urls;
	NSEnumerator *iter;
	
	if(![item isFile])
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
					urls = [NSArray arrayWithObject:[item url]];
					[[NSWorkspace sharedWorkspace] openURLs:urls withAppBundleIdentifier:bundle options:NSWorkspaceLaunchDefault additionalEventParamDescriptor:nil launchIdentifiers:NULL];
					return;
				}
				break;
			}

		}
	}
	[[NSWorkspace sharedWorkspace] openURL:[item url]];
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

- (IBAction)showPrefs:(id)sender
{
	NSString *path;
	
    if(!prefs)
	{
        path = [[NSBundle mainBundle] builtInPlugInsPath];
        prefs = [[SS_PrefsController alloc] initWithPanesSearchPath:path];
		[prefs setAlwaysShowsToolbar:YES];
		[prefs setPanesOrder:[NSArray arrayWithObjects:@"General", @"File Types", nil]];
    }
	[prefs showPreferencesWindow];
}

@end
