//  https://github.com/kolyvan/samizdat
//  this file is part of Samizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt



#import "SamLib.h"
#import "SamLibAgent.h"
#import "KxArc.h"
#import "KxMacros.h"
#import "KxUtils.h"
#import "NSDictionary+Kolyvan.h"
#import "NSDate+Kolyvan.h"
#import "NSString+Kolyvan.h"
#import "NSArray+Kolyvan.h"
#import "DDLog.h"
#import "JSONKit.h"

extern int ddLogLevel;

////

NSString * getStringFromDict(NSDictionary *dict, NSString *name, NSString *path)
{
    id value = [dict get:name];
    if (value &&
        ![value isKindOfClass:[NSString class]]) {
        
        DDLogCWarn(locString(@"invalid '%@' in dictionary: %@"), name, path);
        value = nil;
    }    
    
    return value;
}

NSDate * getDateFromDict(NSDictionary * dict, NSString *name, NSString *path)
{
    id ts = getStringFromDict(dict, name, path);
    if (ts)
        return [NSDate dateWithISO8601String: ts];
    return nil;
}

NSNumber * getNumberFromDict(NSDictionary *dict, NSString *name, NSString *path)
{
    id value = [dict get:name];
    if (value &&
        ![value isKindOfClass:[NSNumber class]]) {        
        DDLogCWarn(locString(@"invalid '%@' in dictionary: %@"), name, path);
        return nil;    
    }
    return value;
}

NSHTTPCookie * searchSamLibCookie(NSString *name)
{
    NSHTTPCookieStorage * storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];    
    NSArray * cookies;
    cookies = [storage cookiesForURL: [NSURL URLWithString: @"http://samlib.ru/"]];
    
    for (NSHTTPCookie *cookie in cookies)
        if ([cookie.name isEqualToString: name])            
            return cookie;
    return nil;
}

NSHTTPCookie * deleteSamLibCookie(NSString *name) 
{
    NSHTTPCookieStorage * storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];    
    NSArray * cookies;
    cookies = [storage cookiesForURL: [NSURL URLWithString: @"http://samlib.ru/"]];
    
    for (NSHTTPCookie *cookie in cookies)
        if ([cookie.name isEqualToString: name])            
        {
            NSHTTPCookie *result = [cookies copy];
            [storage deleteCookie:cookie];
            return KX_AUTORELEASE(result);
        }
    
    return nil;
}

void storeSamLibSessionCookies(BOOL save)
{
    if (save) {
        
        NSHTTPCookieStorage * storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];    
        NSArray * cookies = [storage cookiesForURL: [NSURL URLWithString: @"http://samlib.ru/"]]; 
        if (cookies.nonEmpty) {
            NSArray *session = [cookies filter:^(id elem) {
                return [elem isSessionOnly];
            }];                        
            [SamLibAgent.settings() update:@"session" 
                                     value:[session map:^(id elem){ return [elem properties];}]];
        }
        
    } else {
        
        [SamLibAgent.settings() removeObjectForKey:@"session"];
    }
}

void restoreSamLibSessionCookies()
{
    NSArray * session = [SamLibAgent.settings() get:@"session"];
    if (session.nonEmpty) {
        NSHTTPCookieStorage * storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        for (NSDictionary *dict in session) {
            NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties: dict];
            [storage setCookie:cookie];
            //DDLogInfo(@"set cookie %@: %@", cookie.name, cookie.value);
        }
    }
}

id loadObject(NSString *filepath, BOOL immutable)
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

NSDictionary * loadDictionaryEx(NSString *filepath, BOOL immutable)
{
    id obj = loadObject(filepath, immutable);
    if (obj == [NSNull null]) {
        return immutable ?  [NSDictionary dictionary] : [NSMutableDictionary dictionary];
    }
    return obj;
}

NSDictionary * loadDictionary(NSString *filepath)
{
    return loadDictionaryEx(filepath, YES);
}

BOOL saveDictionary(NSDictionary *dict, NSString * filepath)
{
    return saveObject(dict, filepath);
}

BOOL saveObject(id obj, NSString * filepath)
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

int levenshteinDistance(unichar* s1, int n, unichar *s2, int m)
{    
    int d[n+1][m+1];
    
    for (int i = 0; i <= n; i++)
        d[i][0] = i;
    
    for (int i = 0; i <= m; i++)    
        d[0][i] = i;
    
    for (int i = 1; i <= n; i++)
    {
        int s1i = s1[i - 1];
        
        for (int j = 1; j <= m; j++)
        {
            int s2j = s2[j - 1];
            int cost = s1i == s2j ? 0 : 1;
            
            int x = d[i-1][j  ] + 1;
            int y = d[i  ][j-1] + 1;
            int z = d[i-1][j-1] + cost;
            
            d[i][j] = MIN(MIN(x,y),z);
        }
    }
    return d[n][m];
}

int levenshteinDistanceNS(NSString* s1, unichar *s2, int m)
{
    int n = s1.length;
    
    unichar buffer1[n];
    [s1 getCharacters:buffer1 
                range:NSMakeRange(0, n)];
    
    return levenshteinDistance(buffer1, n, s2, m);
}

/////

@implementation SamLibBase

@synthesize path = _path; 
@synthesize timestamp  = _timestamp; 

@dynamic changed;
@dynamic url;
@dynamic relativeUrl;

- (BOOL) changed
{
    return NO;
}

- (NSString *) relativeUrl 
{  
    return @"";
}

- (NSString *) url 
{
    return [SamLibAgent.samlibURL() stringByAppendingPathComponent: self.relativeUrl];
}

- (id) version
{
    return [NSNull null];
}

- (id) initWithPath: (NSString *)path
{
    NSAssert(path.nonEmpty, @"empty path");
    
    self = [super init];
    if (self) {        
        
        _path = KX_RETAIN(path);
        _timestamp = KX_RETAIN([NSDate date]);
    }
    
    return self;
}

- (void) dealloc
{
    KX_RELEASE(_path);
    KX_RELEASE(_timestamp);    
    KX_SUPER_DEALLOC();
}

@end
