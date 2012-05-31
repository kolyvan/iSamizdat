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
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "KxUtils.h"
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

@end
