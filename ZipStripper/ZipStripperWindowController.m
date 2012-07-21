//
//  ZipStripperWindowController.m
//  ZipStripper
//
//  Created by Ben Cox on 7/20/12.
//  Copyright 2012 Ben Cox. All rights reserved.
//


#import "ZipStripperWindowController.h"
#import "ZipStripperArchive.h"


@interface ZipStripperWindowController ()

- (void) p_syncTableViewWithDocument:(ZipStripperArchive*)document;
- (void) p_setRemoveButtonEnabledState;
- (void) p_dismissAlert:(NSTimer*)timer;
- (void) p_alertDidEnd:(NSAlert*)alert returnCode:(NSInteger)returnCode contextInfo:(void*)contextInfo;

@end


@implementation ZipStripperWindowController

@synthesize tableView = mTableView;
@synthesize progressSheet = mProgressSheet;
@synthesize progressIndicator = mProgressIndicator;
@synthesize removeButton = mRemoveButton;

- (void) dealloc
{
    [mTableView release];
    mTableView = nil;
    [mAlert release];
    mAlert = nil;
    [mAlertDismissTimer invalidate];
    mAlertDismissTimer = nil;
    [mProgressSheet release];
    mProgressSheet = nil;
    [mProgressIndicator release];
    mProgressIndicator = nil;
    [mRemoveButton release];
    mRemoveButton = nil;
    [super dealloc];
}

- (ZipStripperArchive*) document
{
    return (ZipStripperArchive*)[super document];
}

- (void) setDocument:(ZipStripperArchive*)document
{
    [super setDocument:document];
    [self p_syncTableViewWithDocument:document];
}

- (void) windowDidLoad
{
    [self p_syncTableViewWithDocument:self.document];
}

- (IBAction) removeTheFiles:(id)sender
{
    mAlert = [[NSAlert alloc] init];
    BOOL autoDismiss = YES;

    NSSet* filesToBeRemoved = [NSSet setWithArray:[self.document.filesInArchive objectsAtIndexes:[mTableView selectedRowIndexes]]];
    [self.document setFilesToBeRemoved:filesToBeRemoved];
    if ([filesToBeRemoved count] > 0) {
        __block BOOL success = NO;
        __block BOOL done = NO;
        dispatch_queue_t queue = dispatch_queue_create("com.djehuti.ZipStripper.processing", NULL);
        dispatch_async(queue, ^{
            BOOL tempSuccess = [self.document go];
            dispatch_async(dispatch_get_main_queue(), ^{
                success = tempSuccess;
                done = YES;
            });
        });
        [NSApp beginSheet:mProgressSheet modalForWindow:self.window modalDelegate:self didEndSelector:NULL contextInfo:NULL];
        [mProgressIndicator startAnimation:self];
        NSRunLoop* mainRunLoop = [NSRunLoop mainRunLoop];
        while (!done) {
            [mainRunLoop runMode:NSModalPanelRunLoopMode beforeDate:[NSDate distantFuture]];
        }
        dispatch_release(queue);
        [mProgressIndicator stopAnimation:self];
        [NSApp endSheet:mProgressSheet];
        [mProgressSheet orderOut:self];

        if (success) {
            mAlert.alertStyle = NSInformationalAlertStyle;
            mAlert.messageText = NSLocalizedString(@"Finished", @"Finished alert title");
            mAlert.informativeText = [NSString stringWithFormat:NSLocalizedString(@"The file '%@' was processed successfully.", @"Finished alert text"), [self.document.fileURL path]];
        } else {
            mAlert.alertStyle = NSWarningAlertStyle;
            mAlert.messageText = NSLocalizedString(@"Failed", @"Failed alert title");
            mAlert.informativeText = [NSString stringWithFormat:NSLocalizedString(@"Failed to process file '%@'.", @"Failed alert text"), [self.document.fileURL path]];
            autoDismiss = NO;
        }
    } else {
        mAlert.alertStyle = NSInformationalAlertStyle;
        mAlert.messageText = NSLocalizedString(@"Nothing to do", @"Nothing to do alert title");
        mAlert.informativeText = NSLocalizedString(@"No files were selected for removal.", @"no files selected text");
    }
    [mAlert beginSheetModalForWindow:self.window
                       modalDelegate:self
                      didEndSelector:@selector(p_alertDidEnd:returnCode:contextInfo:)
                         contextInfo:NULL];
    if (autoDismiss) {
        mAlertDismissTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(p_dismissAlert:) userInfo:nil repeats:NO];
    }
}

#pragma mark NSTableViewDataSource

- (NSInteger) numberOfRowsInTableView:(NSTableView*)tableView
{
    return (NSInteger) [self.document.filesInArchive count];
}

- (id) tableView:(NSTableView*)tableView objectValueForTableColumn:(NSTableColumn*)tableColumn row:(NSInteger)row
{
    return [self.document.filesInArchive objectAtIndex:row];
}

#pragma mark NSTableViewDelegate

- (void) tableViewSelectionDidChange:(NSNotification*)notification
{
    [self p_setRemoveButtonEnabledState];
}

#pragma mark Private Methods

- (void) p_syncTableViewWithDocument:(ZipStripperArchive*)document
{
    if (document && mTableView) {
        [mTableView reloadData];
        NSMutableIndexSet* indices = [NSMutableIndexSet indexSet];
        for (NSString* filename in document.filesToBeRemoved) {
            [indices addIndex:[document.filesInArchive indexOfObject:filename]];
        }
        [mTableView selectRowIndexes:indices byExtendingSelection:NO];
    }
    [self p_setRemoveButtonEnabledState];
}

- (void) p_setRemoveButtonEnabledState
{
    if (self.document && mTableView && mRemoveButton) {
        mRemoveButton.enabled = ([[mTableView selectedRowIndexes] count] > 0);
    } else {
        mRemoveButton.enabled = NO;
    }
}

- (void) p_dismissAlert:(NSTimer*)timer
{
    mAlertDismissTimer = nil;
    [NSApp endSheet:[mAlert window] returnCode:0];
}

- (void) p_alertDidEnd:(NSAlert*)alert returnCode:(NSInteger)returnCode contextInfo:(void*)contextInfo
{
    [mAlertDismissTimer invalidate];
    mAlertDismissTimer = nil;
    [mAlert release];
    mAlert = nil;
    [self.window close];
}

@end
