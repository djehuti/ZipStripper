//
//  ZipStripperArchive.h
//  ZipStripper
//
//  Created by Ben Cox on 7/20/12.
//  Copyright 2012 Ben Cox. All rights reserved.
//


#import <Cocoa/Cocoa.h>


@interface ZipStripperArchive : NSDocument

@property (nonatomic, readonly, copy) NSArray* filesInArchive;
@property (nonatomic, readwrite, copy) NSSet* filesToBeRemoved;

- (BOOL) go;

@end
