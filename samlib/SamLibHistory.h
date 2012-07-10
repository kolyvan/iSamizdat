//
//  SamLibHistory.h
//  samlib
//
//  Created by Kolyvan on 10.07.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SamLibText;
@class SamLibComments;

typedef enum {
  
    SamLibHistoryCategoryText,
    SamLibHistoryCategoryComments, 
    
} SamLibHistoryCategory;

@interface SamLibHistoryEntry : NSObject
@property (readonly, nonatomic) SamLibHistoryCategory category;
@property (readonly, nonatomic, strong) NSString *title;
@property (readonly, nonatomic, strong) NSString *name;
@property (readonly, nonatomic, strong) NSString *key;
@property (readonly, nonatomic, strong) NSDate *timestamp;
@end

@interface SamLibHistory : NSObject

@property (readonly, nonatomic) NSArray * history;

+ (SamLibHistory *) shared;

- (void) addText: (SamLibText *) text;
- (void) addComments: (SamLibComments *) comments;

- (void) save;

@end
