//
//  SamLibModerator.h
//  samlib
//
//  Created by Kolyvan on 06.07.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "KxArc.h"

@class SamLibComment;

typedef enum {
    
    SamLibBanCategoryName,
    SamLibBanCategoryEmail, 
    SamLibBanCategoryURL,     
    SamLibBanCategoryText,    
    
} SamLibBanCategory;

typedef enum {

    SamLibBanRuleOptionNone,
    SamLibBanRuleOptionSubs,
    SamLibBanRuleOptionRegex,
    SamLibBanRuleOptionLink,    
    
} SamLibBanRuleOption;

typedef enum {
    
    SamLibBanTestOptionAll,
    SamLibBanTestOptionGuests,         
    SamLibBanTestOptionSamizdat,
    
} SamLibBanTestOption;

@interface SamLibBanRule : NSObject<NSCopying>
@property (readwrite, nonatomic, KX_PROP_STRONG) NSString *pattern;
@property (readwrite, nonatomic) SamLibBanCategory category;
@property (readwrite, nonatomic) CGFloat threshold;
@property (readwrite, nonatomic) SamLibBanRuleOption option;

- (id) initFromPattern: (NSString *) pattern 
              category: (SamLibBanCategory) category;

- (CGFloat) testPatternAgainst: (NSString *) s;

@end

@interface SamLibBan : NSObject<NSCopying>
@property (readwrite, nonatomic, KX_PROP_STRONG) NSString *name;
@property (readwrite, nonatomic, KX_PROP_STRONG) NSString *path;
@property (readonly, KX_PROP_STRONG) NSArray *rules;
@property (readwrite, nonatomic) CGFloat tolerance;
@property (readwrite, nonatomic) BOOL enabled;
@property (readwrite, nonatomic) SamLibBanTestOption option;

- (id) initWithName: (NSString *) name 
              rules: (NSArray *) rules 
          tolerance: (CGFloat) tolerance
               path: (NSString *) path;


- (BOOL) checkPath: (NSString *) path;
- (CGFloat) computeBan: (SamLibComment *) comment;
- (BOOL) testForBan: (SamLibComment *) comment;

- (void) addRule:(SamLibBanRule *)rule;
- (void) removeRule:(SamLibBanRule *)rule;
- (void) removeRuleAtIndex:(NSUInteger)index;

@end

@interface SamLibModerator : NSObject

@property (readonly, KX_PROP_STRONG) NSArray * allBans;
@property (readonly) id version;

+ (SamLibModerator *) shared;

- (SamLibBan *) testForBan: (SamLibComment *) comment 
                  withPath: (NSString *) path;

- (void) addBan: (SamLibBan *) ban;
- (void) removeBan: (SamLibBan *) ban;
- (void) removeBanAtIndex:(NSUInteger)index;
- (SamLibBan *) findByName: (NSString *) name;

- (void) save;

- (void) registerLinkToPattern: (NSString *) name pattern: (NSArray *) pattern;
- (NSArray *) lookupPatternByLink: (NSString *) name;

@end
