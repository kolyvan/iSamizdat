//
//  TextLine.m
//  iSamizdat
//
//  Created by Kolyvan on 04.06.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//
//  https://github.com/kolyvan/iSamizdat
//  this file is part of iSamizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt
// 

#import "TextLine.h"
#import "KxArc.h"
#import "NSString+Kolyvan.h"
#import "KxUtils.h"


@interface TextLine() {
    CGSize _size;
    CGFloat _width;    
    KX_WEAK UIFont * _font;
}

@end

@implementation TextLine
@synthesize text, link;
@synthesize origin = _origin;
@synthesize size = _size;

- (CGRect) bounds 
{
    CGRect rc = { _origin, _size };
    return rc;
}

- (CGSize) computeSize: (CGFloat) width 
              withFont: (UIFont *) font
{
    if (_width != width || font != _font) 
    {        
        _font = font;
        _width = width;
        
        if (self.link.nonEmpty)
            _size = [self.text sizeWithFont:font 
                          constrainedToSize:CGSizeMake(width, _font.lineHeight)
                              lineBreakMode:UILineBreakModeMiddleTruncation];
        else
            _size = [self.text sizeWithFont:font 
                          constrainedToSize:CGSizeMake(width, 9999) 
                              lineBreakMode:UILineBreakModeTailTruncation];
    }
    return _size;
}

- (CGSize) drawInRect:(CGRect) bounds 
             withFont:(UIFont *) font
             andColor:(UIColor *) color;
{   
    CGSize sz;
    
    if (color)
        [color set];
    
    if (self.link.nonEmpty) {
        
        bounds.size.height = font.lineHeight;
        
        sz = [self.text drawInRect:bounds
                          withFont:font 
                     lineBreakMode:UILineBreakModeMiddleTruncation];
        
    } else {
        
        sz = [self.text drawInRect:bounds
                          withFont:font 
                     lineBreakMode:UILineBreakModeTailTruncation];
        
    }
    
    _origin = bounds.origin;
    //_size = sz;
    return sz;
}

@end
