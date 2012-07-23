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
#import "KxMacros.h"
#import "KxUtils.h"
#import "NSArray+Kolyvan.h"
#import "NSString+Kolyvan.h"
#import "SamLibStorage.h"
#import "SamLibModel.h"
#import "SamLibText.h"
#import "SamLibAuthor.h"
#import "AppDelegate.h"
#import "DDLog.h"

extern int ddLogLevel;

@interface DropboxViewController () <DropboxServiceDelegate> {
    IBOutlet UIButton *_buttonLink;
    IBOutlet UIButton *_buttonSync;     
    IBOutlet UISwitch *_switchSyncAll;         
    IBOutlet UIActivityIndicatorView *_activityIndicatorView;        
    IBOutlet UIProgressView *_progressView;
    IBOutlet UILabel *_progressLabel;
    IBOutlet UILabel *_countLabel;
    IBOutlet UITextView *_reportView;
    NSMutableArray *_report;
    BOOL _syncPressed; 
}
@end

@implementation DropboxViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _report = [[NSMutableArray alloc] init];
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
                                             selector:@selector(dropboxLinkChanged:)
                                                 name:@"DropboxLinkChanged" 
                                               object:nil];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self refreshUI];
    
    [DropboxService shared].delegate = self;   
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [DropboxService shared].delegate = nil;
        
    BOOL needReloadModel = NO;
    for (id<DropboxTask> task in _report) {
        if (task.mode == DropboxTaskModeDownload && 
            [task.remoteFolder isEqualToString:@"/authors"]) {         
            needReloadModel = YES;
            break;
        }
    }
    
    if (needReloadModel)
        [[SamLibModel shared] reload];
    
    [_report removeAllObjects];    
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

- (void) dropboxLinkChanged: (NSNotification *)notification
{
    if ([DropboxService shared].delegate == self)
        [self refreshUI];
}

- (void) refreshUI
{
    DropboxService *dS = [DropboxService shared];
    
    BOOL isLinked = dS.isLinked;
    
    [_buttonLink setTitle:isLinked ? locString(@"Unlink") : locString(@"Link")
                 forState:UIControlStateNormal];

    _buttonSync.enabled = isLinked;          
    [self refreshProgress: YES task: nil tasksCount:0];
}

- (IBAction) linkDropbox:(id)sender
{   
    [[DropboxService shared] toggleLink: self];        
}

- (IBAction) syncDropbox:(id)sender
{
    DropboxService *dS = [DropboxService shared];
    if (dS.isLinked) {
        
        if (_syncPressed) {
                    
            [dS cancelAll];  
           
            [self refreshProgress: YES task: nil tasksCount:0];
            
        } else {
                    
            [[SamLibModel shared] save];
            
            if (_switchSyncAll.on) {
                
                [self syncAll];
                
            } else {
                
                [self syncAuthors: nil];                
                [self syncTexts: ^(DBMetadata *md) {
                    // only if text exists
                    return (BOOL)([self findObject:md.path] != nil); 
                }];
            }
            
            _syncPressed = !_syncPressed;
            [_buttonSync setTitle:_syncPressed ? locString(@"Cancel") : locString(@"Sync") 
                         forState:UIControlStateNormal];
        }    
        
        
    } else {
    
        NSAssert(false, @"dropbox is not linked");
    }
}

- (void) syncAll
{
    DropboxService *dS = [DropboxService shared];
    
    NSMutableArray *exclude = [NSMutableArray array];
    
    SamLibModel *model = [SamLibModel shared];
    
    for (SamLibAuthor * author in model.authors) {
    
        [dS sync:author.path
           local:SamLibStorage.authorsPath()
          remote:@"/authors"
      completion:nil];
        
        for (SamLibText *text in author.texts) {
         
            if (text.htmlFile.nonEmpty) {
                
                NSString *filename = [[text.path stringByDeletingPathExtension] stringByAppendingPathExtension:@"html"];            
                NSString *localFolder = [SamLibStorage.textsPath() stringByAppendingPathComponent:author.path];
                NSString *remoteFolder = [@"/texts" stringByAppendingPathComponent:author.path];
                
                [exclude addObject:[remoteFolder stringByAppendingPathComponent: filename]];
                
                [dS sync:filename
                   local:localFolder
                  remote:remoteFolder
              completion:nil];
            }
        }
    }

    [self syncAuthors:^BOOL(DBMetadata *md) {       
         // exclude already synced
        return (nil == [model findAuthor:md.filename]);
    }];
    
    [self syncTexts: ^(DBMetadata *md) {
        
        // exclude already synced
        if ([exclude containsObject:md.path])
            return NO;

        // only if text exists        
        return (BOOL)([self findObject:md.path] != nil); 
    }];
}

- (void) syncAuthors: (BOOL(^)(DBMetadata *md)) allowBlock
{
    [self syncFolder:SamLibStorage.authorsPath()
              remote:@"/authors" 
          allowBlock:allowBlock];
}

- (void) syncTexts: (BOOL(^)(DBMetadata *md)) allowBlock
{
    NSFileManager *fm = KxUtils.fileManager();
            
    DropboxService *dS = [DropboxService shared];
    
    [dS loadMetadata:@"" 
              remote:@"/texts" 
          completion:^(id<DropboxTask> task, NSError *error) {
              
              if (error)                 
                  return;
              
              NSArray *contents = [task.metadata.contents filter:^BOOL(DBMetadata *md) {
                  return md.isDirectory && !md.isDeleted;
              }];              
              
              if (contents.isEmpty)
                  return;
              
              for (DBMetadata *md in contents) {
                  
                  NSString *localFolder = [SamLibStorage.textsPath() stringByAppendingPathComponent:md.filename];
                  
                  BOOL isDirectory;
                  BOOL isExists = [fm fileExistsAtPath:localFolder isDirectory:&isDirectory];
                  
                  if (isExists && !isDirectory) { // skip files                      
                      
                  } else {
                      
                      if ([self findObject:md.path]) { // if author exsits
                                               
                          [self syncFolder: localFolder
                                    remote: md.path 
                                allowBlock: allowBlock]; 
                      }
                  }
              }
          }];
}

- (void) syncFolder: (NSString *) localFolder 
             remote: (NSString *) remoteFolder 
         allowBlock: (BOOL(^)(DBMetadata *md)) allowBlock
{    
    DropboxService *dS = [DropboxService shared];
    
    [dS loadMetadata:@"" 
              remote:remoteFolder
          completion:^(id<DropboxTask> task, NSError *error) {
              
              if (error)
                  return;
              
              NSArray *contents = [task.metadata.contents filterNot:^BOOL(DBMetadata *md) {
                  return md.isDirectory || md.isDeleted;
              }];              
              
              if (contents.isEmpty) 
                  return;
                                                        
              KxUtils.ensureDirectory(localFolder);
              
              for (DBMetadata *md in contents) {

                  if (!allowBlock || allowBlock(md)) {
                  
                      [dS sync:md.path.lastPathComponent
                         local:localFolder
                        remote:remoteFolder
                    completion:nil];
                  }
              }              
          }];
}

- (void) refreshProgress: (BOOL) complete 
                    task: (id<DropboxTask>) task 
              tasksCount: (NSInteger) count
{    
    if (complete && task) {
        
        if (task.mode == DropboxTaskModeDownload ||
            task.mode == DropboxTaskModeUpload) {
            
            [_report addObject:task];
        }
    }
    
    _progressLabel.text = complete ? @"" : 
        KxUtils.format(@"%@ %@ > %@", task.modeAsString, task.filename, task.remoteFolder);
    
    NSMutableString *ms = [NSMutableString  string];    
    NSArray *tasks = _report.reverse;    
    for (id<DropboxTask> task in tasks)
        [ms appendFormat:@"%@ %@ > %@\n", task.modeAsString, task.filename, task.remoteFolder];  

    _reportView.text = ms;
    _progressView.progress = 0;
    _progressView.hidden = complete;    
       
    if (count) {
        
        _countLabel.text = KxUtils.format(@"%d", count);
        
        if (!_activityIndicatorView.isAnimating)
            [_activityIndicatorView startAnimating];
        
    } else {

        _countLabel.text = @"";        
        [_activityIndicatorView stopAnimating];
        
        _syncPressed = NO;
        [_buttonSync setTitle:_syncPressed ? locString(@"Cancel") : locString(@"Sync") 
                     forState:UIControlStateNormal];
    }
}

- (id) findObject: (NSString *)path
{   
    id found = nil;
    NSArray *components = [path pathComponents];    
    
    if (components.count > 2) {
        
        if ([components.first isEqualToString:@"/"]) {
        
            components = components.tail;
            NSString *author = [components objectAtIndex:1];            
                        
            if (components.count == 2) {
            
                found = [[SamLibModel shared] findAuthor:author];
                
            } else if (components.count == 3) {
            
                NSString *text = [[components objectAtIndex:2] stringByDeletingPathExtension];                
                found = [[SamLibModel shared] findTextByKey:KxUtils.format(@"%@/%@", author, text)];                        
            }
        }
    }

    return found;
}

#pragma mark - dropbox service

- (void) willProcessTask: (id<DropboxTask>) task tasksCount: (NSInteger) count
{   
    [self refreshProgress: NO task: task tasksCount: count];    
    
}

- (void) didCompleteTask: (id<DropboxTask>) task tasksCount: (NSInteger) count error: (NSError *) error
{ 
    if (error) {                    
        [[AppDelegate shared] errorNoticeInView:self.view 
                                          title:@"Dropbox failure" 
                                        message:KxUtils.completeErrorMessage(error)];
    }
    
    [self refreshProgress: YES task: task tasksCount: count];    
}

- (void) processTask: (id<DropboxTask>) task progress: (CGFloat)progress
{
    _progressView.progress = progress;
}


@end
