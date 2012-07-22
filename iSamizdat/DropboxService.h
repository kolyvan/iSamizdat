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

- (NSString *) modeAsString;
@end

typedef void(^DropboxServiceBlock)(id<DropboxTask> task, NSError *error);

@protocol DropboxServiceDelegate <NSObject>
- (void) willProcessTask: (id<DropboxTask>) task tasksCount: (NSInteger) count;
- (void) didCompleteTask: (id<DropboxTask>) task tasksCount: (NSInteger) count error: (NSError *) error;
- (void) processTask: (id<DropboxTask>) task progress: (CGFloat)progress; 
@end

@interface DropboxService : NSObject

@property (readonly, nonatomic) BOOL isLinked;
@property (readonly, nonatomic) NSUInteger tasksCount;
@property (readwrite, nonatomic) id<DropboxServiceDelegate> delegate;

+ (DropboxService *) shared;

- (BOOL)handleOpenURL:(NSURL*)url;

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
