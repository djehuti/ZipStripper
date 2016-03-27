//
//  ZipStripperWindowController.h
//  ZipStripper
//
//  Created by Ben Cox on 7/20/12.
//  Copyright 2012 Ben Cox. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class ZipStripperArchive;


@interface ZipStripperWindowController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate>

@property (nullable, assign) ZipStripperArchive* document;
@property (nullable, retain) IBOutlet NSTableView* tableView;
@property (nullable, retain) IBOutlet NSWindow* progressSheet;
@property (nullable, retain) IBOutlet NSProgressIndicator* progressIndicator;
@property (nullable, retain) IBOutlet NSButton* removeButton;

- (IBAction) removeTheFiles:(nullable id)sender;

@end
