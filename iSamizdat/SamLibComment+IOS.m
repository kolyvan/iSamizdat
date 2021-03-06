//
//  SamLibComment+IOS.m
//  iSamizdat
//
//  Created by Kolyvan on 04.06.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//
//  https://github.com/kolyvan/iSamizdat
//  this file is part of iSamizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt
// 

#import "SamLibComment+IOS.h"
#import <objc/runtime.h>
#import "NSDictionary+Kolyvan.h"
#import "NSString+Kolyvan.h"
#import "NSArray+Kolyvan.h"
#import "KxUtils.h"
#import "TextLine.h"
#import "UIColor+Kolyvan.h"

@implementation SamLibComment (IOS)

static char gKey;

+ (NSString *) shortLink: (NSString *)link 
{
    if ([link hasPrefix:@"http://"])
        link = [link drop:7];
    else if ([link hasPrefix:@"https://"])
        link = [link drop:8];
    else if ([link hasPrefix:@"mailto://"])
        link = [link drop:9];
    
    if ([link hasPrefix:@"www."])
        link = [link drop:4];    
    
    if ([link hasSuffix:@"/"])
        link = link.butlast;
    
    return link;  
}

+ (void) scanLine: (NSString *) line 
        intoArray: (NSMutableArray *) buffer 
       storeLinks: (BOOL) storeLinks
{
    NSScanner *scanner = [NSScanner scannerWithString:line];
    
    // <noindex><a href=http://samlib.ru/ rel=nofollow>http://samlib.ru/</a></noindex>
    
    while (!scanner.isAtEnd) {
        
        NSString *s;
        
        if ([scanner scanString:@"<noindex><a href=" intoString:nil])
        {
            if ([scanner scanUpToString:@">" intoString:nil] &&
                [scanner scanUpToString:@"</a></noindex>" intoString:&s]) {
                
                TextLine * textLine = [[TextLine alloc] init];
                
                NSString *link = [s drop:1]; // drop >                                
                if (storeLinks)
                    textLine.link = link; 
                textLine.text = [self shortLink:link];
                [buffer push:textLine];
            }
        }
        else {
            
            if ([scanner scanUpToString:@"<noindex><a href=" intoString:&s]) {
                
                TextLine * textLine = [[TextLine alloc] init];                
                textLine.text = [s removeHTML];
                [buffer push:textLine];
            }
        }
    }
}

+ (NSArray *) stringToLines: (NSString *) string storeLinks: (BOOL) storeLinks
{    
    NSArray *lines = [string lines];    
    NSMutableArray * result = [NSMutableArray arrayWithCapacity:lines.count];
    for (NSString * line in lines) {
        
        
        if ([line hasPrefix:@"> "]) {
            
            TextLine * textLine = [[TextLine alloc] init];                
            textLine.text = [line removeHTML];
            textLine.isQuote = YES;
            [result push: textLine];
            
        } else {
        
            [self scanLine: line 
                 intoArray:result 
                storeLinks:storeLinks];        
        }
    }
    
    return result;
}

- (NSMutableDictionary *) extDict
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

- (NSArray *) messageLines
{
    NSMutableDictionary * dict = [self extDict];
    return [dict get:@"message" orSet:^id{            
        return [self->isa stringToLines: self.message storeLinks: YES];
    }];    
}


- (TextLine *) nameLine
{   
    NSMutableDictionary * dict = [self extDict];
    return [dict get:@"name" orSet:^id{  
        
        TextLine * textLine = [[TextLine alloc] init];
        
        textLine.link = self.link; 
        
        if (self.isSamizdat)
            textLine.text = KxUtils.format(@"%@*", self.name);
        else
            textLine.text = self.name;
        
        return textLine;
    }];
}

- (UIColor *) nameColor
{
    NSString *color = self.color;
    
    if ([color isEqualToString:@"red"]) 
        return [UIColor redColor];
    if ([color isEqualToString:@"brown"]) 
        return [UIColor brownColor];    
    if (self.link.nonEmpty) {
        
        //static UIColor *customBlue;
        //if (!customBlue)
        //    customBlue = [UIColor colorWithRed:0.192 green:0.376 blue:0.749 alpha:1];        
        //return customBlue; 
        return [UIColor altBlueColor];
    }   
    
    return [UIColor darkTextColor];
}

@end
