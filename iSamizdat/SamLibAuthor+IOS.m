//
//  SamLibAuthor+IOS.m
//  iSamizdat
//
//  Created by Kolyvan on 29.05.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//

#import "SamLibAuthor+IOS.h"
#import <objc/runtime.h>
#import "NSDictionary+Kolyvan.h"

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



@end
