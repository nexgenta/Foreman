//
//  GCIconTextFieldCell.h
//  GCDrawKit
//
//  Created by graham on 13/01/2009.
//  Copyright 2009 Apptree.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface GCIconTextFieldCell : NSTextFieldCell <NSCopying>
{
	NSImage*		mIcon;
}

- (void)			setTextFieldIcon:(NSImage*) icon;
- (NSImage*)		textFieldIcon;

@end





/*

Text field cell achieves two things:
 
 a) it displays an icon to the left of the text
 b) it vertically centres the text

 n.b. Apple's sample code "ImageAndTextCell" is utterly brain-dead. Don't use it.

*/

