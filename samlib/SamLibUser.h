//
//  SamLibUser.h
//  samlib
//
//  Created by Kolyvan on 10.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//
//  https://github.com/kolyvan/samizdat
//  this file is part of Samizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt


#import <Foundation/Foundation.h>
#import "SamLib.h"

typedef void (^LoginBlock)(SamLibStatus status, NSString *error);

@interface SamLibUser : NSObject

+  (void) setKeychainService: (NSString *) name;

- (NSString *) name;
- (void) setName:(NSString *)name;
- (NSString *) login;
- (void) setLogin:(NSString *)login;
- (NSString *) pass;
- (void) setPass:(NSString *)pass;
- (NSString *) email;
- (void) setEmail:(NSString *)email;
- (NSString *) url;
- (void) setUrl:(NSString *)url;
- (NSString *) homePage;
- (BOOL) isLogin;

+ (NSString *) loggedUserName;
+ (SamLibUser *) currentUser;

- (void) loginSamizdat: (NSString *) login 
                  pass: (NSString *) pass 
                 block: (LoginBlock) block;

- (void) loginSamizdat: (LoginBlock) block;
- (void) logoutSamizdat: (LoginBlock) block;;


@end
