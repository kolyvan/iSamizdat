//
//  SamLibComment+IOS.h
//  iSamizdat
//
//  Created by Kolyvan on 04.06.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//
//  https://github.com/kolyvan/iSamizdat
//  this file is part of iSamizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt
// 

#import "SamLibComments.h"

@class TextLine;

@interface SamLibComment (IOS)

- (NSArray *) messageLines;
- (NSArray *) replytoLines;
- (TextLine *) nameLine;
- (UIColor *) nameColor;

@end
