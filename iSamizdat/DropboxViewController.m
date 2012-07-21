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
#import "SamLibStorage.h"
#import "SamLibModel.h"
#import "AppDelegate.h"
#import "DDLog.h"

extern int ddLogLevel;

@interface DropboxViewController () {
    IBOutlet UIButton *_buttonLink;
    IBOutlet UIButton *_buttonSync;    
    IBOutlet UIProgressView *_progressView;        
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
}

- (IBAction) linkDropbox:(id)sender
{   
    [[DropboxService shared] toggleLink: self];        
}

- (IBAction) syncDropbox:(id)sender
{
    DropboxService *dS = [DropboxService shared];
    if (dS.isLinked) {
        
        [self syncAuthors];        
        
    } else {
    
        DDLogWarn(@"dropbox is not linked!!!");
    }
}

- (void) syncAuthors
{
    _label.hidden = NO;
    _progressView.hidden = NO;
    _label.text = @"sync authors";
    _progressView.progress = 0;
    
    [[SamLibModel shared] save];
    
    DropboxService *dS = [DropboxService shared];
    
    [dS loadMetadata:@"" 
              remote:@"/authors" 
          completion:^(id<DropboxTask> task, NSError *error) {
              
              if (error) {
                  
                  [[AppDelegate shared] errorNoticeInView:self.view 
                                                      title:@"Dropbox failure" 
                                                  message:KxUtils.completeErrorMessage(error)];

                  
                  return;
              }
                            
              __block NSInteger counter = task.metadata.contents.count;
              __block NSInteger download = 0, upload = 0;
              CGFloat deltaProgress = 1.0 / counter;             
              
              //DDLogInfo(@"dropbox finished %@ =%d", task, counter);              
              
              for (DBMetadata *md in task.metadata.contents) {
                  
                  //DDLogInfo(@"dropbox sync %@ (%@)", md.path, md.rev);
                  
                  [dS sync:md.filename
                     local:SamLibStorage.authorsPath()
                    remote:@"/authors"  
                completion:^(id<DropboxTask> task, NSError *error){
                    
                    --counter;
                    
                    if (error)
                        return;
                    
                    if (task.mode == DropboxTaskModeDownload)
                        ++download;
                    else if (task.mode == DropboxTaskModeUpload)
                        ++upload;
                    
                    _label.text = [self messageForTask: task];
                    _progressView.progress += deltaProgress;
                    
                    if (0 == counter) {
                        
                        if (download)                            
                            [[SamLibModel shared] reload];
                                                
                        if (download || upload) {
                            
                            NSString *msg = KxUtils.format(@"Dropbox synced %d/%d", download, upload);
                            [[AppDelegate shared] successNoticeInView:self.view 
                                                                title:msg];                            
                        }
                        
                        _progressView.hidden = YES;
                        _label.hidden = YES;
                    }
                }];
              }              
          }];
}


- (NSString *) messageForTask: (id<DropboxTask>) task
{
    NSString *mode;
    
    switch (task.mode) {
        case DropboxTaskModeDownload:   mode = @"download"; break;
        case DropboxTaskModeUpload:     mode = @"upload"; break;
        case DropboxTaskModeSync:       mode = @"synced"; break;
        case DropboxTaskModeCanceled:   mode = @"canceled"; break;
        case DropboxTaskModeMetadata:   mode = @"query"; break;                        
    }
    
    return KxUtils.format(@"%@ %@", mode, task.filename);
}

@end
