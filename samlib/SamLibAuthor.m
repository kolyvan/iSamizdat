//
//  SamLibAuthor.m
//  samlib
//
//  Created by Kolyvan on 08.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//
//  https://github.com/kolyvan/samizdat
//  this file is part of Samizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt

#import "SamLibAuthor.h"
#import "SamLibAgent.h"
#import "SamLibParser.h"
#import "SamLibText.h"
#import "NSString+Kolyvan.h"
#import "NSDictionary+Kolyvan.h"
#import "NSArray+Kolyvan.h"
#import "NSDate+Kolyvan.h"
#import "KxMacros.h"
#import "KxUtils.h"
#import "DDLog.h"
#import "JSONKit.h"
#import "KxTuple2.h"
#import "SamLibStorage.h"

extern int ddLogLevel;

@interface SamLibAuthor()

@property (readwrite, nonatomic, KX_PROP_STRONG) NSString * name;
@property (readwrite, nonatomic, KX_PROP_STRONG) NSString * title;
@property (readwrite, nonatomic, KX_PROP_STRONG) NSString * updated;
@property (readwrite, nonatomic, KX_PROP_STRONG) NSString * size;
@property (readwrite, nonatomic, KX_PROP_STRONG) NSString * rating;
@property (readwrite, nonatomic, KX_PROP_STRONG) NSString * visitors;
@property (readwrite, nonatomic, KX_PROP_STRONG) NSString * www;
@property (readwrite, nonatomic, KX_PROP_STRONG) NSString * email;
@property (readwrite, nonatomic, KX_PROP_STRONG) NSString * lastModified;
@property (readwrite, nonatomic, KX_PROP_STRONG) NSString * about;
@property (readwrite, nonatomic, KX_PROP_STRONG) NSArray * texts;

- (void) updateFromDictionary: (NSDictionary *) dict;

@end

@implementation SamLibAuthor

@synthesize name = _name;
@synthesize title = _title;
@synthesize updated = _updated;
@synthesize size = _size;
@synthesize rating = _rating;
@synthesize visitors = _visitors;
@synthesize www = _www;
@synthesize email = _email;
@synthesize lastModified = _lastModified;
@synthesize digest = _digest;
@synthesize texts = _texts;
@synthesize about = _about;
@dynamic isDirty;
@synthesize changed = _changed;
@dynamic ratingFloat;

- (NSString *) relativeUrl 
{
    return [NSString stringWithFormat:@"/%c/%@", _path.first, _path];
}

- (void) setDigest:(NSString *)digest
{
    if (![_digest isEqual:digest]) {
        
        //_isDirty = YES;
        _changed = YES;
        self.timestamp = [NSDate date];
        KX_RELEASE(_digest);
        _digest = KX_RETAIN(digest);
    }
}

- (float) ratingFloat
{
    if (_rating.nonEmpty) {
        NSRange r = [_rating rangeOfString:@"*"];
        if (r.location != NSNotFound)
            return [[_rating take: r.location] floatValue];
    }
    return 0;    
}

- (BOOL) ignored
{
    return _ignored;
}

- (void) setIgnored:(BOOL)ignored
{
    if (_ignored != ignored) {
        _ignored = ignored;
        ++_version;
    }
}

- (NSString *) computeHash 
{
    NSMutableString *ms = [NSMutableString string];    
    if (self.timestamp)
        [ms appendString: [self.timestamp description]];
    if (self.lastModified)
        [ms appendString: self.lastModified];    
    [ms appendString: [self.version description]];    
    for (SamLibText *p in _texts) {
//        [ms appendString: [p.timestamp description]];                
        [ms appendString: [p.version description]];
    }
    return [ms md5];
}

- (BOOL) isDirty
{
    return ![[self computeHash] isEqual:_hash];    
}

- (id) version
{
    return [NSNumber numberWithInteger:_version];
}

+ (id) fromDictionary: (NSDictionary *)dict 
             withPath:(NSString *)path
{    
    SamLibAuthor *author = [[SamLibAuthor alloc] initFromDictionary:dict 
                                                           withPath:path];
    return KX_AUTORELEASE(author);
}

- (id) initFromDictionary: (NSDictionary *) dict 
                 withPath:(NSString *)path
{
    NSAssert(dict.nonEmpty, @"empty dictionary"); 
    
    self = [super initWithPath:path];
    if (self) {
        
        [self updateFromDictionary: dict];
        
        _lastModified   = KX_RETAIN(getStringFromDict(dict, @"lastModified", path));
        _digest         = KX_RETAIN(getStringFromDict(dict, @"digest", path));
        _ignored        = [getNumberFromDict(dict, @"ignored", path) boolValue];  
        
        NSDate *dt = getDateFromDict(dict, @"timestamp", path);        
        if (dt) self.timestamp = dt;

        _hash = KX_RETAIN([self computeHash]);        
    }
    return self;
}

- (void) dealloc
{
    KX_RELEASE(_name);    
    KX_RELEASE(_title);    
    KX_RELEASE(_updated);
    KX_RELEASE(_size); 
    KX_RELEASE(_rating);
    KX_RELEASE(_visitors);
    KX_RELEASE(_www);
    KX_RELEASE(_email);   
    KX_RELEASE(_lastModified);
    KX_RELEASE(_digest);
    KX_RELEASE(_texts);
    KX_RELEASE(_hash);
    KX_SUPER_DEALLOC();
}

- (void) updateFromDictionary: (NSDictionary *) dict
{
    self.name     = getStringFromDict(dict, @"name", _path);
    self.title    = getStringFromDict(dict, @"title", _path);
    self.updated  = getStringFromDict(dict, @"updated", _path);
    self.size     = getStringFromDict(dict, @"size", _path);
    self.rating   = getStringFromDict(dict, @"rating", _path);
    self.visitors = getStringFromDict(dict, @"visitors", _path);
    self.www      = getStringFromDict(dict, @"www", _path);
    self.email    = getStringFromDict(dict, @"email", _path);
    self.about    = getStringFromDict(dict, @"about", _path);   
    
    id t = [dict get:@"texts"];
    if (t) {
        if ([t isKindOfClass:[NSArray class]]) {
            
            NSArray * texts = t;
            
            texts = [texts map: ^(id elem) { 
                if ([elem isKindOfClass:[SamLibText class]])
                    return elem;
                if ([elem isKindOfClass:[NSDictionary class]])        
                    return [SamLibText fromDictionary:elem withAuthor: self];
                return nil;
            }];
            
            self.texts = texts;
            
        } else {
            
            DDLogWarn(locString(@"invalid '%@' in dictionary: %@"), @"texts", _path);
        }    
    }
}

- (NSDictionary *) toDictionary
{
    NSMutableDictionary * dict = [NSMutableDictionary dictionaryWithCapacity:14];
    
    NSArray * textsAsDict = [_texts map: ^(id elem) {
        return [elem toDictionary];
    }];

    [dict updateOnly: @"name" valueNotNil: _name];
    [dict updateOnly: @"title" valueNotNil: _title];    
    [dict updateOnly: @"updated" valueNotNil: _updated];    
    [dict updateOnly: @"size" valueNotNil: _size];        
    [dict updateOnly: @"rating" valueNotNil: _rating];    
    [dict updateOnly: @"visitors" valueNotNil: _visitors];    
    [dict updateOnly: @"www" valueNotNil: _www];    
    [dict updateOnly: @"email" valueNotNil: _email];    
    [dict updateOnly: @"lastModified" valueNotNil: _lastModified];    
    [dict updateOnly: @"digest" valueNotNil: _digest];    
    [dict updateOnly: @"timestamp" valueNotNil: [_timestamp iso8601Formatted]];    
    [dict updateOnly: @"texts" valueNotNil: textsAsDict];    
    [dict updateOnly: @"about" valueNotNil: _about];   
    
    if (_ignored)
        [dict update: @"ignored" value: [NSNumber numberWithBool:_ignored]];
    
    return dict;
}

- (SamLibText *) findText: (NSString *) byPath
{
    return [_texts find: ^(id elem) { 
        SamLibText * text = elem;        
        return [text.path isEqualToString:byPath];
    }]; 
}

- (void) updateTexts: (NSArray *) dicts
{
    NSMutableArray *newTexts = [NSMutableArray array];
    
    // update texts
    for (NSDictionary * d in dicts) {
        
        NSString * path = [d get: @"path"];
        SamLibText * t = [self findText:path];
        if (t)
            [t updateFromDictionary:d];
        else { 
            SamLibText *new = [SamLibText fromDictionary:d 
                                              withAuthor:self];
            [new flagAsNew];
            [newTexts push: new];
        }
    }
    
    // find removed texts
    for (SamLibText *t in self.texts) {
    
        BOOL found = NO;
        for (NSDictionary * d in dicts) {    
            
            if ([t.path isEqualToString:[d get: @"path"]]) {
                found = YES;
                break;
            }
        }
        
        if(!found) {
            [t flagAsRemoved];
        }
    }
    
    // add new texts
    if (newTexts.nonEmpty) {
        [newTexts addObjectsFromArray:self.texts];
        self.texts = newTexts;
    }
}

- (BOOL) updateFromData: (NSString *) data 
            lastModfied: (NSString *)lastModified
{
    [self updateFromDictionary: SamLibParser.scanAuthorInfo(data)]; 

    self.lastModified = lastModified;
    
    NSString *body = SamLibParser.scanBody(data);                                           
    NSString *digest = [body md5];
    
    if ([self.digest isEqualToString: digest]) 
        return NO;
  
    self.digest = digest;
    [self updateTexts: SamLibParser.scanTexts(body)];  
    _version++;
    return YES;    
}

- (void) clearTextChanged
{
    for (SamLibText *t in self.texts) 
        [t flagAsChangedNone];
}

- (void) update: (UpdateAuthorBlock) block
{    
#if __has_feature(objc_arc_weak)    
    __weak SamLibAuthor *this = self;
#else
    SamLibAuthor *this = self;
#endif    
    
    _changed = NO;
    
    SamLibAgent.fetchData([self.relativeUrl stringByAppendingPathComponent:@"indexdate.shtml"], 
                          self.lastModified, 
                          NO,
                          nil,
                          nil,
                          ^(SamLibStatus status, NSString *data, NSString *lastModified) {
                              
                              if (!this)
                                  return;
                              
                              if (status == SamLibStatusSuccess)  {
                                  
                                  if (![this updateFromData:data
                                                lastModfied:lastModified]) {
                                      
                                      status = SamLibStatusNotModifed;
                                  }
                              } 
                              
                              //if (status == SamLibStatusNotModifed)                                  
                              //    [self clearTextChanged];
                              
                              block(this, status, data);
                              
                          },
                          nil);
    
}

- (void) save: (NSString *) folder
{
    if (SamLibStorage.saveDictionary([self toDictionary], 
                                     [folder stringByAppendingPathComponent:_path])) {
 
 
        KX_RELEASE(_hash);
        _hash = KX_RETAIN([self computeHash]);
    }    
}

+ (id) fromFile: (NSString *) filepath
{
    NSDictionary *dict = SamLibStorage.loadDictionary(filepath);
    if (dict) {    
        NSString *path = [filepath lastPathComponent];        
        if (dict.nonEmpty)
            return [SamLibAuthor fromDictionary:dict withPath:path];
        return KX_AUTORELEASE([[SamLibAuthor alloc] initWithPath:path]);
    }    
    return nil;        
}

- (void) gcRemovedText
{
    self.texts = [_texts filterNot:^BOOL(id elem) {
        SamLibText * text = elem;        
        return text.isRemoved;
    }]; 
}

@end
