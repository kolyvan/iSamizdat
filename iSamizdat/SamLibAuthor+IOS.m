//
//  SamLibAuthor+IOS.m
//  iSamizdat
//
//  Created by Kolyvan on 29.05.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//
//  https://github.com/kolyvan/iSamizdat
//  this file is part of iSamizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt
// 

#import "SamLibAuthor+IOS.h"
#import <objc/runtime.h>
#import "NSDictionary+Kolyvan.h"
#import "NSString+Kolyvan.h"
#import "NSArray+Kolyvan.h"
#import "SamLibText.h"
#import "SamLibText+IOS.h"
#import "SamLibStorage.h"

@implementation SamLibAuthor (IOS)

static char gKey;

- (NSMutableDictionary *) extra
{   
    NSMutableDictionary * dict = objc_getAssociatedObject(self, &gKey);
    
    if (!dict) {
        
        dict = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, 
                                 &gKey,
                                 dict,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    return dict;
}

- (NSString *) lastError
{
    NSMutableDictionary * dict = [self extra];
    return [dict get:@"lastError"];    
}

- (void) setLastError:(NSString *)lastError
{
    NSMutableDictionary * dict = [self extra];
    if (lastError)
        [dict update:@"lastError" value:lastError];
    else
        [dict removeObjectForKey:@"lastError"];
}

- (BOOL) hasUpdatedText
{
    for (SamLibText *text in self.texts)
        if (text.hasUpdates)
            return YES;
    return NO;
}

- (NSString *) shortName
{
    return [self.name split].first;
}

- (NSString *) filePath
{
    return [SamLibStorage.authorsPath() stringByAppendingPathComponent:self.path];
}

@end
