//
//  SamLibComment+IOS.h
//  iSamizdat
//
//  Created by Kolyvan on 04.06.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//

#import "SamLibComments.h"

@class TextLine;

@interface SamLibComment (IOS)

- (NSArray *) messageLines;
- (NSArray *) replytoLines;
- (TextLine *) nameLine;
- (UIColor *) nameColor;

@end
