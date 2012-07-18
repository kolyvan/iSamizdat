//
//  SamLibText+IOS.h
//  iSamizdat
//
//  Created by Kolyvan on 30.05.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//
//  https://github.com/kolyvan/iSamizdat
//  this file is part of iSamizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt
// 


#import "SamLibText.h"

@interface SamLibText (IOS)

@property (nonatomic, readonly) BOOL hasUpdates;

@property (nonatomic, readonly) UIImage * favoritedImage;
@property (nonatomic, readonly) UIImage * imageFlagNew;
@property (nonatomic, readonly) UIImage * image;

@property (nonatomic, readonly) NSString * myVoteAsString;

+ (NSString *) stringForVote: (NSInteger) vote;

@end
