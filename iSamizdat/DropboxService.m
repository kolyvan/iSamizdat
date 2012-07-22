//
//  DropboxService.m
//  iSamizdat
//
//  Created by Kolyvan on 20.07.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//

#import "DropboxService.h"
#import "KxMacros.h"
#import "KxUtils.h"
#import "NSArray+Kolyvan.h"
#import "NSDictionary+Kolyvan.h"
#import "NSDate+Kolyvan.h"
#import "NSString+Kolyvan.h"
#import "AppDelegate.h"
#import <DropboxSDK/DropboxSDK.h>
#import "DDLog.h"

extern int ddLogLevel;

static DropboxService *gShared = nil;

///////

@interface DropboxTaskImpl : NSObject<DropboxTask>

@property (readwrite) DropboxTaskMode mode;
@property (readonly, strong) DropboxServiceBlock completion;

@property (readonly, strong) NSString *filename;
@property (readonly, strong) NSString *localFolder;
@property (readonly, strong) NSString *remoteFolder;

@property (readonly, strong) NSString *localPath;
@property (readonly, strong) NSString *remotePath;

@property (readwrite, strong) DBMetadata *metadata;
@end

@implementation DropboxTaskImpl
@synthesize mode = _mode, completion = _completion, filename =_filename;
@synthesize localFolder = _localFolder, remoteFolder = _remoteFolder, metadata = _metadata;

- (id) init: (DropboxTaskMode) mode
   filename: (NSString *) filename  
      local: (NSString *) localFolder 
     remote: (NSString *) remoteFolder 
 completion: (DropboxServiceBlock) completion
{
    self = [super init];
    if (self) {        
        _mode = mode;
        _filename = filename;
        _localFolder = localFolder;
        _remoteFolder = remoteFolder;
        _completion = completion;
    }
    return self;
}

- (NSString *) localPath
{
    return [_localFolder stringByAppendingPathComponent:_filename];
}

- (NSString *) remotePath
{
    return [_remoteFolder stringByAppendingPathComponent:_filename];
}

- (NSString *) description
{    
    if (_metadata)    
        return KxUtils.format(@"<DT %@ %@ %@ (%@)>", 
                              self.modeAsString, _filename, _remoteFolder, _metadata.humanReadableSize);
    return KxUtils.format(@"<DT %@ %@ %@>", self.modeAsString,  _filename, _remoteFolder);
}

- (NSString *) modeAsString
{
    switch (_mode) {
        case DropboxTaskModeCanceled:   return @"canceled";            
        case DropboxTaskModeUpload:     return @"upload";            
        case DropboxTaskModeDownload:   return @"download";
        case DropboxTaskModeSync:       return @"synced";
        case DropboxTaskModeMetadata:   return @"query";
    }    
}

@end

///////

@interface DropboxService () <DBSessionDelegate, DBNetworkRequestDelegate, DBRestClientDelegate> {

    DBRestClient *_restClient;    
    NSString *_relinkUserId;
    NSMutableArray *_tasks;
}
@end

@implementation DropboxService

@synthesize delegate;

+ (DropboxService *) shared
{    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        gShared = [[DropboxService alloc] init];
        
    });
    
    return gShared;
}

- (BOOL)handleOpenURL:(NSURL*)url
{
    DBSession *session = [DBSession sharedSession];
    
    if ([session handleOpenURL:url]) {
        
        [[[UIAlertView alloc] initWithTitle:@"Dropbox"
                                    message:session.isLinked ? locString(@"App linked") : locString(@"App unlinked")
                                   delegate:nil
                          cancelButtonTitle:locString(@"Ok")
                          otherButtonTitles:nil] show]; 
                
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DropboxLinkChanged" object:nil];
        
        return YES;
    }    
    return NO;
}

- (BOOL) isLinked
{
    return [[DBSession sharedSession] isLinked];
}

- (NSUInteger) tasksCount
{
    return _tasks.count;
}

- (id) init
{
    self = [super init];
    if (self) {
                        
        NSAssert(nil == gShared, @"DropboxService singleton already created");
            
        _tasks = [NSMutableArray array];
        
        NSString *secret = [NSString stringWithContentsOfFile:KxUtils.pathForResource(@"dropbox.secret") 
                                                     encoding:NSUTF8StringEncoding 
                                                        error:nil];
        
        if (secret.nonEmpty) {
        
            DBSession* session = [[DBSession alloc] initWithAppKey:@"8jr6tpiiyvlr8jg" 
                                                         appSecret:secret
                                                              root:kDBRootAppFolder];
            session.delegate = self;	
            [DBSession setSharedSession:session];    	
            [DBRequest setNetworkRequestDelegate:self];  
            
            if ([session isLinked]) {
                
                DDLogInfo(@"Dropbox is linked");               
                
            } else {
                
                DDLogInfo(@"Dropbox is not linked");               
            }
            
        } else {
        
            DDLogWarn(@"Dropbox secret not found"); 
            self = nil;
        }
    }
    return self;
}

- (void) cancelAll
{
    if (_restClient) {
        [_restClient cancelAllRequests];
        _restClient = nil;
    }
    
    [_tasks removeAllObjects];
}

- (DBRestClient *)restClient 
{
    if (!_restClient) {
        
        NSAssert([DBSession sharedSession].isLinked, @"dropbox is not linked");
        _restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        _restClient.delegate = self;
    }
    return _restClient;
}

- (void) toggleLink: (UIViewController *) vc
{	
    DBSession *session = [DBSession sharedSession];
    
    if (session.isLinked) {
        
         [session unlinkAll];
        
    }  else {
        
        [session linkFromController:vc];
    }   
}

- (void) link: (UIViewController *) vc
{	    
    if (![[DBSession sharedSession] isLinked]) {
        
        DBSession *session = [DBSession sharedSession];
        [session linkFromController:vc];
    }    
}

- (void) upload: (NSString *) filename  
          local: (NSString *) localFolder 
         remote: (NSString *) remoteFolder
     completion: (DropboxServiceBlock) completion;
{        
    [self handle:DropboxTaskModeUpload 
        filename:filename 
           local:localFolder 
          remote:remoteFolder 
      completion:completion];
}

- (void) download: (NSString *) filename  
            local: (NSString *) localFolder 
           remote: (NSString *) remoteFolder 
       completion: (DropboxServiceBlock) completion
{   
    [self handle:DropboxTaskModeDownload 
        filename:filename 
           local:localFolder 
          remote:remoteFolder 
      completion:completion];

}

- (void) sync: (NSString *) filename  
        local: (NSString *) localFolder 
       remote: (NSString *) remoteFolder 
   completion: (DropboxServiceBlock) completion
{
    [self handle:DropboxTaskModeSync 
        filename:filename 
           local:localFolder 
          remote:remoteFolder 
      completion:completion];
}

- (void) loadMetadata: (NSString *) filename  
               remote: (NSString *) remoteFolder 
           completion: (DropboxServiceBlock) completion
{
    [self handle:DropboxTaskModeMetadata 
        filename:filename 
           local:nil 
          remote:remoteFolder 
      completion:completion];
}

- (void) handle: (DropboxTaskMode) mode
       filename: (NSString *) filename  
          local: (NSString *) localFolder 
         remote: (NSString *) remoteFolder
     completion: (DropboxServiceBlock) completion;
{   
    DropboxTaskImpl *task  = [[DropboxTaskImpl alloc] init: mode 
                                                  filename: filename  
                                                     local: localFolder 
                                                    remote: remoteFolder
                                                completion: completion];
    
    DDLogVerbose(@"dropbox added %@", task); 
    
    [_tasks addObject:task];    
    if (_tasks.count == 1)
        [self process];
}

- (void) process
{
    if (_tasks.nonEmpty) {
    
        DropboxTaskImpl *task = _tasks.first;
        
        DDLogVerbose(@"dropbox process %@", task);  
        
        if (self.delegate)
            [self.delegate willProcessTask:task tasksCount:_tasks.count];
        
        if (task.metadata) {
            
            if (task.mode == DropboxTaskModeSync) {  
                
                if (task.metadata.isDeleted) {
                    
                    task.mode = DropboxTaskModeUpload;
                    
                } else {
                
                    NSFileManager *fm = KxUtils.fileManager();
                    
                    if ([fm fileExistsAtPath:task.localPath]) {
                        
                        NSDictionary *attr = [fm attributesOfItemAtPath:task.localPath error:nil];
                        
                        NSDate *lt = [attr get: NSFileModificationDate];
                        NSDate *dt = task.metadata.lastModifiedDate;
                        
                        if ([lt isLess: dt]) {                        
                            
                            task.mode = DropboxTaskModeDownload;                        
                            
                        } else if ([lt isGreater: dt]) {
                            
                            task.mode = DropboxTaskModeUpload;
                        }
                        
                    } else {
                        
                        task.mode = DropboxTaskModeDownload;
                    }
                }
                
                if (task.mode == DropboxTaskModeSync) {

                    [self complete:nil failure:nil];
                    return;
                }
            }
            
            if (task.mode == DropboxTaskModeUpload) {
                
                if (!KxUtils.fileExists(task.localPath)) {
                    
                    task.mode = DropboxTaskModeCanceled;  
                    [self complete:nil failure:nil];
                    return;                
                }
                
                [self.restClient uploadFile:task.filename
                                     toPath:task.remoteFolder
                              withParentRev:task.metadata.isDeleted ? nil : task.metadata.rev 
                                   fromPath:task.localPath];
                
            } else if (task.mode == DropboxTaskModeDownload) {  
                
                if (task.metadata.isDeleted) {
                    
                    task.mode = DropboxTaskModeCanceled;
                    [self complete:nil failure:nil];
                    return;
                }
                
                [self.restClient loadFile:task.remotePath 
                                 intoPath:task.localPath];
                
            } 
            
        } else {

            [self.restClient loadMetadata: task.remotePath]; 
        }
    }
}

- (void) complete:(DBMetadata*)metadata failure: (NSError*)error 
{    
    if (error)
        DDLogWarn(@"dropbox failure: %@", KxUtils.completeErrorMessage(error));
    
    if (_tasks.nonEmpty) {
        
        DropboxTaskImpl *task = _tasks.first;
                
        if (metadata)
            task.metadata = metadata;
        
        DDLogVerbose(@"dropbox complete %@", task); 
        
        if (task.completion)
            task.completion(task, error);
                
        if (self.delegate)
            [self.delegate didCompleteTask:task tasksCount:_tasks.count - 1 error:error];
        
        [_tasks removeObjectAtIndex:0];  
        [self process];
    }
}

- (void) syncTime: (DBMetadata *) metadata forPath: (NSString *) localPath 
{   
    //DDLogVerbose(@"dropbox syncTime %@ %@", localPath, metadata.lastModifiedDate);     
    
    NSDictionary *attr = [NSDictionary dictionaryWithObject:metadata.lastModifiedDate
                                                     forKey:NSFileModificationDate];
    [KxUtils.fileManager() setAttributes:attr
                            ofItemAtPath:localPath 
                                   error:nil];
}

#pragma mark - DBSessionDelegate methods

- (void)sessionDidReceiveAuthorizationFailure:(DBSession*)session userId:(NSString *)userId 
{    
	_relinkUserId = userId;
    
	[[[UIAlertView alloc] initWithTitle:locString(@"Dropbox Session Ended") 
                                message:locString(@"Do you want to relink?") 
                               delegate:self 
                      cancelButtonTitle:locString(@"Cancel") 
                      otherButtonTitles:locString(@"Relink"), nil] show];
}


#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)index 
{
	if (index != alertView.cancelButtonIndex) {
        
		[[DBSession sharedSession] linkUserId:_relinkUserId 
                               fromController:[AppDelegate shared].window.rootViewController];
	}
	_relinkUserId = nil;
}

#pragma mark - DBNetworkRequestDelegate methods

static int outstandingRequests;

- (void)networkRequestStarted {
	outstandingRequests++;
	if (outstandingRequests == 1) {
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	}
}

- (void)networkRequestStopped {
	outstandingRequests--;
	if (outstandingRequests == 0) {
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	}
}

#pragma mark DBRestClientDelegate methods

- (void)restClient:(DBRestClient*)client loadedMetadata:(DBMetadata*)metadata 
{
    if (_tasks.nonEmpty) {
        
        DropboxTaskImpl *task = _tasks.first;
        
        DDLogVerbose(@"dropbox loadedMetadata %@ (%@ %@)", task, metadata.path, metadata.rev);        
        
        if (task.mode == DropboxTaskModeMetadata) {
            
            [self complete:metadata failure:nil];
            
        } else {
            
            task.metadata = metadata;
            [self process];
        }
    }
}

- (void)restClient:(DBRestClient*)client loadMetadataFailedWithError:(NSError*)error 
{   
    if ([error.domain isEqualToString:@"dropbox.com"] && 
        error.code == 404) { // not found
        
        DDLogVerbose(@"dropbox notfound %@", [error.userInfo get:@"path"]);        
        
        if (_tasks.nonEmpty) {
            
            DropboxTaskImpl *task = _tasks.first;

            if (task.mode == DropboxTaskModeDownload) { 
                
                task.mode = DropboxTaskModeCanceled;  
                [self complete:nil failure:nil];
                return;                
            }

            if (task.mode == DropboxTaskModeSync) {
                
                task.mode = DropboxTaskModeUpload; 
            }
            
            task.metadata = [[DBMetadata alloc] init];
            [self process];
            return;
        }
    } 
    
    [self complete:nil failure:error];    
}

- (void)restClient:(DBRestClient*)client 
      uploadedFile:(NSString*)destPath
              from:(NSString*)srcPath 
          metadata:(DBMetadata*)metadata 
{   
    [self syncTime: metadata forPath: srcPath];    
    [self complete: metadata failure:nil];    
    
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error 
{
    [self complete: nil failure:error];    
}

- (void)restClient:(DBRestClient*)client 
        loadedFile:(NSString*)destPath 
       contentType:(NSString*)contentType 
          metadata:(DBMetadata*)metadata
{       
    [self syncTime: metadata forPath: destPath];    
    [self complete: metadata failure:nil];        
}

- (void)restClient:(DBRestClient*)client loadFileFailedWithError:(NSError*)error
{
    [self complete: nil failure:error];
}

- (void)restClient:(DBRestClient*)client loadProgress:(CGFloat)progress forFile:(NSString*)destPath
{
    if (_tasks.nonEmpty) {        
        DropboxTaskImpl *task = _tasks.first;
        if (self.delegate)
            [self.delegate processTask:task progress: progress];
    }
}

- (void)restClient:(DBRestClient*)client uploadProgress:(CGFloat)progress forFile:(NSString*)destPath from:(NSString*)srcPath
{
    if (_tasks.nonEmpty) {        
        DropboxTaskImpl *task = _tasks.first;
        if (self.delegate)
            [self.delegate processTask:task progress: progress];
    }    
}


@end
