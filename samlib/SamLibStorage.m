//
//  SamLibStorage.m
//  samlib
//
//  Created by Kolyvan on 20.06.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//

#import "SamLibStorage.h"

#import "KxUtils.h"
#import "KxArc.h"
#import "KxMacros.h"
#import "NSArray+Kolyvan.h"
#import "NSString+Kolyvan.h"
#import "NSDictionary+Kolyvan.h"
#import "DDLog.h"
#import "JSONKit.h"
#import "SamLibAgent.h"

extern int ddLogLevel;

#ifdef DEBUG
//#define _DEVELOPMENT_MODE_
#endif

static void enumerateFolder(NSString *folder, EnumerateFolderBlock block)
{
    NSFileManager *fm = [[NSFileManager alloc] init];
    
    NSError *error;
    NSArray * files = [fm contentsOfDirectoryAtPath:folder
                                              error:&error];
    if (files) {
        
        for (NSString *filename in files) {
            
            if (filename.first != '.') {
                
                NSString * fullpath = [folder stringByAppendingPathComponent:filename];
                NSDictionary *attr = [fm attributesOfItemAtPath:fullpath error:nil];
                
                if ([[attr get:NSFileType] isEqual: NSFileTypeRegular]) {
                    
                    block(fm, fullpath, attr);                    
                }
            }
        }        
        
    } else {
        
        DDLogCError(locString(@"file error: %@"), 
                    KxUtils.completeErrorMessage(error));        
    }
    
      KX_RELEASE(fm);
}

static unsigned long long sizeOfFolder(NSString *folder)
{ 
    unsigned long long __block totalSize = 0;
    
    enumerateFolder(folder,
                    ^(NSFileManager *fm, NSString *fullpath, NSDictionary *attr){
                        
                        NSNumber *size = [attr get:NSFileSize];                    
                        totalSize += size.unsignedLongLongValue;
                    });  
    
    return totalSize;
}

static void cleanupFolder(NSString *folder)
{   
    enumerateFolder(folder,
                    ^(NSFileManager *fm, NSString *fullpath, NSDictionary *attr){
                        
                        NSError *error;
                        if (![fm removeItemAtPath:fullpath error:&error]) {
                            
                            DDLogCError(locString(@"file error: %@"), 
                                        KxUtils.completeErrorMessage(error));        
                        }                    
                    });
}

static NSString * authorsPath()
{
    static NSString * path = nil;
    
    if (!path) {
        
#ifdef _DEVELOPMENT_MODE_
        path = [@"~/tmp/samlib/authors/" stringByExpandingTildeInPath];
#else
        path = KX_RETAIN([KxUtils.privateDataPath() stringByAppendingPathComponent: @"authors"]);
#endif              
        KxUtils.ensureDirectory(path);        
    }
    
    return path;
}

static NSString * textsPath()
{
    static NSString * path = nil;
    
    if (!path) {
#ifdef _DEVELOPMENT_MODE_                  
        path = [@"~/tmp/samlib/texts/" stringByExpandingTildeInPath];
#else
        path = KX_RETAIN([KxUtils.cacheDataPath() stringByAppendingPathComponent: @"texts"]);
#endif  
        KxUtils.ensureDirectory(path);                
    }
    
    return path;
}

static NSString * commentsPath()
{
    static NSString * path = nil;
    
    if (!path) {
#ifdef _DEVELOPMENT_MODE_            
        path = [@"~/tmp/samlib/comments/" stringByExpandingTildeInPath];
#else
        path = KX_RETAIN([KxUtils.cacheDataPath() stringByAppendingPathComponent: @"comments"]);
#endif      
        KxUtils.ensureDirectory(path);                
    }
    
    return path;
}

static NSString * namesPath()
{
    static NSString * path = nil;
    
    if (!path) {
#ifdef _DEVELOPMENT_MODE_            
        path = [@"~/tmp/samlib/names" stringByExpandingTildeInPath];
#else
        path = KX_RETAIN([KxUtils.cacheDataPath() stringByAppendingPathComponent: @"names"]);
#endif      
        KxUtils.ensureDirectory(path);
    }
    
    return path;
}

static NSString * bansPath()
{
    NSString * path = nil;

#ifdef _DEVELOPMENT_MODE_            
        path = [@"~/tmp/samlib/bans" stringByExpandingTildeInPath];
#else
        path = [KxUtils.privateDataPath() stringByAppendingPathComponent: @"bans"];
#endif      

    return path;
}

static unsigned long long sizeOfTexts()
{ 
    return sizeOfFolder(textsPath());
}

static unsigned long long sizeOfComments()
{
    return sizeOfFolder(commentsPath());
}

static unsigned long long sizeOfNames()
{
    return sizeOfFolder(namesPath());
}

static void cleanupTexts()
{
    cleanupFolder(textsPath());
}

static void cleanupComments()
{
    cleanupFolder(commentsPath());
}

static void cleanupNames()
{
    cleanupFolder(namesPath());    
}

static BOOL allowTexts()
{
    return SamLibAgent.settingsBool(@"storage.allowTexts", YES);    
}

static BOOL allowComments()
{
    return SamLibAgent.settingsBool(@"storage.allowComments", YES);    
}

static BOOL allowNames()
{
    return SamLibAgent.settingsBool(@"storage.allowNames", YES);    
}

static void setAllowTexts(BOOL allow)
{
    SamLibAgent.setSettingsBool(@"storage.allowTexts", allow, YES);     
}

static void setAllowComments(BOOL allow)
{
    SamLibAgent.setSettingsBool(@"storage.allowComments", allow, YES);         
}

static void setAllowNames(BOOL allow)
{
    SamLibAgent.setSettingsBool(@"storage.allowNames", allow, YES);             
}

static id loadObject(NSString *filepath, BOOL immutable)
{
    NSFileManager * fm = [[NSFileManager alloc] init];    
    BOOL r = [fm isReadableFileAtPath:filepath];    
    KX_RELEASE(fm);    
    
    if (!r) {        
        DDLogCWarn(locString(@"file not found: %@"), filepath);         
        return nil;        
    }         
    
    NSError * error = nil;    
    NSData * data = [NSData dataWithContentsOfFile:filepath
                                           options:0
                                             error:&error];
    if (!data) {
        DDLogCError(locString(@"file error: %@"), 
                    KxUtils.completeErrorMessage(error));         
        return nil;
    }
    
    if (data.length == 0) 
        return [NSNull null];
    
    id obj;
    if (immutable)                
        obj = [data objectFromJSONDataWithParseOptions: JKParseOptionNone
                                                 error: &error];
    else
        obj = [data mutableObjectFromJSONDataWithParseOptions: JKParseOptionNone
                                                        error: &error];
    
    if (!obj) {
        DDLogCError(locString(@"json error: %@"), 
                    KxUtils.completeErrorMessage(error));
    }
    
    return obj;
}

static NSDictionary * loadDictionaryEx(NSString *filepath, BOOL immutable)
{
    id obj = loadObject(filepath, immutable);
    if (obj == [NSNull null]) {
        return immutable ?  [NSDictionary dictionary] : [NSMutableDictionary dictionary];
    }
    return obj;
}

static NSDictionary * loadDictionary(NSString *filepath)
{
    return loadDictionaryEx(filepath, YES);
}

static BOOL saveObject(id obj, NSString *filepath)
{
    NSError * error = nil;    
    NSData * json = [obj JSONDataWithOptions:JKSerializeOptionPretty 
                                       error:&error];
    if (!json) {
        
        DDLogCError(locString(@"json error: %@"), 
                    KxUtils.completeErrorMessage(error));        
        return NO;
    }
    
    error = nil;
    if (![json writeToFile:filepath
                   options:0 
                     error:&error]) {
        
        DDLogCError(locString(@"file error: %@"), 
                    KxUtils.completeErrorMessage(error));        
        
        return NO;
    }    
    return YES;
}


static BOOL saveDictionary(NSDictionary *dict, NSString * filepath)
{
    return saveObject(dict, filepath);
}

SamLibStorage_t SamLibStorage = {
  
    authorsPath,
    textsPath,
    commentsPath,
    namesPath,
    bansPath,
    
    enumerateFolder,
    
    sizeOfTexts,
    sizeOfComments,
    sizeOfNames,
    
    cleanupTexts,
    cleanupComments,
    cleanupNames,
    
    allowTexts,
    allowComments,
    allowNames,
    
    setAllowTexts,
    setAllowComments,
    setAllowNames,
    
    loadObject,    
    loadDictionary,
    loadDictionaryEx,    
    saveObject,
    saveDictionary,
};