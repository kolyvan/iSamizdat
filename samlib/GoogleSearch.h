//
//  GoogleSearch.h
//  samlib
//
//  Created by Kolyvan on 17.06.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//
//  https://github.com/kolyvan/samizdat
//  this file is part of Samizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt


#import <Foundation/Foundation.h>

typedef enum {

    GoogleSearchStatusSuccess,
    GoogleSearchStatusHTTPFailure,  
    GoogleSearchStatusJSONFailure,      
    GoogleSearchStatusResponseFailure,       
    
} GoogleSearchStatus;

typedef void (^GoogleSearchResult)(GoogleSearchStatus status, NSString *details, NSArray *results);

@interface GoogleSearch : NSObject

+ (id) search: (NSString *)query 
        block: (GoogleSearchResult) block;

- (void) cancel;

@end