//
//  SamLibUser.m
//  samlib
//
//  Created by Kolyvan on 10.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//
//  https://github.com/kolyvan/samizdat
//  this file is part of Samizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt


#import "SamLibUser.h"
#import "KxArc.h"
#import "KxMacros.h"
#import "KxUtils.h"
#import "NSDictionary+Kolyvan.h"
#import "NSString+Kolyvan.h"
#import "DDLog.h"
#import "SamLibAgent.h"
#import "SamLibParser.h"
#import "JSONKit.h"

#import "SSKeychain.h"

extern int ddLogLevel;

///

static SamLibUser * gUser = nil;
static NSString * gKeychainService = @"ru.kolyvan.samlib";


@implementation SamLibUser

+  (void) setKeychainService: (NSString *) name
{
    KX_RELEASE(gKeychainService);
    gKeychainService = [name copy];
}

- (NSString *) name
{
    NSDictionary *d = SamLibAgent.settings();
    return [d get: @"user.name" orElse: @""];
}

- (void) setName:(NSString *)name
{
    NSMutableDictionary *d = SamLibAgent.settings();
    [d updateOnly: @"user.name" valueNotNil: name];
}

- (NSString *) login
{
    NSDictionary *d = SamLibAgent.settings();
    return [d get: @"user.login" orElse: @""];
}

- (void) setLogin:(NSString *)login
{
    NSMutableDictionary *d = SamLibAgent.settings();
    [d updateOnly: @"user.login" valueNotNil: login];
}

- (NSString *) pass
{
    NSString *login = self.login;
    NSString *pass = nil;
    
    if (login.nonEmpty) {

        NSError *error = nil;
        pass = [SSKeychain passwordForService:gKeychainService
                                                account:login 
                                                  error:&error];
        if (!pass) {
            
            if (error.code != SSKeychainErrorNotFound) {

                DDLogCWarn(locString(@"keychain failure: %@"), 
                           KxUtils.completeErrorMessage(error));
            }    
        }
    } else {
        DDLogCWarn(locString(@"unable get password: empty login"));        
    }
     
    return pass;
}

- (void) setPass:(NSString *)pass
{    
    NSString *login = self.login;
    if (login.nonEmpty) {
 
        NSError *error = nil;
        if (pass.nonEmpty) {
                        
           // or use KxUtils.appBundleID() for service name?
            if (![SSKeychain setPassword:pass 
                              forService:gKeychainService
                                 account:login
                                   error:&error]) {
                
                DDLogCWarn(locString(@"keychain failure: %@"), 
                           KxUtils.completeErrorMessage(error));
            }
        } else {
        
            [SSKeychain deletePasswordForService:gKeychainService
                                         account:pass];
        
        }
    } else {
    
        DDLogCWarn(locString(@"unable set password: empty login"));
    }

}

- (NSString *) email
{
    NSDictionary *d = SamLibAgent.settings();
    return [d get: @"user.email" orElse: @""];
}

- (void) setEmail:(NSString *)email
{
    NSMutableDictionary *d = SamLibAgent.settings();
    [d updateOnly: @"user.email" valueNotNil: email];    
}

- (NSString *) url
{
    NSDictionary *d = SamLibAgent.settings();
    return [d get: @"user.url" orElse: @""];
}

- (void) setUrl:(NSString *)url
{
    NSMutableDictionary *d = SamLibAgent.settings();
    [d updateOnly: @"user.url" valueNotNil: url];    
}

+ (void) initialize
{    
    if(!gUser) {
        gUser = [[SamLibUser alloc] init];        
    }
}

+ (SamLibUser *) currentUser
{
    return gUser;
}

- (NSString *) homePage
{
    // if (self.isLogin) 
    {     
        NSHTTPCookie *cookie = searchSamLibCookie(@"HOME");
        NSString * s = cookie.value;
        if (s != nil && ![s isEqualToString: @"none"])
            return [SamLibAgent.samlibURL() stringByAppendingPathComponent:s];
    }
    return nil;
}

- (BOOL) isLogin
{
    return [[self->isa loggedUserName] isEqualToString:self.login];
}

+ (NSString *) loggedUserName
{
    NSHTTPCookie *cookie = searchSamLibCookie(@"NAME");
    NSString *name = cookie.value;
    if (!name || [name isEqualToString: @"none"])
        return nil;
    return name;
}

- (void) loginSamizdat:(LoginBlock) block
{
    [self loginSamizdat:self.login pass:self.pass block:block];
}
- (void) loginSamizdat: (NSString *) login 
                  pass: (NSString *) pass 
                 block: (LoginBlock) block;

{
    NSMutableDictionary * d = [NSMutableDictionary dictionary];
    
    [d setValue:@"login" forKey:@"OPERATION"];    
    [d setValue:@"http://samlib.ru/" forKey:@"BACK"];        
    [d setValue:login forKey:@"DATA0"];
    [d setValue:pass forKey:@"DATA1"];    
    
    SamLibAgent.postData(@"/cgi-bin/login", 
                         @"http://samlib.ru/cgi-bin/login", 
                         d, 
                         YES,
                         ^(SamLibStatus status, NSString *data, NSString *_unused){
          
                             if (status == SamLibStatusSuccess &&
                                 !SamLibParser.scanLoginResponse(data)) {
                                 
                                 status = SamLibStatusFailure;
                                 data = nil;              
                             } 
                             
                             block(status, data);
                         });
}

- (void) logoutSamizdat:(LoginBlock) block
{   
    SamLibAgent.postData(@"/cgi-bin/logout", 
                         @"http://samlib.ru/", 
                         nil, 
                         YES,
                         ^(SamLibStatus status, NSString *data, NSString *_unused){
                             
                             if (status == SamLibStatusSuccess &&
                                 !SamLibParser.scanLoginResponse(data)) {
                                 
                                 status = SamLibStatusFailure;
                                 data = nil;              
                             } 
                             
                             block(status, data);
                         });
}

@end
