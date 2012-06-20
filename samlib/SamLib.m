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
