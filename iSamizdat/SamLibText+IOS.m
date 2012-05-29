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

@implementation SamLibText (IOS)

- (UIImage *) favoritedImage
{
    return [UIImage imageNamed: self.favorited ? @"favorite.png" : @"favorite-off.png"];        
}

@end
