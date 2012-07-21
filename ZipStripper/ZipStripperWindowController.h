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
{
    NSTableView* mTableView;
    NSAlert* mAlert;
    NSTimer* mAlertDismissTimer;
    NSWindow* mProgressSheet;
    NSProgressIndicator* mProgressIndicator;
    NSButton* mRemoveButton;
}

@property (nonatomic, readwrite, retain) IBOutlet NSTableView* tableView;
@property (nonatomic, readwrite, retain) ZipStripperArchive* document;
@property (nonatomic, readwrite, retain) IBOutlet NSWindow* progressSheet;
@property (nonatomic, readwrite, retain) IBOutlet NSProgressIndicator* progressIndicator;
@property (nonatomic, readwrite, retain) IBOutlet NSButton* removeButton;

- (IBAction) removeTheFiles:(id)sender;

@end
