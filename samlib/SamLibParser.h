//
//  SamLibParser.h
//  samlib
//
//  Created by Kolyvan on 07.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//
//  https://github.com/kolyvan/samizdat
//  this file is part of Samizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt


#import <Foundation/Foundation.h>

extern NSString * removeHTMLComments(NSString *s);

typedef enum {
    
    SamLibParserPostCommentResponseSuccess,
    SamLibParserPostCommentResponseTooMany,    
    SamLibParserPostCommentResponseAccessDenied,        
    SamLibParserPostCommentResponseUnknownError,            
    
} SamLibParserPostCommentResponse;

typedef struct {
    
    NSDictionary * (*scanAuthorInfo)(NSString *html);
    NSString * (*scanBody)(NSString *html);    
    NSArray *  (*scanTexts)(NSString *html);
    NSString * (*scanTextData)(NSString *html);        
    NSArray * (*scanComments)(NSString *html);    
    SamLibParserPostCommentResponse (*scanCommentsResponse)(NSString *html);    
    BOOL (*scanLoginResponse)(NSString * response);
    NSDictionary * (*scanTextPage)(NSString *html);
    NSArray* (*listOfGroups)();
    NSArray * (*scanAuthors)(NSString *html);
    NSString * (*capitalToPath)(unichar first);
    NSString * (*cyrillicToLatin)(unichar first);
    
} SamLibParser_t;


extern SamLibParser_t SamLibParser;