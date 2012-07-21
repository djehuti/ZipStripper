//
//  ZipStripperArchive.m
//  ZipStripper
//
//  Created by Ben Cox on 7/20/12.
//  Copyright 2012 Ben Cox. All rights reserved.
//


#import "ZipStripperArchive.h"
#import "ZipStripperWindowController.h"


static NSString* const kUnzipPath = @"/usr/bin/unzip";
static NSString* const kZipPath = @"/usr/bin/zip";


@interface ZipStripperArchive ()
{
    NSArray* mFilesInArchive;
    NSSet* mFilesToBeRemoved;
}

@property (nonatomic, readwrite, copy) NSArray* filesInArchive;

- (BOOL) p_readZipArchiveFromFile:(NSString*)pathname;
- (BOOL) p_updateZipArchiveAtFile:(NSString*)pathname;

@end

#pragma mark -

@implementation ZipStripperArchive

#pragma mark Properties

@synthesize filesInArchive = mFilesInArchive;
@synthesize filesToBeRemoved = mFilesToBeRemoved;

#pragma mark Lifecycle

- (id)init
{
    if ((self = [super init])) {
    }
    return self;
}

- (void) dealloc
{
    [mFilesInArchive release];
    mFilesInArchive = nil;
    [mFilesToBeRemoved release];
    mFilesToBeRemoved = nil;
    [super dealloc];
}

#pragma mark Window Controller

- (void) makeWindowControllers
{
    [self addWindowController:[[[ZipStripperWindowController alloc] initWithWindowNibName:@"ZipStripperArchive"] autorelease]];
}

#pragma mark Persistence

- (NSData*) dataOfType:(NSString*)typeName error:(NSError**)outError
{
    // ZipStripperArchive documents don't "save" per se.

    if (outError) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
    }
    return nil;
}

- (BOOL) readFromURL:(NSURL*)absoluteURL ofType:(NSString*)typeName error:(NSError**)outError
{
    BOOL result = NO;
    if ([absoluteURL isFileURL]) {
        result = [self p_readZipArchiveFromFile:[absoluteURL path]];
    }
    else {
        // Not a file URL. Can't deal with that.
        if (outError) {
            *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
        }
    }
    return result;
}

#pragma mark Methods

- (BOOL) go
{
    BOOL result = YES;
    if ([mFilesToBeRemoved count] > 0) {
        result = [self p_updateZipArchiveAtFile:[[self fileURL] path]];
    }
    return result;
}

#pragma mark Private Methods

- (BOOL) p_readZipArchiveFromFile:(NSString*)pathname
{
    BOOL result = YES;

    NSMutableString* zipOutput = [[[NSMutableString alloc] init] autorelease];
    NSPipe* pipe = [NSPipe pipe];
    NSFileHandle* readHandle = [pipe fileHandleForReading];
    NSData* readData = nil;

    NSTask* zipTask = [[[NSTask alloc] init] autorelease];
    zipTask.launchPath = kUnzipPath;
    zipTask.arguments = [NSArray arrayWithObjects:@"-ql", pathname, nil];
    zipTask.standardInput = [NSFileHandle fileHandleWithNullDevice];
    zipTask.standardOutput = pipe;
    zipTask.standardError = [NSFileHandle fileHandleWithNullDevice];
    [zipTask launch];

    while ((readData = [readHandle availableData]) && [readData length]) {
        [zipOutput appendString:[[[NSString alloc] initWithData:readData encoding:NSISOLatin1StringEncoding] autorelease]];
    }
    [zipTask waitUntilExit];
    if ([zipTask terminationStatus] != 0) {
        result = NO;
    }
    else {
        NSArray* lines = [zipOutput componentsSeparatedByString:@"\n"];
        if ([lines count] >= 5) {
            lines = [lines subarrayWithRange:NSMakeRange(0, [lines count] - 3)];
        }
        NSUInteger columnIndex = 0;
        BOOL foundFirstLine = NO;
        BOOL foundDashLine = NO;
        NSMutableArray* filenames = [NSMutableArray arrayWithCapacity:[lines count]];
        NSMutableSet* filesToRemove = [NSMutableSet set];
        for (NSString* line in lines) {
            if (!foundFirstLine) {
                NSRange nameRange = [line rangeOfString:@"Name"];
                if (nameRange.location != NSNotFound) {
                    foundFirstLine = YES;
                    columnIndex = nameRange.location;
                }
            }
            else if (!foundDashLine) {
                NSRange dashRange = [line rangeOfString:@"----"];
                if (dashRange.location != NSNotFound) {
                    foundDashLine = YES;
                }
            }
            else {
                if ([line length] > columnIndex) {
                    NSString* filename = [line substringFromIndex:columnIndex];
                    [filenames addObject:filename];
                    if ([[filename lastPathComponent] isEqualToString:@".DS_Store"]) {
                        [filesToRemove addObject:filename];
                    }
                    else {
                        NSArray* components = [filename pathComponents];
                        if ([components containsObject:@"__MACOSX"]) {
                            [filesToRemove addObject:filename];
                        }
                    }
                }
            }
        }
        self.filesInArchive = filenames;
        self.filesToBeRemoved = filesToRemove;
    }

    return result;
}

- (BOOL) p_updateZipArchiveAtFile:(NSString*)pathname
{
    BOOL result = YES;
    if ([self.filesToBeRemoved count] > 0) {
        NSMutableArray* arguments = [NSMutableArray arrayWithCapacity:[self.filesToBeRemoved count] + 2];
        [arguments addObject:@"-d"];
        [arguments addObject:pathname];
        [arguments addObjectsFromArray:[self.filesToBeRemoved allObjects]];

        NSTask* zipTask = [[[NSTask alloc] init] autorelease];
        zipTask.launchPath = kZipPath;
        zipTask.arguments = arguments;
        zipTask.standardInput = [NSFileHandle fileHandleWithNullDevice];
        zipTask.standardOutput = [NSFileHandle fileHandleWithNullDevice];
        zipTask.standardError = [NSFileHandle fileHandleWithNullDevice];
        [zipTask launch];
        [zipTask waitUntilExit];
        if ([zipTask terminationStatus] != 0) {
            result = NO;
        }
    }
    return result;
}

@end
