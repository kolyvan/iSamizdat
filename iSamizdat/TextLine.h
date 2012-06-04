//
//  TextLine.h
//  iSamizdat
//
//  Created by Kolyvan on 04.06.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TextLine : NSObject

@property (readwrite, nonatomic) NSString *text;
@property (readwrite, nonatomic) NSString *link;
@property (readonly, nonatomic) CGPoint origin;
@property (readonly, nonatomic) CGSize size;
@property (readonly, nonatomic) CGRect bounds;

- (CGSize) computeSize: (CGFloat) width 
              withFont: (UIFont *) font;

- (CGSize) drawInRect:(CGRect) bounds 
             withFont:(UIFont *) font 
             andColor:(UIColor *) color;
@end
