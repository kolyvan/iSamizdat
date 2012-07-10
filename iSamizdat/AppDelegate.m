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
#import "FavoritesViewController.h"
#import "VotedViewController.h"
#import "SearchViewController.h"
#import "SettingsViewController.h"
#import "SamLibAgent.h"
#import "SamLibModel.h"
#import "SamLibHistory.h"
#import "SamLibAuthor.h"
#import "SamLibText.h"
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
#import "SHKFacebook.h"
#import "SHKConfiguration.h"
#import "SHKConfig.h"


#if DEBUG
int ddLogLevel = LOG_LEVEL_INFO;
#else
int ddLogLevel = LOG_LEVEL_WARN;
#endif

@interface AppDelegate()

@property (strong, nonatomic) WBErrorNoticeView * errorNotice;
@property (strong, nonatomic) WBSuccessNoticeView * successNotice;
@end

@implementation AppDelegate

@synthesize window = _window;
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

   // [[UINavigationBar appearance] setBarStyle: UIBarStyleBlack];
    
    MainViewController *vc0 = [[MainViewController alloc] init];
    FavoritesViewController *vc1 = [[FavoritesViewController alloc] init];
    VotedViewController *vc2 = [[VotedViewController alloc] init];
    SearchViewController *vc3 = [[SearchViewController alloc] init]; 
    SettingsViewController *vc4 = [[SettingsViewController alloc] init];      
    
    UITabBarController *tabBarContrller = [[UITabBarController alloc] init];
    tabBarContrller.viewControllers = KxUtils.array(
                                                    [[UINavigationController alloc] initWithRootViewController:vc0],
                                                    [[UINavigationController alloc] initWithRootViewController:vc1],
                                                    [[UINavigationController alloc] initWithRootViewController:vc2],
                                                    [[UINavigationController alloc] initWithRootViewController:vc3],                                                    
                                                    [[UINavigationController alloc] initWithRootViewController:vc4],                                                    
                                                    nil);

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];    
    self.window.rootViewController = tabBarContrller;    
    [self.window makeKeyAndVisible];
    
    DefaultSHKConfigurator *configurator = [[SHKConfig alloc] init];
    [SHKConfiguration sharedInstanceWithConfigurator:configurator];
    KX_RELEASE(configurator);
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [[SamLibModel shared] save]; 
    [[SamLibHistory shared] save]; 
    
    if (!SamLibStorage.allowTexts()) {
        DDLogInfo(@"cleanup texts");
        SamLibStorage.cleanupTexts();
    }        
    
    if (!SamLibStorage.allowComments()) {
        DDLogInfo(@"cleanup comments");        
        SamLibStorage.cleanupComments();
    }
    
    if (!SamLibStorage.allowNames()) {
        DDLogInfo(@"cleanup names");                
        SamLibStorage.cleanupNames();
    }
    
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

    for (SamLibAuthor *author in [SamLibModel shared].authors)
        for (SamLibText *text in author.texts)
            [text freeCommentsObject];    
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
}

- (void) closeNotice
{
    [self.successNotice close];
    [self.errorNotice close];    
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

#pragma mark - SSO Facebook support

- (BOOL)handleOpenURL:(NSURL*)url
{
	NSString* scheme = [url scheme];
    if ([scheme hasPrefix:[NSString stringWithFormat:@"fb%@", SHKCONFIG(facebookAppId)]])
        return [SHKFacebook handleOpenURL:url];
    return YES;
}

- (BOOL)application:(UIApplication *)application 
            openURL:(NSURL *)url 
  sourceApplication:(NSString *)sourceApplication 
         annotation:(id)annotation 
{
    return [self handleOpenURL:url];
}

- (BOOL)application:(UIApplication *)application 
      handleOpenURL:(NSURL *)url 
{
    return [self handleOpenURL:url];  
}

@end
