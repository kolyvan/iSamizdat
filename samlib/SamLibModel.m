//
//  SamLibModel.m
//  samlib
//
//  Created by Kolyvan on 12.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//
//  https://github.com/kolyvan/samizdat
//  this file is part of Samizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt



#import "KxArc.h"
#import "KxMacros.h"
#import "KxUtils.h"
#import "NSArray+Kolyvan.h"
#import "NSDictionary+Kolyvan.h"
#import "NSString+Kolyvan.h"
#import "SamLibModel.h"
#import "SamLibAgent.h"
#import "SamLibAuthor.h"
#import "SamLibText.h"
#import "SamLibComments.h"
#import "DDLog.h"

extern int ddLogLevel;

@interface SamLibModel() {
        
    NSArray * _authors;
    NSInteger _version;
}

@property (readwrite, nonatomic, ) NSArray * authors;
@property (readwrite, nonatomic) NSInteger version;

@end

@implementation SamLibModel

@synthesize authors = _authors;
@synthesize version = _version;

+ (SamLibModel *) shared
{
    static SamLibModel * gModel = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{

        gModel = [[SamLibModel alloc] init];
        [gModel reload];
        
    });
    
    return gModel;
}

- (id) init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (void) dealloc
{
    KX_RELEASE(_authors);
    _authors = nil;
    KX_SUPER_DEALLOC();
}

- (void) reload
{
    self.authors = SamLibAgent.loadAuthors();
    self.version += 1;
    
    DDLogInfo(@"loaded authors: %ld", _authors.count);    
}

- (void) save
{
    for (SamLibAuthor * author in _authors) {
        if (author.isDirty) {
            [author save: SamLibAgent.authorsPath()];
            DDLogInfo(@"save author: %@", author.path);
        }
        for (SamLibText *text in author.texts) {
            SamLibComments *comments = [text commentsObject:NO];
            if (comments && comments.isDirty) {
                [comments save: SamLibAgent.commentsPath()];
                DDLogInfo(@"save comments: %@", text.key);
            }
        }
    }
}

- (void) addAuthor: (SamLibAuthor *) author
{    
    [author save:SamLibAgent.authorsPath()];

    NSMutableArray *a = [_authors mutableCopy];
    [a push: author];    
    self.authors = a;
    KX_RELEASE(a);    
    self.version += 1;    
}

- (void) deleteAuthor: (SamLibAuthor *) author
{
    for (SamLibText *text in author.texts)
        [text removeTextFiles:YES andComments:YES];
        
    SamLibAgent.removeAuthor(author.path); 
    
    NSMutableArray *ma = [_authors mutableCopy];
    [ma removeObject:author];    
    self.authors = ma;
    KX_RELEASE(ma);    
    self.version += 1;  
}

- (SamLibAuthor *) findAuthor: (NSString *) byPath
{
    return [_authors find:^BOOL(id elem) {
        SamLibAuthor * author = elem;
        return [author.path isEqualToString:byPath];
    }];
}

- (SamLibText *) findTextByKey: (NSString *)key
{
    NSArray *a = [key split:@"."];
    
    if (a.count == 2) {
        
        NSString *path = [a objectAtIndex:0];        
        SamLibAuthor *author = [self findAuthor: path];        
        if (author) {
            //return [author findText:path];            
            return [author.texts find: ^(id elem) { 
                SamLibText *text = elem;        
                return [text.key isEqualToString:key];
            }]; 
        }
    }      
    
    return nil;
}



@end
