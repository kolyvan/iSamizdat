//
//  AppDelegate.m
//  iSamizdat
//
//  Created by Kolyvan on 28.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//
//  https://github.com/kolyvan/iSamizdat
//  this file is part of iSamizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt
// 

#import "AppDelegate.h"
#import "MainViewController.h"
#import "SamLibAgent.h"
#import "SamLibModel.h"
#import "SamLibAuthor.h"
#import "SamLibUser.h"
#import "SamLibStorage.h"
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "KxUtils.h"
#import "KxMacros.h"
#import "NSDictionary+Kolyvan.h"
#import "NSString+Kolyvan.h"
#import "WBSuccessNoticeView.h"
#import "WBErrorNoticeView.h"

#if DEBUG
int ddLogLevel = LOG_LEVEL_INFO;
#else
int ddLogLevel = LOG_LEVEL_WARN;
#endif

@interface AppDelegate()

@property (strong, nonatomic) UINavigationController *navigationController;
@property (strong, nonatomic) WBErrorNoticeView * errorNotice;
@property (strong, nonatomic) WBSuccessNoticeView * successNotice;
@end

@implementation AppDelegate

@synthesize window = _window;
@synthesize navigationController;
@synthesize errorNotice;
@synthesize successNotice;

+ (AppDelegate *) shared
{
    return [UIApplication sharedApplication].delegate;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self initLogger];
    
    if (SamLibAgent.settingsBool(@"user.enableAccount", NO)) {
        DDLogInfo(@"restore SamLib session cookies");
        restoreSamLibSessionCookies();
    }
    
    DDLogInfo(@"logged as %@", [SamLibUser loggedUserName]);
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    MainViewController *viewController = [[MainViewController alloc] init];
    self.navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    self.window.rootViewController = self.navigationController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [[SamLibModel shared] save]; 
    
    if (!SamLibStorage.allowTexts())
        SamLibStorage.cleanupTexts();
    
    if (!SamLibStorage.allowComments())
        SamLibStorage.cleanupComments();
    
    if (!SamLibStorage.allowNames())
        SamLibStorage.cleanupNames();
    
    SamLibAgent.saveSettings();
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    SamLibAgent.cleanup();
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
    self.errorNotice = nil;
    self.successNotice = nil;
    
    // todo: free comments objects in samlibtext
}

- (void) initLogger
{
#ifdef DEBUG
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
#else
    // todo: file logger
#endif    
    
    DDLogInfo(@"%@ started", [NSBundle mainBundle].bundleIdentifier);
}


- (void) errorNoticeInView:(UIView *) view
                     title:(NSString *) title
                   message:(NSString *) message
{
    if (!self.errorNotice)
        self.errorNotice =  [[WBErrorNoticeView alloc] init];
    
    self.errorNotice.view = view;
    self.errorNotice.title = title;
    self.errorNotice.message = message;
    
    [self.errorNotice show];
}

- (void) successNoticeInView:(UIView *) view
                       title:(NSString *) title
{    
    if (!self.successNotice)
        self.successNotice =  [[WBSuccessNoticeView alloc] init];
    
    self.successNotice.view = view;
    self.successNotice.title = title;
    
    [self.successNotice show];
    
    //[[WBSuccessNoticeView successNoticeInView:view title:title] show];
}

- (void) clearCookies
{
    DDLogInfo(@"clear cookies");    
    storeSamLibSessionCookies(NO);
    deleteSamLibCookie(@"COMMENT");
    deleteSamLibCookie(@"ZUI");    
    deleteSamLibCookie(@"NAME");
    deleteSamLibCookie(@"PASSWORD");                    
    deleteSamLibCookie(@"HOME");     
}

- (void) checkLogin
{
    SamLibUser *user = [SamLibUser currentUser];
    
    BOOL enableAccount = SamLibAgent.settingsBool(@"user.enableAccount", NO);
           
    if (enableAccount) {
        
        if (!user.isLogin) {
            
            [self clearCookies];          
            
            NSString *login = user.login;
            NSString *password = user.pass;
            
            if (login.nonEmpty && password.nonEmpty) {
                
                DDLogInfo(@"attempt to log in as %@", login);
                
                // login and save cookies            
                
                [user loginSamizdat:login
                               pass:password
                              block:^(SamLibStatus status, NSString *error){
                                  
                                  NSString *title;
                                  NSString *message;
                                  
                                  if (SamLibStatusSuccess == status) {
                                      
                                      storeSamLibSessionCookies(YES);
                                      
                                      title = locString(@"login success");
                                      message = KxUtils.format(locString(@"logged as %@"), login);
                                      
                                  } else {
                                      
                                      title = locString(@"login failure");
                                      message = locString(@"invalid name or password");
                                  }
                                  
                                  
                                  UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                                                      message:message
                                                                                     delegate:nil 
                                                                            cancelButtonTitle:locString(@"Ok") 
                                                                            otherButtonTitles:nil];
                                  
                                  [alertView show];
                                  
                              }];
            }
        }
        
    } else {
        
        // logout and clear cookies
              
        /*
        if (user.isLogin) {                        
            
            DDLogInfo(@"attempt to log out");            
            [user logoutSamizdat:^(SamLibStatus status, NSString *error) {
                
                NSString *title;
                NSString *message;
                
                if (SamLibStatusSuccess == status) {
                    
                    title = locString(@"logout success");
                    message = nil;
                    
                } else {
                    
                    title = locString(@"logout failure"); 
                    message = error.nonEmpty ? error : locString(@"unknown error");                                                           
                }
                
                
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                                    message:message
                                                                   delegate:nil 
                                                          cancelButtonTitle:locString(@"Ok") 
                                                          otherButtonTitles:nil];
                
                [alertView show];
               
            }]; 
        }
        */ 
        
        if ([SamLibUser loggedUserName] != nil) {
            [self clearCookies];
        }
        
    }    
        
}

@end
