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
#import "DownloadsViewController.h"
#import "SearchViewController.h"
#import "SettingsViewController.h"
#import "HistoryViewController.h"
#import "TextReadViewController.h"
#import "SamLibAgent.h"
#import "SamLibModel.h"
#import "SamLibHistory.h"
#import "SamLibModerator.h"
#import "SamLibAuthor.h"
#import "SamLibText.h"
#import "SamLibUser.h"
#import "SamLibStorage.h"
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "KxUtils.h"
#import "KxMacros.h"
#import "NSArray+Kolyvan.h"
#import "NSDictionary+Kolyvan.h"
#import "NSString+Kolyvan.h"
#import "WBSuccessNoticeView.h"
#import "WBErrorNoticeView.h"
#import "SHKFacebook.h"
#import "SHKConfiguration.h"
#import "SHKConfig.h"
#import <DropboxSDK/DropboxSDK.h>
#import "DropboxService.h"


#if DEBUG
int ddLogLevel = LOG_LEVEL_INFO;
#else
int ddLogLevel = LOG_LEVEL_WARN;
#endif

@interface AppDelegate() {
}

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
    
    [self checkFirstRun];
    [self checkVersion];
                
    //[[UINavigationBar appearance] setBarStyle: UIBarStyleBlack];
    
    NSArray * controllers = KxUtils.array([[MainViewController alloc] init],                                          
                                          [[FavoritesViewController alloc] init],
                                          [[HistoryViewController alloc] init],
                                          [[SearchViewController alloc] init],
                                          [[VotedViewController alloc] init],                                          
                                          [[DownloadsViewController alloc] init],                                                                                    
                                          [[SettingsViewController alloc] init],                                                                                                                                                                        
                                          nil);
    
    controllers = [self restoreTabBars:controllers];    
    controllers = [controllers = controllers map:^(UIViewController *vc) {
        return [[UINavigationController alloc] initWithRootViewController:vc];       
    }];
    
    UITabBarController *tabBarContrller = [[UITabBarController alloc] init];
    tabBarContrller.viewControllers = controllers;
    tabBarContrller.customizableViewControllers = controllers; 

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];    
    self.window.rootViewController = tabBarContrller;    
    //self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:vc0];        
    //self.window.rootViewController = [[DropboxViewController alloc] init];    
    
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
    [[DropboxService shared] cancelAll];
    
    [[SamLibModel shared] save]; 
    [[SamLibModerator shared] save];
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
    
    [self saveTabBars];
    
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

- (void) checkFirstRun
{
    if (SamLibAgent.settingsBool(@"app.firstRun", YES)) {
        
        SamLibAgent.setSettingsBool(@"app.firstRun", NO, YES);
        
        SamLibModel * model = [SamLibModel shared];
        if (model.authors.count == 0) {
            
            // add defaults authors            
            NSDictionary *dict;
            SamLibAuthor *author;
            
            dict = KxUtils.dictionary(@"Буревой Андрей", @"name",nil);            
            author = [SamLibAuthor fromDictionary:dict withPath:@"burewojandrej"];
            [model addAuthor:author];     
            
            dict = KxUtils.dictionary(@"Колыван", @"name",nil);            
            author = [SamLibAuthor fromDictionary:dict withPath:@"kolywan"];
            [model addAuthor:author];     
            
            dict = KxUtils.dictionary(@"Смирнов Артур", @"name",nil);            
            author = [SamLibAuthor fromDictionary:dict withPath:@"smirnow_artur_sergeewich"];
            [model addAuthor:author];     
            
            dict = KxUtils.dictionary(@"Корнев Павел Николаевич", @"name",nil);            
            author = [SamLibAuthor fromDictionary:dict withPath:@"kornew_p_n"];
            [model addAuthor:author];     
        }
    }
}

- (NSArray *) restoreTabBars: (NSArray *) vcs
{
    NSArray * order = [SamLibAgent.settings() get:@"ui.tabbar"];
    
    if (!order.nonEmpty) 
        return vcs;
       
    for (UIViewController *vc in vcs) {
        
        NSString *klass = NSStringFromClass([vc class]);
        vc.tabBarItem.tag = [order indexOfObject:klass];        
    }
    
    return [vcs sortWith:^(UIViewController *l, UIViewController *r) {      
        NSInteger li = l.tabBarItem.tag;
        NSInteger ri = r.tabBarItem.tag;                
        if (li < ri) return NSOrderedAscending;
        if (li > ri) return NSOrderedDescending;        
        return NSOrderedSame;        
    }];   
}

- (void) saveTabBars
{    
    UITabBarController *tabBarContrller = (UITabBarController *)self.window.rootViewController;
    
    NSMutableArray *ma = [NSMutableArray array];
    
    for (UINavigationController *nav in tabBarContrller.viewControllers) {
    
        // sometimes this is an empty array
        // not best solution but working, it's just to skip
        if (!nav.viewControllers.nonEmpty)
            return; 
        
        UIViewController *rootVC = nav.viewControllers.first;
        [ma push: NSStringFromClass([rootVC class])];
    }
    
    [SamLibAgent.settings() update:@"ui.tabbar" value:ma];
}

- (void) checkVersion
{
    NSInteger currentVersion = [[[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleVersion"] integerValue];
    NSInteger storedVersion = SamLibAgent.settingsInt(@"app.version", 0);
            
    if (storedVersion != currentVersion) {
                        
        SamLibAgent.setSettingsInt(@"app.version", currentVersion, 0);
        
        DDLogInfo(@"upgrade %d -> %d", storedVersion, currentVersion);
        
        ensureTextCSSInCacheFolder(YES);
        
#if 0
        if (storedVersion == 0) {    

            DDLogInfo(@"migrate texts and comments");
            [self migrateFolder: SamLibStorage.textsPath()];
            [self migrateFolder: SamLibStorage.commentsPath()];
            
            DDLogInfo(@"clean history");            
            [[SamLibHistory shared] clearAll];            
        }
#endif
    }
}

- (void) migrateFolder: (NSString *) baseFolder
{    
    SamLibStorage.enumerateFolder(baseFolder, ^(NSFileManager *fm, NSString *fullpath, NSDictionary *attr){

        NSString *folder = [fullpath stringByDeletingLastPathComponent];
        if ([baseFolder isEqualToString:folder]) {
            
            // move            
            NSString *key = [fullpath lastPathComponent];
            
            NSRange r = [key rangeOfString:@"."];
            if (r.location != NSNotFound) {
            
                KxTuple2 *t = [key splitAt:r.location];                
                folder = [folder stringByAppendingPathComponent:t.first];
                KxUtils.ensureDirectory(folder);            
                NSString *fn = t.second;
                NSString *to = [folder stringByAppendingPathComponent: [fn drop:1]];
                [fm moveItemAtPath:fullpath toPath:to error:nil];                            
                //DDLogInfo(@"%@ -> %@", fullpath, to);
            }                      
        }         

    });
}

- (BOOL)handleOpenURL:(NSURL*)url
{   
	NSString* scheme = [url scheme];
    
    if ([scheme hasPrefix:[NSString stringWithFormat:@"fb%@", SHKCONFIG(facebookAppId)]])
        return [SHKFacebook handleOpenURL:url];
    
    if ([scheme hasPrefix:@"db-8jr6tpiiyvlr8jg"]) 
        return [[DropboxService shared] handleOpenURL: url];
    
    return YES;
}

#pragma mark - SSO Facebook support

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

#pragma mark - dropbox

- (void) dropbox
{
    //if (!_dropboxService) {
    //    _dropboxService = [[DropboxService alloc] init];
    //}
    
    //[_dropboxService link];
    
    //DropboxViewController * vc = [[DropboxViewController alloc] init];                
    //[self.window.rootViewController presentViewController:vc animated:YES completion:nil];

}


@end
