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

#import "NGToolbarItem.h"

@implementation NGToolbarItem

- (void)validate
{
	id target;
	BOOL chain;
	
	/* If the item has a specific target or delegate, use that. Otherwise,
	 * walk the responder chain until something returns NO or the chain runs
	 * out. This (code) seems to be the only way for -validateUserInterfaceItem:
	 * in a window controller to be able to disable toolbar items targeted at
	 * the First Responder.
	 */
	chain = NO;
	if([self action])
	{
		if(!(target = [self target]))
		{
			if(!(target = [[self toolbar] delegate]))
			{
				target = [[[self view] window] firstResponder];
				chain = YES;
			}
		}
		do
		{
			if([target respondsToSelector:@selector(validateToolbarItem:)])
			{
				if(![target validateToolbarItem:self])
				{
					[self setEnabled:NO];
					return;
				}
			}
			if([target respondsToSelector:@selector(validateUserInterfaceItem:)])
			{
				if(![target validateUserInterfaceItem:self])
				{
					[self setEnabled:NO];
					return;
				}
			}
			target = [target nextResponder];
		}
		while(target && chain);
	}
	[self setEnabled:YES];
}

@end
