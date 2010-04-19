//
//  GeneralPrefsController.h
//  Foreman
//
//  Created by Mo McRoberts on 2010-04-19.
//  Copyright 2010 Nexgenta. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SS_PreferencePaneProtocol.h"

@interface GeneralPrefsController : NSObject <SS_PreferencePaneProtocol> {
	IBOutlet NSView *prefsView;
}

@end
