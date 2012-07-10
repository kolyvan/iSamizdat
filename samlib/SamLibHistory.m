//
//  SamLibHistory.m
//  samlib
//
//  Created by Kolyvan on 10.07.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//

#import "SamLibHistory.h"
#import "KxUtils.h"
#define NSNUMBER_SHORTHAND
#import "KxMacros.h"
#import "NSString+Kolyvan.h"
#import "NSArray+Kolyvan.h"
#import "NSDictionary+Kolyvan.h"
#import "NSDate+Kolyvan.h"
#import "SamLibAuthor.h"
#import "SamLibText.h"
#import "SamLibComments.h"
#import "SamLibComments.h"
#import "SamLibStorage.h"
#import "DDLog.h"

extern int ddLogLevel;

#define MAX_HISTORY_COUNT 100

@interface SamLibHistoryEntry()
@property (readwrite, nonatomic) SamLibHistoryCategory category;
@property (readwrite, nonatomic, strong) NSString *title;
@property (readwrite, nonatomic, strong) NSString *name;
@property (readwrite, nonatomic, strong) NSString *key;
@property (readwrite, nonatomic, strong) NSDate *timestamp;
@end

@implementation SamLibHistoryEntry
@synthesize category;
@synthesize title;
@synthesize name;
@synthesize key;
@synthesize timestamp;

+ (id) fromDictionary: (NSDictionary *) dict
{
    SamLibHistoryEntry *p = [[SamLibHistoryEntry alloc] init];
    
    p.category  = [[dict get:@"category"] integerValue];
    p.title     = [dict get:@"title"];
    p.name      = [dict get:@"name"];    
    p.key       = [dict get:@"key"];
    p.timestamp = [NSDate dateWithISO8601String: [dict get:@"timestamp"]];

    return p;
}

- (NSDictionary *) toDictionary
{
    return KxUtils.dictionary($int(self.category), @"category",
                              self.title, @"title",
                              self.name, @"name",
                              self.key, @"key",
                              self.timestamp.iso8601Formatted, @"timestamp",                              
                              nil);
}


@end

@implementation SamLibHistory {
    NSMutableArray *_history;
    NSInteger _version;    
    NSInteger _savedVersion;
}

@synthesize history =_history;

+ (SamLibHistory *) shared
{
    static SamLibHistory * gHistory = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        gHistory = [[SamLibHistory alloc] init];
        
    });
    
    return gHistory;
}

- (id) init
{
    self = [super init];
    if (self) {
        
        NSArray *array = nil;
        
        if (KxUtils.fileExists(SamLibStorage.historyPath())) {
            array = SamLibStorage.loadObject(SamLibStorage.historyPath(), YES);
        }
        
        _history = [NSMutableArray arrayWithCapacity:array.count];
        for (NSDictionary *d in array)
            [_history push:[SamLibHistoryEntry fromDictionary:d]];
        
    }
    return self;   
}

- (void) addText: (SamLibText *) text
{
    [self addBaseObject:text];
}

- (void) addComments: (SamLibComments *) comments
{
    [self addBaseObject:comments];    
}

- (void) addBaseObject: (SamLibBase *) obj
{   
    SamLibHistoryCategory category;
    SamLibText *text;
        
    if ([obj isKindOfClass:[SamLibText class]]) {
        
        text = (SamLibText *)obj;
        category = SamLibHistoryCategoryText;
        
    } else if ([obj isKindOfClass:[SamLibComments class]]) {

        text = ((SamLibComments *)obj).text;
        category = SamLibHistoryCategoryComments;
        
    } else {
        NSAssert(false, @"invalid class");
        return;
    }
    
    SamLibHistoryEntry *p = [[SamLibHistoryEntry alloc] init];
    p.category = category;
    p.title = text.title;
    p.name = text.author.name;
    p.key = text.key;
    p.timestamp = [NSDate date];
    
    [self addEntry:p];
    
}

- (void) addEntry: (SamLibHistoryEntry *)newEntry
{
    for (SamLibHistoryEntry * p in _history) {

        if (p.category == newEntry.category &&
            [p.key isEqualToString:newEntry.key]) {
        
            [_history removeObject:p];            
            break;        
        }
    }
    
    [_history push: newEntry];    
    if (_history.count > MAX_HISTORY_COUNT)  
        [_history removeObjectAtIndex:0];
    
    ++_version;
}

- (void) save
{
    if (_version != _savedVersion) {
        
        _savedVersion = _version;
        
        NSArray *a = [_history map:^(id elem) { return [elem toDictionary]; }];        
        SamLibStorage.saveObject(a, SamLibStorage.historyPath());
        DDLogInfo(@"saved history: %d", _history.count);    
    }
}


@end
