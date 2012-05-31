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

- (BOOL) hasChangedSize
{
    NSMutableDictionary * dict = [self extra];
    return [dict contains:@"hasChanged"];    
}

- (void) setHasChangedSize:(BOOL)hasChanged
{
    NSMutableDictionary * dict = [self extra];
    if (hasChanged)
        [dict update:@"hasChanged" value:[NSNull null]];
    else
        [dict removeObjectForKey:@"hasChanged"];
}

- (NSString *) shortName
{
    return [self.name split].first;
}

@end
