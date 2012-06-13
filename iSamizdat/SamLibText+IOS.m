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
#import "KxMacros.h"

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
