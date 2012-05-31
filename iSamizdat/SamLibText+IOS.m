//
//  SamLibText+IOS.m
//  iSamizdat
//
//  Created by Kolyvan on 30.05.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//
//  https://github.com/kolyvan/iSamizdat
//  this file is part of iSamizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt
// 

#import "SamLibText+IOS.h"
#import "NSDictionary+Kolyvan.h"

@implementation SamLibText (IOS)

- (UIImage *) favoritedImage
{
    return [UIImage imageNamed: self.favorited ? @"favorite.png" : @"favorite-off.png"];        
}

- (UIImage *) image
{
    // todo: new and removed
    
    if (self.changedSize) {
        
        return [UIImage imageNamed:@"size_changed.png"];
        
    } else if (self.changedComments) {
        
        return [UIImage imageNamed:@"comment.png"];     
        
    } else {
        
        return self.favoritedImage;
    }
}

- (CGFloat) htmlOffset
{
    NSDictionary* dict = [SamLibAgent.settings() get: @"htmlOffset"];    
    return [[dict get:self.key] floatValue];    
}

- (void) setHtmlOffset:(CGFloat)offset
{
    NSMutableDictionary * dict = [SamLibAgent.settings() get: @"htmlOffset" 
                                                       orSet:^id{
                                                           return [NSMutableDictionary dictionary];
                                                       }];
    
    CGFloat old = [[dict get:self.key] floatValue]; 
    
    if (old != offset) {
        //++_version;
        if (offset > 0)
            [dict update:self.key value:[NSNumber numberWithFloat:offset]];
        else
            [dict removeObjectForKey:self.key];
    }
}

@end
