//
//  SamLibComments.m
//  samlib
//
//  Created by Kolyvan on 10.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//
//  https://github.com/kolyvan/samizdat
//  this file is part of Samizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt


#import "SamLibComments.h"
#import "KxArc.h"
#import "NSDictionary+Kolyvan.h"
#import "NSDate+Kolyvan.h"
#import "NSString+Kolyvan.h"
#import "NSArray+Kolyvan.h"
#import "KxMacros.h"
#import "KxUtils.h"
#import "DDLog.h"
#import "JSONKit.h"
#import "SamLibText.h"
#import "SamLibAuthor.h"
#import "SamLibAgent.h"
#import "SamLibParser.h"
#import "SamLibUser.h"
#import "SamLibStorage.h"

extern int ddLogLevel;

static NSInteger maxCommens()
{
    static NSInteger value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = SamLibAgent.settingsInt(@"comments.maxsize", 100);
    });
    return value;
}

static NSDate* mkDateFromComment(NSString *dt)
{
    return [NSDate date:dt
                 format:@"yyyy/MM/dd HH:mm" 
                 locale:nil 
               timeZone:[NSTimeZone timeZoneWithName:@"Europe/Moscow"]];
}

/////

@interface SamLibComment() {
    NSDictionary * _dict;
    NSDate * _timestamp;
    NSInteger _msgidNumber;
    BOOL _isNew;
}
@end

@implementation SamLibComment

@synthesize timestamp = _timestamp;
@synthesize isNew = _isNew;

@dynamic number, deleteMsg, name, link, color, msgid, replyto, message, isSamizdat;

- (NSInteger) number        { return [[_dict get:@"num"] integerValue]; }
- (NSString *) deleteMsg    { return [_dict get: @"deleteMsg"]; }
- (NSString *) name         { return [_dict get: @"name"]; }
- (NSString *) link         { return [_dict get: @"link"]; }
- (NSString *) color        { return [_dict get: @"color"]; }
- (NSString *) msgid        { return [_dict get: @"msgid"]; }
- (NSString *) replyto      { return [_dict get: @"replyto"]; }
- (NSString *) message      { return [_dict get: @"message"]; }
- (BOOL) isSamizdat         { return [_dict contains:@"samizdat"]; }
- (BOOL) canEdit            { return [[_dict get:@"canEdit"] boolValue]; }
- (BOOL) canDelete          { return [[_dict get:@"canDelete"] boolValue]; }

- (NSInteger) msgidNumber {
    if (!_msgidNumber)
        _msgidNumber = [self.msgid integerValue];
    return _msgidNumber; 
}

+ (id) fromDictionary: (NSDictionary *) dict
{ 
    SamLibComment *p = [[SamLibComment alloc] initWithDict:dict];       
    return KX_AUTORELEASE(p);
}

- (NSDictionary *) toDictionary
{    
    return _dict;
}

- (id) initWithDict: (NSDictionary *) dict
{
    NSAssert(dict.nonEmpty, @"empty dict");     
    self = [super init];
    if (self) {
        _dict = KX_RETAIN(dict);
        
        NSString* dt = getStringFromDict(dict, @"date", @"comment");
        if (dt)
            _timestamp = KX_RETAIN(mkDateFromComment(dt));
    }
    return self;
}

- (void) dealloc
{
    KX_RELEASE(_dict);
    KX_RELEASE(_timestamp);
    KX_SUPER_DEALLOC();
}

- (NSString *) description
{
    return KxUtils.format(@"<%@ %ld %ld %@>", 
                          NSStringFromClass([self class]), 
                          self.number,
                          self.msgidNumber, 
                          self.timestamp);
}

- (NSComparisonResult) compare: (SamLibComment *) other
{
    if (self.number < other.number)
        return NSOrderedAscending;
    if (self.number > other.number)            
        return NSOrderedDescending;
    
    return [self.timestamp compare:other.timestamp];           
}

- (BOOL) isEqualToComment:(SamLibComment *)other 
{
    if (self == other)
        return YES;    
    return  self.number == other.number;    
}

@end

////

@interface SamLibComments()
@property (readwrite, nonatomic, KX_PROP_STRONG) NSString * lastModified;
@property (readwrite, nonatomic, KX_PROP_STRONG) NSArray * all;
@end

@implementation SamLibComments

@synthesize text = _text;
//@synthesize all = _all;
@synthesize lastModified = _lastModified;
@synthesize isDirty = _isDirty;
@synthesize numberOfNew = _numberOfNew;
@dynamic changed;

- (id) version
{
    return [NSNumber numberWithInteger:_version];
}

- (NSArray *) all
{
    return KX_AUTORELEASE(KX_RETAIN(_all));
}

- (void) setAll:(NSArray *)all
{
    if (_all != all) {
        KX_RELEASE(_all);
        _all = KX_RETAIN(all);
        _isDirty = YES;
        _version++;
        self.timestamp = [NSDate date];        
    }
}

- (NSString *) relativeUrl
{
    // comment/i/iwanow475_i_i/zaratustra 
    NSString *s = [@"comment" stringByAppendingPathComponent:_text.author.relativeUrl];
    return [s stringByAppendingPathComponent: _path];
}

- (NSString *) filename
{
    return [_text.key stringByAppendingPathExtension:@"comments"];
}

- (BOOL) changed
{
    return _numberOfNew > 0;
}

+ (id) fromDictionary: (NSDictionary *)dict 
             withText: (SamLibText *) text
{

    NSAssert(dict.nonEmpty, @"empty dict");   
    
    SamLibComments * comments = [[SamLibComments alloc] initFromDictionary: dict 
                                                                  withText:text];

    return KX_AUTORELEASE(comments);
}

- (id) initWithText: (SamLibText *) text;
{
    return [self initFromDictionary:nil withText:text];
}

- (id) initFromDictionary: (NSDictionary *)dict 
                 withText: (SamLibText *) text;
{
    NSAssert(text != nil, @"nil text");     
    
    self = [super initWithPath:[text.path stringByDeletingPathExtension]];
    if (self) {
        
        _text = text;
        
        if (dict) {
        
            NSDate * dt = getDateFromDict(dict, @"timestamp", text.path);
            if (dt) self.timestamp = dt;
            
            //_subscribed = [[dict get: @"subscribed" orElse:[NSNumber numberWithBool:NO]] boolValue];    
            
            self.lastModified = getStringFromDict(dict, @"lastModified", text.path);    
            
            id p = [dict get:@"all"];
            if (p) {
                if ([p isKindOfClass:[NSArray class]]) {
                    
                    NSArray * a = p;
                    a = [a map:^id(id elem) {
                        return [SamLibComment fromDictionary:elem];
                    }];
                    _all = KX_RETAIN(a);
                    
                } else {
                    DDLogWarn(locString(@"invalid '%@' in dictionary: %@"), @"all", text.path);
                }
            }
        }
    }
    return self;
}

- (void) dealloc
{
    KX_RELEASE(_lastModified);
    KX_RELEASE(_all);
    KX_SUPER_DEALLOC();
}

- (NSDictionary *) toDictionary
{
    NSMutableDictionary * dict = [NSMutableDictionary dictionaryWithCapacity:3];
    
    [dict updateOnly: @"timestamp" valueNotNil: [_timestamp iso8601Formatted]]; 
    [dict updateOnly: @"lastModified" valueNotNil: _lastModified];    
    
    if (_all.nonEmpty) {
        NSArray * a = [_all map:^id(id elem) { return [elem toDictionary]; }];
        [dict update: @"all" value: a]; 
    }
    
    return dict;
}

- (void) updateComments: (NSArray *) result
{           
    if (_all.nonEmpty) {  
          
        NSMutableArray *ma = [result mutableCopy];
        
        // add all old comments not found in new 
        for (SamLibComment * p in _all) {            
            BOOL exists = [result exists:^(id elem) { 
                return [p isEqualToComment: elem];
            }];
            if (!exists)
                [ma push:p]; 
        }
        
        NSArray *final;
        if (ma.count < maxCommens()) {
            
            final = ma;
            
        } else {
        
            final = [ma take: maxCommens()];
        }
                        
        // determine and count new
        _numberOfNew = 0;        
        for (SamLibComment * p in final) {
            
            p.isNew = ![_all exists:^BOOL(id elem) {
                SamLibComment * p2 = elem;
                return p.number == p2.number && 
                    [p.timestamp isEqualToDate: p2.timestamp] &&
                    p.msgidNumber == p2.msgidNumber;
            }];
            
            if (p.isNew) {
                DDLogInfo(@"new %@", p);
                ++_numberOfNew;
            } 
        }
        
        if (_numberOfNew > 0) {
            self.all = final;
            //_isDirty = YES;
        }
        
        
    } else {        

        _numberOfNew = result.count;          
        self.all = result;        
        //_isDirty = YES;        
    }    
    
    //if (_isDirty)
    //    self.timestamp = [NSDate date];        
    
}

- (void) update: (NSString *)path
     parameters:  (NSDictionary *) parameters                      
           page: (NSInteger) page
         buffer: (NSMutableArray*)buffer
          force: (BOOL) force
          block: (UpdateCommentsBlock) block 
{
    
    SamLibAgent.fetchData(page > 0 ? [path stringByAppendingFormat:@"?PAGE=%ld", page + 1] : path, 
                          page ? nil : _lastModified, 
                          YES,
                          [@"http://" stringByAppendingString: self.url],
                          parameters,
                          ^(SamLibStatus status, NSString *data, NSString *lastModified) {
                              
                              if (status == SamLibStatusSuccess) {
                                  
                                  NSArray *comments = SamLibParser.scanComments(data);
                                  if (comments.nonEmpty) {
                                      
                                      if (lastModified.nonEmpty)
                                          self.lastModified = lastModified;
                                      
                                      //DDLogInfo(@"fetched %ld comments", comments.count);                                      
                                      
                                      NSArray *result = [comments map:^id(id elem) {
                                          return [SamLibComment fromDictionary:elem];  
                                      }];
                                      
                                      [buffer appendAll: result];
                                      
                                      if (!parameters && // parameters != nil on deleteComment call                                          
                                          buffer.count < maxCommens())
                                      {                                           
                                          BOOL isContinue;
                                          
                                          if (!force && _all.nonEmpty) {
                                              
                                              isContinue = NO;
                                              for (SamLibComment *p in result) {
                                                  
                                                  BOOL exists = [_all exists:^(id p2) {
                                                      return [p isEqualToComment: p2];
                                                  }];
                                                  if (!exists) {
                                                      // found new comment, continue fetch
                                                      isContinue = YES;
                                                      break;
                                                  }
                                              }
                                              
                                          } else {
                                              isContinue = YES;
                                          }
                                       
                                          
                                          if (isContinue) {
                                              [self update:path
                                                parameters:parameters
                                                      page:page + 1 
                                                    buffer:buffer 
                                                     force:force
                                                     block:block];
                                              return;                                           
                                          }
                                      }
                                  }
                              }    
                              
                              if (buffer.nonEmpty)
                                  [self updateComments: buffer];
                              if (page > 0) { // always success
                                  status = SamLibStatusSuccess;                              
                                  data = nil;
                              }
                              block(self, status, data);
                              
                          },
                          nil);
}

- (void) update: (BOOL) force 
          block: (UpdateCommentsBlock) block
{   
    _numberOfNew = 0;            
    [self update:self.relativeUrl 
     parameters:nil
            page:0 
          buffer:[NSMutableArray array] 
           force:force
           block:block];
}

- (void) deleteComment: (NSString *) msgid 
                 block: (UpdateCommentsBlock) block
{   

    _numberOfNew = 0;            
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"delete", @"OPERATION", msgid, @"MSGID", nil];
    [self update:self.relativeUrl 
      parameters:parameters
            page:0 
          buffer:[NSMutableArray array] 
           force:NO
           block:block];
}

+ (id) fromFile: (NSString *) filepath 
       withText: (SamLibText *) text
{
    NSFileManager * fm = [[NSFileManager alloc] init];    
    BOOL r = [fm isReadableFileAtPath:filepath];    
    KX_RELEASE(fm);    

    if (!r)
        return KX_AUTORELEASE([[SamLibComments alloc] initWithText:text]);
        
    NSDictionary *dict = SamLibStorage.loadDictionary(filepath);
    if (dict) {    
        if (dict.nonEmpty)
            return [SamLibComments fromDictionary:dict withText:text];
        return KX_AUTORELEASE([[SamLibComments alloc] initWithText:text]);
    }    
    return nil;
}

- (void) save: (NSString *)folder
{
    if (SamLibStorage.saveDictionary([self toDictionary], 
                                     [folder stringByAppendingPathComponent: self.filename])) {
        _isDirty = NO;
    }
}

- (void) post:(NSString *)message
        block: (UpdateCommentsBlock) block
{
    [self post:message
         msgid:nil
       isReply:NO
         block:block];
}

- (void) post: (NSString *) message 
        msgid: (NSString *) msgid        
      isReply: (BOOL) isReply
        block: (UpdateCommentsBlock) block
{
    SamLibUser *user = [SamLibUser currentUser];
    
    NSMutableDictionary * d = [NSMutableDictionary dictionary];    

    // /i/iwanow475_i_i/zaratustra
    NSString *url = [_text.relativeUrl stringByDeletingPathExtension];
    
    message = [message stringByReplacingOccurrencesOfString:@"\n" 
                                                 withString:@"\r"];
    
    [d update:@"FILE" value:url];
    [d update:@"TEXT" value:message];        
    [d update:@"NAME" value:user.name];
    [d update:@"EMAIL"value:user.email];
    [d update:@"URL"  value:user.isLogin ? user.homePage : user.url];     

    if (msgid.nonEmpty) {
        if (isReply)
            [d update:@"OPERATION" value:@"store_reply"];
        else
            [d update:@"OPERATION" value:@"store_edit"];
        [d update:@"MSGID" value:msgid];     
    } else {
        [d update:@"OPERATION" value:@"store_new" ];
        [d update:@"MSGID" value:@""];     
    }
   
    SamLibAgent.postData(@"/cgi-bin/comment",  
                         KxUtils.format(@"http://samlib.ru/cgi-bin/comment?COMMENT=%@", url), 
                         d,
                         YES,
                         ^(SamLibStatus status, NSString *data, NSString *lastModified) {

                             if (status == SamLibStatusSuccess) {
                                 
                                 if (SamLibParser.scanCommentsResponse(data)) {
                                 
                                     NSArray *comments = SamLibParser.scanComments(data);
                                     if (comments.nonEmpty) {
                                         
                                         if (lastModified.nonEmpty)
                                             self.lastModified = lastModified;

                                         [self updateComments: [comments map:^id(id elem) {
                                             return [SamLibComment fromDictionary:elem];  
                                         }]];
                                     }
                                                                      
                                 } else {
                                 
                                     data = locString(@"too many comments");
                                     status = SamLibStatusFailure;                                 
                                 }
                             }
                             
                             block(self, status, data);
                         });
    
}

@end
