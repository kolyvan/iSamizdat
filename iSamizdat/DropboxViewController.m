//
//  DropboxViewController.m
//  iSamizdat
//
//  Created by Kolyvan on 20.07.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//

#import "DropboxViewController.h"
#import <DropboxSDK/DropboxSDK.h>
#import "DropboxService.h"
#import "KxUtils.h"
#import "NSArray+Kolyvan.h"
#import "SamLibStorage.h"
#import "SamLibModel.h"
#import "AppDelegate.h"
#import "DDLog.h"

extern int ddLogLevel;

typedef void(^DropboxSyncResultBlock)(NSInteger downloads, NSInteger uploads, NSInteger errors, NSError *error);

@interface DropboxViewController () {
    IBOutlet UIButton *_buttonLink;
    IBOutlet UIButton *_buttonSync;    
    IBOutlet UIActivityIndicatorView *_activityIndicatorView;        
    IBOutlet UILabel *_label;
}
@end

@implementation DropboxViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
        
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dropboxLinkChangeChanged:)
                                                 name:@"DropboxLinkChangeChanged" 
                                               object:nil];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self refreshUI];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) dropboxLinkChangeChanged: (NSNotification *)notification
{
    [self refreshUI];
}

- (void) refreshUI
{
    DropboxService *dS = [DropboxService shared];
    
    BOOL isLinked = dS.isLinked;
    
    [_buttonLink setTitle:isLinked ? @"Unlink" : @"Link"
                 forState:UIControlStateNormal];
    
    _buttonSync.enabled = isLinked;    
    _label.text = @"";
}

- (IBAction) linkDropbox:(id)sender
{   
    [[DropboxService shared] toggleLink: self];        
}

- (IBAction) syncDropbox:(id)sender
{
    DropboxService *dS = [DropboxService shared];
    if (dS.isLinked) {

        _label.text = @"sync ...";
        [_activityIndicatorView startAnimating];
                              
        [self syncAuthors: ^(NSInteger authorsDown, NSInteger authorsUp, NSInteger authorsErrs, NSError *authorError){
                    
            if (authorsDown)
                 [[SamLibModel shared] reload];
            
            [self syncTexts:  ^(NSInteger textsDown, NSInteger textsUp, NSInteger texstErrs, NSError *textError){
                
                
                _label.text = KxUtils.format(@"Authors loaded: %d upload: %d errors: %d\n"
                                             @"Texts   loaded: %d upload: %d errors: %d"
                                             ,authorsDown, authorsUp, authorsErrs,
                                             textsDown, textsUp, texstErrs);    
                
                NSError *error = authorError ? authorError : textError;
                if (error) {                    
                    [[AppDelegate shared] errorNoticeInView:self.view 
                                                      title:@"Dropbox failure" 
                                                    message:KxUtils.completeErrorMessage(error)];
                } 

                [_activityIndicatorView stopAnimating];
                
            }];
        }];
        
    } else {
    
        NSAssert(false, @"dropbox is not linked");
    }
}

- (void) syncAuthors: (DropboxSyncResultBlock) block
{
    [[SamLibModel shared] save];
    
    [self syncFolder:SamLibStorage.authorsPath()
              remote:@"/authors" 
               block:block];
}

- (void) syncTexts: (DropboxSyncResultBlock) block
{
    NSFileManager *fm = KxUtils.fileManager();
            
    DropboxService *dS = [DropboxService shared];
    
    [dS loadMetadata:@"" 
              remote:@"/texts" 
          completion:^(id<DropboxTask> task, NSError *lastError) {
              
              if (lastError) {                                    
                  block(0, 0, 1, lastError); 
                  return;
              }
              
              NSArray *contents = [task.metadata.contents filter:^BOOL(DBMetadata *md) {
                  return md.isDirectory && !md.isDeleted;
              }];              
              
              if (contents.isEmpty) {                      
                  block(0, 0, 0, nil); 
                  return;
              }
              
              __block NSInteger counter = contents.count;
              __block NSInteger numd = 0, numu = 0, nume = 0;              
              
              for (DBMetadata *md in contents) {
                  
                  NSString *localFolder = [SamLibStorage.textsPath() stringByAppendingPathComponent:md.filename];
                  
                  BOOL isDirectory;
                  BOOL isExists = [fm fileExistsAtPath:localFolder isDirectory:&isDirectory];
                  
                  if (isExists && !isDirectory) { // skip files
                      
                      if (0 == --counter)                         
                          block(numd, numu, nume, nil);
                      
                  } else {
                      
                      [self syncFolder: localFolder
                                remote: md.path 
                                 block:^(NSInteger downloads, NSInteger uploads, NSInteger errors, NSError *error) {
                                     
                                     numd += downloads;
                                     numu += uploads;
                                     nume += errors;
                                     
                                     if (0 == --counter)
                                         block(numd, numu, nume, nil);
                                 }];
                  }
              }
          }];
}

- (void) syncFolder: (NSString *) localFolder 
             remote: (NSString *) remoteFolder 
              block: (DropboxSyncResultBlock) block
{    
    DropboxService *dS = [DropboxService shared];
    
    [dS loadMetadata:@"" 
              remote:remoteFolder
          completion:^(id<DropboxTask> task, NSError *error) {
              
              if (error) {   
                  if (block)
                      block(0,0,1,error);                  
                  return;
              }
              
              NSArray *contents = [task.metadata.contents filterNot:^BOOL(DBMetadata *md) {
                  return md.isDirectory || md.isDeleted;
              }];              
              
              if (contents.isEmpty) {
                  if (block)
                      block(0,0,0,nil); 
                  return;
              }
              
              __block NSInteger counter = contents.count;
              __block NSInteger downloads = 0, uploads = 0, errors = 0;
              
              KxUtils.ensureDirectory(localFolder);
              
              for (DBMetadata *md in contents) {
                  
                  [dS sync:md.path.lastPathComponent
                     local:localFolder
                    remote:remoteFolder
                completion:^(id<DropboxTask> task, NSError *error){
                    
                    --counter;
                    
                    if (error) {
                        
                        ++errors;
                        
                    } else {
                        
                        if (task.mode == DropboxTaskModeDownload)
                            ++downloads;
                        else if (task.mode == DropboxTaskModeUpload)
                            ++uploads;
                        
                    }
                    
                  _label.text = [self messageForTask: task];                    
                                    
                    if (0 == counter) {
                        
                        if (block)
                            block(downloads,uploads,errors,nil);  
                    }
                }];
              }              
          }];
}

- (NSString *) messageForTask: (id<DropboxTask>) task
{
    NSString *mode;
    
    switch (task.mode) {
        case DropboxTaskModeDownload:   mode = @"<<<"; break;
        case DropboxTaskModeUpload:     mode = @">>>"; break;
        case DropboxTaskModeSync:       mode = @"<->"; break;
        case DropboxTaskModeCanceled:   mode = @">-< "; break;
        case DropboxTaskModeMetadata:   mode = @" ? "; break;                        
    }
    
    return KxUtils.format(@"%@ %@ %@", task.filename, mode,  task.remoteFolder);
}

@end
