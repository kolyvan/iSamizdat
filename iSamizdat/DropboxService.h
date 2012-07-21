//
//  DropboxService.h
//  iSamizdat
//
//  Created by Kolyvan on 20.07.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {

    DropboxTaskModeCanceled,    
    DropboxTaskModeUpload,
    DropboxTaskModeDownload,    
    DropboxTaskModeSync,  
    DropboxTaskModeMetadata,      
    
} DropboxTaskMode;

@class DBMetadata;

@protocol DropboxTask
@property (readonly) DropboxTaskMode mode;
@property (readonly, strong) NSString *filename;
@property (readonly, strong) NSString *localFolder;
@property (readonly, strong) NSString *remoteFolder;
@property (readonly, strong) DBMetadata *metadata;
@end

typedef void(^DropboxServiceBlock)(id<DropboxTask> task, NSError *error);

@interface DropboxService : NSObject

+ (DropboxService *) shared;

- (BOOL)handleOpenURL:(NSURL*)url;

@property (readonly, nonatomic) BOOL isLinked;

- (void) toggleLink: (UIViewController *) vc;
- (void) link: (UIViewController *) vc;

- (void) upload: (NSString *) filename  
          local: (NSString *) localFolder 
         remote: (NSString *) remoteFolder 
     completion: (DropboxServiceBlock) completion;

- (void) download: (NSString *) filename  
            local: (NSString *) localFolder 
           remote: (NSString *) remoteFolder 
       completion: (DropboxServiceBlock) completion;

- (void) sync: (NSString *) filename  
        local: (NSString *) localFolder 
       remote: (NSString *) remoteFolder 
   completion: (DropboxServiceBlock) completion;

- (void) loadMetadata: (NSString *) filename  
               remote: (NSString *) remoteFolder 
           completion: (DropboxServiceBlock) completion;

- (void) cancelAll;

@end
