//
//  GCIconTextFieldCell.m
//  GCDrawKit
//
//  Created by graham on 13/01/2009.
//  Copyright 2009 Apptree.net. All rights reserved.
//

#import "GCIconTextFieldCell.h"


@implementation GCIconTextFieldCell



- (void)			setTextFieldIcon:(NSImage*) icon
{
	[icon retain];
	[mIcon release];
	mIcon = icon;
}


- (NSImage*)		textFieldIcon
{
	return mIcon;
}

#pragma mark -
#pragma mark - as a NSTextFieldCell


- (void)			drawWithFrame:(NSRect) cellFrame inView:(NSView*) controlView
{
    if ( mIcon )
	{
		NSRect iconRect = NSInsetRect( cellFrame, 1, 1 );
		
		// note - icon display is currently fixed to 16 x 16 image
		
		iconRect.origin.y += floor(( NSHeight( iconRect ) - 17 ) * 0.5 );
		iconRect.size.width = iconRect.size.height = 16;
		
        if ([self drawsBackground])
		{
            [[self backgroundColor] set];
            NSRectFill( iconRect );
        }
		
		[mIcon setFlipped:[controlView isFlipped]];
		[mIcon drawInRect:iconRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
		
		cellFrame.origin.x += NSWidth( iconRect ) + 3;
		cellFrame.size.width -= ( NSWidth( iconRect ) + 3);
    }
    
	[super drawWithFrame:cellFrame inView:controlView];
}

/*
- (NSSize)			cellSize
{
    NSSize cellSize = [super cellSize];
	float imageSpace = cellSize.height * 1.5;
	
    cellSize.width += (mIcon? imageSpace : 0) + 3;
    
	return cellSize;
}
*/

- (NSRect)			drawingRectForBounds:(NSRect) theRect
{
	// Get the parent's idea of where we should draw
	NSRect newRect = [super drawingRectForBounds:theRect];
	
	// Get our ideal size for current text
	NSSize textSize = [self cellSizeForBounds:theRect];
	
	// Center that in the proposed rect
	float heightDelta = newRect.size.height - textSize.height;	
	
	if (heightDelta > 0)
	{
		newRect.size.height -= heightDelta;
		newRect.origin.y += (heightDelta / 2);
	}
	
	return newRect;
}





#pragma mark -
#pragma mark - as a NSObject

- (void)			dealloc
{
    [mIcon release];
    [super dealloc];
}



- (id)				copyWithZone:(NSZone*) zone
{
    GCIconTextFieldCell* cell = [super copyWithZone:zone];
    cell->mIcon = [mIcon retain];
    
	return cell;
}



@end
