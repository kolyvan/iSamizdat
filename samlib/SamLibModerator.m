//
//  SamLibModerator.m
//  samlib
//
//  Created by Kolyvan on 06.07.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//

#import "SamLibModerator.h"
#import "KxUtils.h"
#define NSNUMBER_SHORTHAND
#import "KxMacros.h"
#import "NSString+Kolyvan.h"
#import "NSArray+Kolyvan.h"
#import "NSDictionary+Kolyvan.h"
#import "SamLibComments.h"
#import "SamLib.h"
#import "SamLibStorage.h"
#import "DDLog.h"

extern int ddLogLevel;

@implementation SamLibBanRule {
    NSArray *_patternAsArray;
    NSInteger _version;
}

@synthesize pattern = _pattern, category = _category, threshold = _threshold, option = _option;

- (void) setPattern:(NSString *)pattern
{
    NSAssert(pattern, @"pattern is nil");
    
    if (![_pattern isEqualToString: pattern]) {
        
        _patternAsArray = nil;
        _pattern = pattern.lowercaseString;
        _version++;
    }
}

- (void) setCategory:(SamLibBanCategory)category
{
    if (_category != category) {
        _category = category;
        _version++;
    }
}

- (void) setThreshold:(CGFloat)threshold
{
    if (_threshold != threshold) {
        _threshold = threshold;
        _version++;
    }    
}

- (void) setOption:(SamLibBanRuleOption)option
{
    if (_option != option) {
        _option = option;
        _version++;
    }
}

- (NSInteger) version
{
    return _version;
}

+ (id) fromDictionary: (NSDictionary *) dict
{
    SamLibBanRule *p;
    p = [[SamLibBanRule alloc] initFromPattern:[dict get:@"pattern"]  
                                         category:[[dict get:@"category"] intValue]];
    
    p.threshold = [[dict get:@"threshold"] floatValue];
    p.option = [[dict get:@"option"] integerValue];    
    return p;
}

- (NSDictionary *) toDictionary
{
    return KxUtils.dictionary(_pattern, @"pattern",
                              $int(_category), @"category",
                              $float(_threshold), @"threshold",
                              $int(_option), @"option",  
                              nil);
}

- (id) initFromPattern: (NSString *) pattern 
              category: (SamLibBanCategory) category             
{
    NSAssert(pattern.nonEmpty, @"empty pattern");
    
    self = [super init];
    if (self) {
        self.pattern = pattern;
        _category = category;
        _threshold = 1;
        _option = SamLibBanRuleOptionNone;
    }
    return self;
}

- (id) copyWithZone:(NSZone *)zone
{
    SamLibBanRule *p = [[SamLibBanRule allocWithZone:zone] initFromPattern:[_pattern copy]
                                                                  category:_category];
    p.threshold = _threshold;
    p.option = _option;
    return p;
}

- (NSArray *) patternAsArray
{
    if (!_patternAsArray) {
    
        if (_option == SamLibBanRuleOptionLink) {
            
            _patternAsArray = [[SamLibModerator shared] lookupPatternByLink: _pattern];
        }
        else {
            static NSCharacterSet *separtors = nil;
            if (!separtors)
                separtors = [NSCharacterSet characterSetWithCharactersInString:@"|"];        
            _patternAsArray = [_pattern componentsSeparatedByCharactersInSet:separtors];         
        }
    }
    
    return _patternAsArray;
}

- (CGFloat) testPatternAgainst: (NSString *) s
{
    s = s.lowercaseString;
    
    if (_option == SamLibBanRuleOptionRegex) {
        
        return [self->isa testRegexp:s pattern:_pattern];
        
    } else {
        
        static NSCharacterSet *separtors = nil;
        if (!separtors)
            separtors = [NSCharacterSet characterSetWithCharactersInString:@" \n\r\t.,;:\"!?"];
    
        NSArray *words = nil;
        
        for (NSString *pattern in self.patternAsArray) {
            
            if ([pattern rangeOfCharacterFromSet:separtors].location != NSNotFound ||
                _option == SamLibBanRuleOptionSubs ) {
                
                CGFloat r = [self->isa testSubs:s 
                                        pattern:pattern 
                                      threshold:_threshold];
                
                if (r > 0)
                    return r;
                
            } else {
                                
                if (!words) {                    
                    words = [[s componentsSeparatedByCharactersInSet: separtors] filter:^(id elem) {
                        return [elem nonEmpty];
                    }];
                }
                
                for (NSString *w in words) {
                    
                    CGFloat r = [self->isa testWord:w
                                            pattern:pattern 
                                          threshold:_threshold];
                    if (r > 0) 
                        return r;;
                }            
            }
        }
    }
        
    return 0;
}

+ (CGFloat) fuzzyTest: (NSString *)w 
              pattern: (NSString *)pattern
            threshold: (CGFloat) threshold
{
    float distance = levenshteinDistanceNS2(pattern, w);
    distance = 1.0 - (distance / MAX(pattern.length, w.length));
    return threshold < distance ? distance : 0;
}

+ (CGFloat) testWord: (NSString *) w
             pattern: (NSString *) pattern
           threshold: (CGFloat) threshold
{
    if (threshold > 0.999)        
        return [w isEqualToString:pattern] ? 1 : 0;    
    return [self fuzzyTest:w pattern:pattern threshold:threshold];
}

+ (CGFloat) testSubs: (NSString *) s 
             pattern: (NSString *) pattern
           threshold: (CGFloat) threshold

{    if (threshold > 0.999)        
        return [s rangeOfString:pattern].location != NSNotFound ? 1 : 0;
    
    if (pattern.length >= s.length)        
        return [self fuzzyTest:s pattern:pattern threshold:threshold];

    NSInteger n = s.length - pattern.length;
    for (int i = 0; i < n; ++i) {
        
        NSString *subs = [s substringWithRange:NSMakeRange(i, pattern.length)];
        CGFloat r = [self fuzzyTest:subs pattern:pattern threshold:threshold];
        if (r > 0)
            return r;        
    }
    
    return 0;
}

+ (CGFloat) testRegexp: (NSString *) w
               pattern: (NSString *) pattern
{
    NSRegularExpression *regex;
    regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                      options:NSRegularExpressionCaseInsensitive
                                                        error:nil];
    
    NSTextCheckingResult *match;
    match = [regex firstMatchInString:w
                              options:0
                                range:NSMakeRange(0, w.length)];
    
    return match ? 1 : 0;
}

@end

////

@implementation SamLibBan {
    NSMutableArray *_rules;
    NSInteger _version;
}

@synthesize name = _name; 
@synthesize rules = _rules; 
@synthesize tolerance = _tolerance; 
@synthesize path = _path;
@synthesize enabled = _enabled;
@synthesize option = _option;

- (NSInteger) version
{
    NSInteger version = _version;
    for (SamLibBanRule *rule in _rules)
        version += rule.version;
    return version;
}

- (void) setName:(NSString *)name
{    
    NSAssert(name, @"name is nil");
    
    if (![_name isEqualToString: name]) {

        _name = name;
        _version++;
    }
}

- (void) setTolerance:(CGFloat)tolerance
{
    if (_tolerance != tolerance) {
        _tolerance = tolerance;
        _version++;
    }
}

- (void) setPath:(NSString *)path
{
    NSAssert(path, @"path is nil");
    
    if (![_path isEqualToString: path]) {
        
        _path = path;
        _version++;
    }
}

- (void) setEnabled:(BOOL)enabled
{
    if (_enabled != enabled) {
        _enabled = enabled;
        _version++;
    }
}

- (void) setOption:(SamLibBanTestOption)option
{
    if (_option != option) {
        _option = option;
        _version++;
    }
}

+ (id) fromDictionary: (NSDictionary *) dict
{
    NSArray *rules = [dict get:@"rules"];
    
    rules = [rules map:^(id elem) {
        return [SamLibBanRule fromDictionary: elem];
    }];
    
    SamLibBan *p;
    p = [[SamLibBan alloc] initWithName: [dict get:@"name"]
                                  rules: rules
                              tolerance: [[dict get:@"tolerance"] floatValue]
                                   path: [dict get:@"path"]];

    p.enabled = [[dict get:@"enabled"] boolValue];
    p.option =  [[dict get:@"option"] integerValue];
    return p;
}

- (NSDictionary *) toDictionary
{
    NSArray *rules = [_rules map:^(id elem) {
        return [elem toDictionary];
    }];
    
    return KxUtils.dictionary(_name.nonEmpty ? _name : @"", @"name",
                              _path.nonEmpty ? _path : @"", @"path",
                              rules, @"rules",
                              $float(_tolerance), @"tolerance",
                              $bool(_enabled), @"enabled",
                              $int(_option), @"option",                              
                              nil);
}

- (id) initWithName: (NSString *) name 
              rules: (NSArray *) rules 
          tolerance: (CGFloat) tolerance
               path: (NSString *) path
{
    NSAssert(rules.nonEmpty, @"empty rules");
    NSAssert(tolerance > 0, @"tolerance out of range");    
    
    self = [super init];
    if (self) {
        
        _rules = [rules mutableCopy];        
        self.name = name;
        self.path = path;
        _tolerance = tolerance;
        _enabled = YES;
        _option = SamLibBanTestOptionAll;
    }
    return self;
}

- (id) copyWithZone:(NSZone *)zone
{
    SamLibBan *p = [[SamLibBan allocWithZone:zone] initWithName:[_name copy] 
                                                          rules:[_rules map:^(id x) {return [x copy];}] 
                                                      tolerance:_tolerance 
                                                           path:[_path copy]];
    p.enabled = _enabled;
    p.option = _option;
    return p;
}

- (void) addRule:(SamLibBanRule *)rule
{
    [_rules push:rule];
}

- (void) removeRule:(SamLibBanRule *)rule
{
    [_rules removeObject:rule];
}

- (void) removeRuleAtIndex:(NSUInteger)index
{
    [_rules removeObjectAtIndex:index];
}

- (BOOL) checkPath: (NSString *) path
{
    if (!_path.nonEmpty)
        return YES; // empty path, always true 
    
    return [path hasPrefix:_path];
}

- (CGFloat) computeBan: (SamLibComment *) comment 
{
    CGFloat result = 0;
    
    for (SamLibBanRule *rule in _rules) {
        
        NSString *s = nil;
        
        switch (rule.category) {
            case SamLibBanCategoryName:     s = comment.name;   break;
            case SamLibBanCategoryEmail:    s = comment.email;  break;
            case SamLibBanCategoryURL:      s = comment.link;   break;
            case SamLibBanCategoryText:     s = comment.message; break;
        }
        
        if (s.nonEmpty)
            result += [rule testPatternAgainst: s];        
    }
    
    return result;
}

- (BOOL) testForBan: (SamLibComment *) comment
{   
    if (_option != SamLibBanTestOptionAll) {
        BOOL isSamizdat = _option == SamLibBanTestOptionSamizdat;
        if (isSamizdat != comment.isSamizdat)
            return NO;
    }
        
    CGFloat total = 0;
        
    for (SamLibBanRule *rule in _rules) {
    
        NSString *s = nil;
        
        switch (rule.category) {
            case SamLibBanCategoryName:     s = comment.name;   break;
            case SamLibBanCategoryEmail:    s = comment.email;  break;
            case SamLibBanCategoryURL:      s = comment.link;   break;
            case SamLibBanCategoryText:     s = comment.message; break;
        }
        
        if (s.nonEmpty)
            total += [rule testPatternAgainst: s];
            
        if (total >= _tolerance)
            return YES;        
    }
    
    return NO;
}

@end

@implementation SamLibModerator {

    id _hash;
    NSInteger _version;
    NSMutableArray *_allBans;
    NSMutableDictionary *_links;

}

@synthesize allBans = _allBans;

- (id) version
{
    NSInteger version = _version;
    for (SamLibBan *ban in _allBans)
        version += ban.version;
    return [NSNumber numberWithInteger:version];
}

+ (SamLibModerator *) shared
{
    static SamLibModerator * gModer = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        gModer = [[SamLibModerator alloc] init];
        
    });
    
    return gModer;
}

- (id) init
{
    self = [super init];
    if (self) {
        
        NSArray *array = nil;
        
        if (KxUtils.fileExists(SamLibStorage.bansPath())) {
            array = SamLibStorage.loadObject(SamLibStorage.bansPath(), YES);
        }
        
        _allBans = [NSMutableArray arrayWithCapacity:array.count];
        for (NSDictionary *d in array)
            [_allBans push:[SamLibBan fromDictionary:d]];                
        
        _hash = self.version;
    }
    return self;
}

- (SamLibBan *) testForBan: (SamLibComment *) comment 
                  withPath:(NSString *)path
{
    for (SamLibBan *ban in _allBans) {
        if ([ban enabled] &&
            [ban checkPath: path] &&
            [ban testForBan:comment])
            return ban;    
    }
    return nil;
}

- (void) addBan: (SamLibBan *) ban
{
    [_allBans push:ban];
    ++_version;
}

- (void) removeBan: (SamLibBan *) ban
{
    [_allBans removeObject:ban];
    ++_version;
}

- (void) removeBanAtIndex:(NSUInteger)index
{
    [_allBans removeObjectAtIndex:index];
}

- (SamLibBan *) findByName: (NSString *) name
{
    for (SamLibBan *ban in _allBans)
        if ([ban.name isEqualToString:name])
            return ban;
    return nil;
}

- (void) save
{
    id newHash = self.version;
    
    if (![_hash isEqual:newHash]) {

        _hash = newHash;
        
        NSArray *a = [_allBans map:^id(id elem) {
            return [elem toDictionary];
        }];
        
        SamLibStorage.saveObject(a, SamLibStorage.bansPath());
        
        DDLogInfo(@"saved bans: %d", _allBans.count);
    }
}

- (void) registerLinkToPattern: (NSString *) name pattern: (NSArray *) pattern
{
    if (!_links)
        _links = [NSMutableDictionary dictionary];
    [_links update:name value:pattern];
}

- (NSArray *) lookupPatternByLink: (NSString *) name
{
    return [_links get:name orElse:[NSArray array]];
}

@end
