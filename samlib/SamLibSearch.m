//
//  SamLibSearch.m
//  samlib
//
//  Created by Kolyvan on 18.06.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//
//  https://github.com/kolyvan/samizdat
//  this file is part of Samizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt


#import "SamLibSearch.h"
#import "KxArc.h"
#import "KxMacros.h"
#import "KxUtils.h"
#import "NSArray+Kolyvan.h"
#import "NSDictionary+Kolyvan.h"
#import "NSString+Kolyvan.h"
#import "NSDate+Kolyvan.h"
#import "SamLibAgent.h"
#import "SamLibModel.h"
#import "SamLibParser.h"
#import "SamLibAuthor.h"
#import "SamLibCacheNames.h"
#import "GoogleSearch.h"
#import "DDLog.h"
#import "SamLibStorage.h"

extern int ddLogLevel;

#define MINDISTANCE1 0.2
#define MINDISTANCE2 0.4
#define DISTANCE_THRESHOLD 0.8
#define GOOGLE_REQUERY_TIME 1
#define SAMLIB_REQUERY_TIME 24

///

static NSDictionary * mapGoogleResult(NSDictionary * dict, NSString * baseURL)
{        
    // "titleNoFormatting": "Журнал &quot;Самиздат&quot;.Смирнов Василий Дмитриевич. Смирнов ..."
    // "url": "http://samlib.ru/s/smirnow_w_d/indexdate.shtml",
    
    NSScanner *scanner;
    scanner = [NSScanner scannerWithString:[dict get:@"url"]];  
    if (![scanner scanString:baseURL intoString:nil])
        return nil;
    
    NSString *path = nil;
    if (![scanner scanUpToString:@"/indexdate.shtml" intoString:&path])
        return nil;
    
    if (!path.nonEmpty)
        return nil;
    
    scanner = [NSScanner scannerWithString:[dict get:@"titleNoFormatting"]];  
    
    if (![scanner scanString:@"Журнал &quot;Самиздат&quot;." intoString:nil])
        return nil;
    
    NSString *name = nil;
    if (![scanner scanUpToString:@"." intoString:&name])
        return nil;
    
    if (!name.nonEmpty)
        return nil;

    NSString *info = nil;
    if (!scanner.isAtEnd)
        info = [[scanner.string substringFromIndex:scanner.scanLocation + 1] trimmed];
    
    return KxUtils.dictionary(name, @"name", 
                              path, @"path",
                              info, @"info",                              
                              @"google", @"from",                                                                
                              nil);
}

static NSArray * searchAuthor(NSString * pattern,
                              NSString * key,
                              NSArray * array)
{
    NSInteger patternLengtn = pattern.length;
    unichar patternChars[patternLengtn];
    [pattern getCharacters:patternChars 
                     range:NSMakeRange(0, patternLengtn)];
    
    NSMutableArray * ma = [NSMutableArray array];
    
    for (NSDictionary *dict in array) {
        
        NSString *value = [dict get:key];
        if (value.nonEmpty) {
            
            float distance = levenshteinDistanceNS(value, patternChars, patternLengtn);
            distance = 1.0 - (distance / MAX(value.length, patternLengtn));
            
            if (patternLengtn <= value.length &&                
                [value hasPrefix: pattern] &&
                (distance > MINDISTANCE1)) {
                
                NSMutableDictionary *md = [dict mutableCopy];
                [md update:@"distance" value:[NSNumber numberWithFloat:1.0 + distance]];                
                [ma push:md];
                KX_RELEASE(md);
            }
            else if (distance > MINDISTANCE2) {            
                
                NSMutableDictionary *md = [dict mutableCopy];
                [md update:@"distance" value:[NSNumber numberWithFloat:distance]];                
                [ma push:md];
                KX_RELEASE(md);                
            }
        }
    }
    
    return ma;    
}



static NSString * mkPathFromName(NSString *name)
{    
    // convert from cirillyc name to path                                
    // Дмитриев Павел -> dmitriew_p
        
    name = name.lowercaseString;
    NSMutableString *ms = [NSMutableString string];
    NSArray *a = [name split];
    NSString *first = a.first;
    
    for (NSNumber *n in [first toArray])  {
        
        unichar ch = [n unsignedShortValue];            
        NSString *s = SamLibParser.cyrillicToLatin(ch);
        if (s)
            [ms appendFormat:@"%@", s];                    
        else
            [ms appendFormat:@"%c", ch];                    
    };
    
    for (NSString *p in a.tail) {
        NSString *s = SamLibParser.cyrillicToLatin(p.first);
        if (s)
            [ms appendFormat:@"_%@", s];                    
        else
            [ms appendFormat:@"_%c", p.first];                    
    }
    
    return ms;
}

///

@interface SamLibSearch() {
    SamLibCacheNames * _cacheNames;    
    GoogleSearch * _googleSearch;
    NSMutableDictionary *_history;
    NSString * _historyDigest;
    BOOL _cancelAgent;
}
@end

@implementation SamLibSearch

+ (NSString *) historyPath
{
    return [SamLibStorage.namesPath() stringByAppendingPathComponent: @"searchlog.json"];
}

- (id) init
{
    self = [super init];
    if (self) {
        _cacheNames = [[SamLibCacheNames alloc] init];
        
        _history = (NSMutableDictionary *)SamLibStorage.loadDictionaryEx([self->isa historyPath], NO);
        if (!_history)            
            _history = [NSMutableDictionary dictionary];        
        _historyDigest = [_history.description md5];
    }
    return self;
}

- (void) dealloc
{
    [self cancel];    
    
    DDLogInfo(@"%@ dealloc", [self class]);

    if (![_historyDigest isEqualToString: [_history.description md5]]) {

        DDLogInfo(@"save search history");
        SamLibStorage.saveDictionary(_history, [self->isa historyPath]);        
    }

    KX_RELEASE(_history);
    KX_RELEASE(_historyDigest); 
    
    [_cacheNames close];
    KX_RELEASE(_cacheNames);
    _cacheNames = nil;
    KX_SUPER_DEALLOC();
}

- (BOOL) checkTime: (NSInteger ) hours 
          forQuery: (NSString *) query
{    
    NSNumber *timestamp = [_history get:query];
    NSDate *now = [NSDate date];
    
    // check timeout
    if (timestamp) {
        
        NSDate *dt = [NSDate dateWithTimeIntervalSinceReferenceDate:timestamp.doubleValue];        
        if ([now isLess:dt])        
            return NO; // still wait
    }
    
    // save timeout
    NSDate *dt = [now addHours:hours];
    timestamp = [NSNumber numberWithDouble:dt.timeIntervalSinceReferenceDate];
    [_history update: query value: timestamp];
    
    return YES;
}


- (NSArray *) localSearchAuthor: (NSString *)pattern 
                            key: (NSString *)key  
{
    NSArray *authors = [SamLibModel shared].authors;
    
    authors = [authors map:^(id elem) {
        SamLibAuthor *author = elem;
        return KxUtils.dictionary(author.name, @"name", 
                                  author.path, @"path", 
                                  author.title, @"info", 
                                  //[NSNumber numberWithFloat:3], @"distance",                                  
                                  @"local", @"from",                                  
                                  nil);
    }];
    
    return searchAuthor(pattern, key, authors); 
}

- (NSArray *) cacheSearchAuthor: (NSString *)pattern
                            key: (NSString *)key 
                        section: (unichar) sectionChar
{
    NSString *s = KxUtils.format(@"%%%@%%", pattern);

    NSArray *like; // LIKE %name% 
    if ([key isEqualToString: @"name"])
        like = [_cacheNames selectByName:s];    
    else
        like = [_cacheNames selectByPath:s];    
        
    NSArray *section = [_cacheNames selectBySection:sectionChar];
    NSArray *result = [self->isa unionArray:section withArray: like]; 
    DDLogInfo(@"loaded from cache: %d", result.count);    
    if (result.nonEmpty)
        return searchAuthor(pattern, key, result);    
    return nil;
}

- (void) googleSearch: (NSString *)pattern
                  key: (NSString *)key
              section: (unichar)section
                block: (AsyncSearchResult) block
{   
    
    NSString *query;
    
    if ([key isEqualToString:@"name"]) {
        
        NSMutableString *ms = [NSMutableString string];
        for (NSString *s in [pattern split])
            [ms appendFormat:@"intitle:%@ ", s];      
        
        query = KxUtils.format(@"site:samlib.ru/%c %@ inurl:indexdate.shtml", section, ms);
        
    }
    else
        query = KxUtils.format(@"site:samlib.ru/%c inurl:indexdate.shtml", section);
    
    _googleSearch = [GoogleSearch search: query 
                                   block: ^(GoogleSearchStatus status, NSString *details, NSArray *googleResult) {
                       
                       
                       NSArray *result = nil;
                       
                       if (status == GoogleSearchStatusSuccess) {
                           
                           DDLogInfo(@"loaded from google: %d", googleResult.count);
                           
                           NSString *baseURL = KxUtils.format(@"http://samlib.ru/%c/", section); 
                           
                           NSMutableArray *authors = [NSMutableArray array];
                           
                           for (NSDictionary *d in googleResult) {
                               NSDictionary *mapped = mapGoogleResult(d, baseURL);
                               if (mapped)
                                   [authors push:mapped];
                           }
                           
                           if (authors.nonEmpty) {
                               
                               [_cacheNames addBatch:authors];
                               result = searchAuthor(pattern, key, authors);                             
                               DDLogInfo(@"found in google: %d", result.count);               
                           }                         
                       } 
                       
                       block(result);                     
                       
                   }];
}

- (void) samlibSearch: (NSString *)pattern
                  key: (NSString *)key
              catalog: (NSString *)catalog
                block: (AsyncSearchResult) block
{
    _cancelAgent = YES;    
    SamLibAgent.fetchData(catalog, nil, NO, nil, nil,
                          ^(SamLibStatus status, NSString *data, NSString *lastModified) {                                  
                              
                              NSArray *result = nil;
                              
                              if (status == SamLibStatusSuccess) {
                                  
                                  NSArray *authors = SamLibParser.scanAuthors(data); 
                                  
                                  DDLogInfo(@"loaded from samlib: %d", authors.count);
                                  
                                  if (authors.nonEmpty) {
                                      
                                      [_cacheNames addBatch:authors];                                      
                                      result = searchAuthor(pattern, key, authors);
                                      DDLogInfo(@"found in samlib: %d", result.count);                                      
                                  }
                              }
                              
                              block(result);                              
                          },
                          nil);
}

-(void) directSearchByPath: (NSString *) path  
                     block: (AsyncSearchResult) block
{
    _cancelAgent = YES;        
    
    SamLibAuthor *author = [[SamLibAuthor alloc] initWithPath:path];
    
    [author update:^(SamLibAuthor *unused, SamLibStatus status, NSString *error) {        
        
        if (status == SamLibStatusSuccess) {
            
            NSMutableDictionary *md = [NSMutableDictionary dictionary];
            [md update:@"path"      value:author.path];
            [md update:@"distance"  value:[NSNumber numberWithFloat:2]];
            [md update:@"from"      value:@"direct"];            
            [md updateOnly:@"name"  valueNotNil:author.name];
            [md updateOnly:@"info"  valueNotNil:author.title];
            block([NSArray arrayWithObject:md]);
            
        } else {

            block(nil);
        }

        KX_RELEASE(author);
    }];
}


- (void) searchAuthor: (NSString *) pattern 
               byName: (BOOL) byName
                 flag: (FuzzySearchFlag) flag
                block: (AsyncSearchResult) block
{      
    NSString *key;
    NSString *catalog; // samlib catalog    
    unichar section;
    
    if (byName) {        
        
        catalog = SamLibParser.captitalToPath(pattern.first);        
        
        if (!catalog.nonEmpty) {
            
            DDLogWarn(locString(@"invalid author name: %@"), pattern);
            block(nil);
            return;
        }  
        
        section = catalog.first;
        key = @"name";
        
    } else {
        
        pattern = pattern.lowercaseString;        
        section = pattern.first;
        catalog = KxUtils.format(@"%c/", section);
        key = @"path";        
    }
    
    if (0 != (flag & FuzzySearchFlagLocal)) {
        
        NSArray *found = [self localSearchAuthor:pattern 
                                             key:key];    
        DDLogInfo(@"found local: %d", found.count);    
        if (found.nonEmpty)
            block(found);
    }   
    
    BOOL cacheHit = NO;
    
    if (0 != (flag & FuzzySearchFlagCache)) {
        
        NSArray *found = [self cacheSearchAuthor:pattern 
                                             key:key
                                         section:section];
        
        DDLogInfo(@"found in cache: %d", found.count);     
        
        if (found.nonEmpty) {
            
            block(found);                    
            for (NSDictionary *d in found) {
                float distance = [[d get: @"distance"] floatValue];
                if (distance > DISTANCE_THRESHOLD) {
                    cacheHit = YES;
                    break;
                }
            }  
        }
    }
    
    BOOL needDirect = 0 != (flag & FuzzySearchFlagDirect); 
    BOOL needGoogle = NO, needSamlib = NO;
    
    if (!cacheHit) {
        
        if (0 != (flag & FuzzySearchFlagGoogle)) {
            
            needGoogle = [self checkTime:GOOGLE_REQUERY_TIME 
                                forQuery:KxUtils.format(@"google:%@", pattern)];
        }
        
        if (0 != (flag & FuzzySearchFlagSamlib)) {
            
            needSamlib = [self checkTime:SAMLIB_REQUERY_TIME 
                       forQuery:KxUtils.format(@"samlib:%@", catalog)];
        }
    } 
    
    __block int asyncCount = 0;    
    
    asyncCount += (needDirect ? 1 : 0);
    asyncCount += (needGoogle ? 1 : 0);
    asyncCount += (needSamlib ? 1 : 0);
    
    if (asyncCount) {
        
        void(^asyncBlock)(NSArray *) = ^(NSArray *found) {
                       
            if (found.nonEmpty)
                block(found);
            
            if (--asyncCount == 0) {
                
                block(nil); // 
            }
        };
                
        if (needDirect) {
            
            [self directSearchByPath:byName ? mkPathFromName(pattern) : pattern
                               block:asyncBlock];
        }
        
        if (needGoogle) {            

            [self googleSearch:pattern key:key section:section block:asyncBlock];
        }
        
        if (needSamlib) {
            
            [self samlibSearch:pattern key:key catalog:catalog block:asyncBlock];
        }
        
    } else {
        
        block(nil); // fire about finish
    }    
}

+ (id) searchAuthor: (NSString *) pattern
             byName: (BOOL) byName
               flag: (FuzzySearchFlag) flag
              block: (void(^)(NSArray *result)) block
{
    NSAssert(pattern.nonEmpty, @"empty pattern");
    SamLibSearch *p = [[SamLibSearch alloc] init];    
    [p searchAuthor:pattern byName:byName flag:flag block:block];    
    return KX_AUTORELEASE(p);
}

- (void) cancel
{
    if (_cancelAgent)
        SamLibAgent.cancelAll();    
    [_googleSearch cancel];
    _googleSearch = nil;
}

+ (NSArray *) sortByDistance: (NSArray *) result
{
    return [result sortWith:^(id obj1, id obj2) {
        NSDictionary *l = obj1, *r = obj2;
        return [[r get:@"distance"] compare: [l get:@"distance"]];
    }];
}

+ (NSArray *) unionArray: (NSArray *) l
               withArray: (NSArray *) r
{    
    NSMutableArray *result = [NSMutableArray array];
    
    // filter duplicates    
    for (NSDictionary *m in l) {
        
        NSString *path = [m get:@"path"];
        
        BOOL found = NO;
        
        for (NSDictionary *n in r)            
            if ([path isEqualToString: [n get:@"path"]]) {
                found = YES;
                break;
            }   
        
        if (!found) 
            [result push:m];
    }
    
    // union    
    [result appendAll: r];
    return result;
}

@end
