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
#import "NSString+Kolyvan.h"
#import "KxMacros.h"

@implementation SamLibText (IOS)

- (BOOL) hasUpdates
{
    return self.changedSize || (self.isNew && self.flagNew != nil);
}

- (UIImage *) favoritedImage
{
    return [UIImage imageNamed: self.favorited ? @"favorite.png" : @"favorite-off.png"];        
}

- (UIImage *) imageFlagNew
{
    if ([self.flagNew isEqualToString:@"red"])         
        return [UIImage imageNamed:@"new-red.png"];        
    
    if ([self.flagNew isEqualToString:@"brown"])
        return [UIImage imageNamed:@"new-brown.png"];        
    
    if ([self.flagNew isEqualToString:@"gray"])
        return [UIImage imageNamed:@"new-gray.png"];  
    
    return nil;
}

- (UIImage *) image
{   
    if (self.isRemoved) 
        return [UIImage imageNamed:@"trash.png"];     
    
    if (self.changedSize)
        return [UIImage imageNamed:@"success.png"];
        
    if (self.changedComments)        
        return [UIImage imageNamed:@"comment.png"];     
    
    if (self.favorited)
        return [UIImage imageNamed: @"favorite.png"];        
        
    if (self.flagNew.nonEmpty)                        
        return [self imageFlagNew];
            
    return [UIImage imageNamed: @"favorite-off.png"];
}

- (NSString *) myVoteAsString
{        
    return [self->isa stringForVote:self.myVote];
}

+ (NSString *) stringForVote: (NSInteger) vote
{   
    static NSString * voteNames[11] = {
        @"none",
        @"must not read",
        @"very bad",
        @"bad",
        @"mediocre",
        @"nothing",
        @"normally",
        @"good",
        @"very good", 
        @"great", 
        @"masterwork",
    };
    
    if (vote >= 0 && vote < 11)
        return locString(voteNames[vote]);    
    return nil;

}

@end
