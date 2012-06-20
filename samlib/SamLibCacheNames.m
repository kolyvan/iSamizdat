//
//  SamLibCacheNames.m
//  samlib
//
//  Created by Kolyvan on 17.06.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//
//  https://github.com/kolyvan/samizdat
//  this file is part of Samizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt


#import "SamLibCacheNames.h"
#import "KxArc.h"
#import "KxUtils.h"
#import "NSArray+Kolyvan.h"
#import "NSDictionary+Kolyvan.h"
#import "NSString+Kolyvan.h"
#import "FMDatabase.h"
#import "DDLog.h"

extern int ddLogLevel;

@interface SamLibCacheNames() {
    FMDatabase *db;    
    BOOL _status;
}
@end

@implementation SamLibCacheNames

- (BOOL) status
{
    return _status;
}

- (id) init
{
    self = [super init];
    if (self) {
        _status = YES;
    }
    return self;
}

- (void) dealloc
{
    [self close];    
    KX_SUPER_DEALLOC();
}

- (void) close
{
    [db close];
    KX_RELEASE(db);    
    db = nil;
}

- (BOOL) openDB
{
    if (!db && _status) {
                
        NSString *dbPath = [KxUtils.cacheDataPath() stringByAppendingPathComponent: @"names.db"];            
        BOOL needCreateTable = !KxUtils.fileExists(dbPath);
        
        db = [[FMDatabase alloc] initWithPath:dbPath];
                
        if (db) {
            
            if ([db open]) {
                
                if (needCreateTable) {
                    
                    NSString * sql = 
                    @"CREATE TABLE IF NOT EXISTS NAMES ("
                    @" ID INTEGER PRIMARY KEY AUTOINCREMENT,"
                    @" SECTION INTEGER,"                                        
                    @" PATH TEXT UNIQUE,"                    
                    @" NAME TEXT NOT NULL,"
                    @" INFO TEXT"
                    @")";
                    
                    [db executeUpdate:sql];
                    
                    if (db.hadError) {               
                        DDLogCWarn(@"DB ERR: %d %@", db.lastErrorCode, db.lastErrorMessage);
                        [db close];
                        db = nil;                                       
                        _status = NO;
                    } 
                }
                
            } else {
            
                DDLogCWarn(@"DB ERR: unable open db: %d %@", db.lastErrorCode, db.lastErrorMessage);               
                db = nil;
                _status = NO;
            }
            
        } else  {
            
            DDLogCError(@"DB ERR: unable create the database at path %@", dbPath);
            _status = NO;
        }  
    }
    
    return _status;
}

- (BOOL) hadName: (NSString *) name
{
    return [self selectByName:name].nonEmpty;
}

- (BOOL) hadPath: (NSString *) path
{
    return [self selectByPath:path].nonEmpty;
}

- (NSArray *) executeQuery: (NSString *) sql withArgs: (NSArray *)args
{
    if (![self openDB])
        return nil;

    FMResultSet *s = [db executeQuery:sql withArgumentsInArray: args];
    
    if (db.hadError) {
        DDLogCWarn(@"DB ERR: %d %@", db.lastErrorCode, db.lastErrorMessage);
        return nil;
    }    
    
    NSMutableArray *result = nil;
    
    while ([s next]) {
        
        if (!result) {
            result = [[NSMutableArray alloc] init];
        }
                
        NSString *path = [s stringForColumnIndex:0];
        NSString *name = [s stringForColumnIndex:1];                
        NSString *info = [s stringForColumnIndex:2];
        
        NSDictionary *dict = KxUtils.dictionary(path, @"path",
                                                name, @"name",
                                                info, @"info",
                                                nil);
        [result push: dict];
    }
    
    return KX_AUTORELEASE(result);
}

- (NSArray *) selectByPath: (NSString *) path
{
    NSAssert(path.nonEmpty, @"empty path"); 
    NSString *sql = @"SELECT PATH, NAME, INFO FROM NAMES WHERE PATH LIKE ? ORDER BY PATH";
    return [self executeQuery: sql 
                     withArgs:[NSArray arrayWithObject:path.lowercaseString]];
}

- (NSArray *) selectByName: (NSString *) name
{   
    NSAssert(name.nonEmpty, @"empty name");    
    NSString *sql = @"SELECT PATH, NAME, INFO FROM NAMES WHERE NAME LIKE ? ORDER BY PATH";
    return [self executeQuery: sql 
                     withArgs:[NSArray arrayWithObject:name]];
}

- (NSArray *) selectBySection:(unichar)section
{
    NSString *sql = @"SELECT PATH, NAME, INFO FROM NAMES WHERE SECTION=? ORDER BY PATH";
    return [self executeQuery: sql 
                     withArgs:[NSArray arrayWithObject:[NSNumber numberWithInt:section]]];

}

- (void) addPath: (NSString *) path 
        withName: (NSString *) name
        withInfo: (NSString *) info
{
    NSAssert(path.nonEmpty, @"empty path"); 
    NSAssert(name.nonEmpty, @"empty name");
        
    if (![self openDB])
        return;
    
    path = path.lowercaseString;        
    NSNumber *section = [NSNumber numberWithInt:path.first];    
    
    NSString * insert = @"INSERT OR REPLACE INTO NAMES (SECTION, PATH, NAME, INFO) VALUES (?, ?, ?, ?)";
    NSArray * args = KxUtils.array(section, path, name, info ? info: [NSNull null], nil);
                
    [db executeUpdate:insert withArgumentsInArray:args];
    
    if (db.hadError)        
        DDLogCWarn(@"DB ERR: %d %@", db.lastErrorCode, db.lastErrorMessage);
}

- (void) addBatch: (NSArray *) batch
{   
    if (!batch.nonEmpty)
        return;
    
    if (![self openDB])
        return;
    
    NSString * insert = @"INSERT OR REPLACE INTO NAMES (SECTION, PATH, NAME, INFO) VALUES (?, ?, ?, ?)";
        
    [db beginTransaction];
    
    for (NSDictionary *d in batch) {
        
        NSString *path = [d get:@"path"];
        NSString *name = [d get:@"name"];
        
        if (path.nonEmpty && name.nonEmpty) {

            id info = [d get:@"info" orElse:[NSNull null]];
            
            path = path.lowercaseString;        
            NSNumber *section = [NSNumber numberWithInt:path.first];    
            NSArray *args = KxUtils.array(section, path, name, info, nil);
            
            [db executeUpdate:insert withArgumentsInArray:args];
        } 
    }
    
    [db commit];
    
    if (db.hadError)        
        DDLogCWarn(@"DB ERR: %d %@", db.lastErrorCode, db.lastErrorMessage);
}

- (void) each: (void (^)(NSString *path, NSString *name, NSString *info)) block
{
    if (![self openDB])
        return;
    
    NSString *sql = @"SELECT PATH, NAME, INFO FROM NAMES";
    
    FMResultSet *s = [db executeQuery:sql];
    
    if (db.hadError) {
        DDLogCWarn(@"DB ERR: %d %@", db.lastErrorCode, db.lastErrorMessage);
        return;
    }    
        
    while ([s next]) {
        
        NSString *path = [s stringForColumnIndex:0];
        NSString *name = [s stringForColumnIndex:1];                
        NSString *info = [s stringForColumnIndex:2];
        
        block(path, name, info);
    }
}

@end

