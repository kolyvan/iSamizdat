//
//  SamLibParser.m
//  samlib
//
//  Created by Kolyvan on 07.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//
//  https://github.com/kolyvan/samizdat
//  this file is part of Samizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt


#import "SamLibParser.h"
#import "NSString+Kolyvan.h"
#import "NSDictionary+Kolyvan.h"
#import "NSArray+Kolyvan.h"
#import "NSDate+Kolyvan.h"
#import "KxTuple2.h"
#import "KxUtils.h"
#import "KxArc.h"
#import "KxMacros.h"
#import "DDLog.h"
#import <wctype.h>
#import <xlocale.h>

extern int ddLogLevel;

static NSString * const BGN_HREF = @"<A HREF=";
static NSString * const END_HREF = @"</A>";

#pragma mark - scanner helpers

static BOOL findTag(NSScanner *scanner, NSString *tag) 
{    
    return  [scanner scanString:tag intoString:nil] || 
            ([scanner scanUpToString:tag intoString:nil] && 
             [scanner scanString:tag intoString:nil]);   
}

static NSString* scanUpToTag(NSScanner *scanner, NSString *tag) 
{    
    if ([scanner scanString:tag intoString:nil]) 
        return @"";
    
    NSString *s;
    if ([scanner scanUpToString:tag intoString:&s] &&
        [scanner scanString:tag intoString:nil]) {
        return s;
    }
    
    return nil;
}

static NSString * nextTag(NSScanner *scanner, NSString *bgnTag, NSString *endTag) 
{
    if (findTag(scanner, bgnTag))
        return scanUpToTag(scanner, endTag);
    return nil;
}

static NSString * parseTag(NSString * s, NSString *bgnTag, NSString *endTag) 
{
    NSScanner * scanner = [NSScanner scannerWithString: s];
    return nextTag(scanner, bgnTag, endTag);
}

static NSString * nextLink(NSScanner *scanner) 
{
    return nextTag(scanner, BGN_HREF, END_HREF);
}

 NSString * removeHTMLComments(NSString *s)
{
    NSScanner * scanner = [NSScanner scannerWithString: s];        
    NSMutableString *sb = [NSMutableString string];
    
    NSInteger n1 = 0;
    
    while(!scanner.isAtEnd) {
                
        if (findTag(scanner, @"<!--")) {
            
            NSInteger n2 = scanner.scanLocation - @"<!--".length;    
            
            if (findTag(scanner, @"-->")) {
                [sb appendString:[s substringWithRange:NSMakeRange(n1, n2 - n1)]];
                n1 = scanner.scanLocation;
            }
        }
    }
    
    [sb appendString:[s substringWithRange:NSMakeRange(n1, scanner.scanLocation - n1)]];
    return sb;
}

static NSString * substringFromPattern(NSString *s, NSString *pattern) 
{    
    NSRange range = [s rangeOfString:pattern];
    if (range.location == NSNotFound) 
        return nil;    
    return [[s substringFromIndex:range.location + range.length] trimmed];    
}

static NSString *decodeEmail(NSString *email)
{    
    NSArray * a = [[email split:@"&#"] tail];
    a = [a map: ^(id elem) { return KxUtils.format(@"%c", [elem intValue]); }];
    return [a mkString];
}

#pragma mark - private interface

static KxTuple2* parseLink(NSString *link) 
{
    NSScanner *scanner = [NSScanner scannerWithString: link];
    NSString *path = scanUpToTag(scanner, @">");
    if (!path.nonEmpty)
        return nil;    
    NSString *title = nextTag(scanner, @"<b>", @"</b>");
    return [KxTuple2 first:path second: title];
}

static NSString * parseCopyright(NSString *s) 
{    
    NSScanner * scanner = [NSScanner scannerWithString: s];
    s = scanUpToTag(scanner, BGN_HREF);
    if (!s.nonEmpty) 
        return nil;    
    scanner = [NSScanner scannerWithString: s];
    return nextTag(scanner, @"<b>", @"</b>");    
}

static NSString* parseIsNew(NSString *s) 
{   
    // <font color=brown size=-2>New</font>
    
    NSScanner * scanner = [NSScanner scannerWithString: s];
    s = scanUpToTag(scanner, BGN_HREF);
    if (s.nonEmpty) 
    {   
        scanner = [NSScanner scannerWithString: s];
        
        if ([scanner scanString: @"<font color=" intoString:nil]) { 
            NSString *color = scanUpToTag(scanner, @"size=-2>");
            
            if ([scanner scanString: @"New</font>" intoString:nil]) {
                return [color trimmed];
            }
        } 
        
        //s = nextTag(scanner, @"<font color=", @"</font>");
        //if (s.nonEmpty) return [s contains:@"New"];
    }
    
    return nil;
}

static void parseRatingGroupGenreComments(NSScanner *scanner, NSMutableDictionary *dict) 
{    
    NSString *s = nextTag(scanner, @"<small>", @"</small>");   
        
    if (!s.nonEmpty)
        return;
    
    scanner = [NSScanner scannerWithString: s];
    NSString * untilAtag = scanUpToTag(scanner, BGN_HREF);
    
    NSString *comments = nil;
    if (untilAtag.nonEmpty)
        comments = nextTag(scanner, @"Комментарии: ", END_HREF);
    else
        untilAtag = s;
        
    scanner = [NSScanner scannerWithString: untilAtag];
    NSString *rating = nextTag(scanner, @"Оценка:<b>", @"</b>");
    
    NSInteger scanLoc = 0;
    
    if (rating.nonEmpty)                  
        scanLoc = scanner.scanLocation;
    else         
        scanner.scanLocation = 0;
    
    NSString *group = nextTag(scanner, @"\"", @"\"");
    //NSNumber *groupMark = nil;
    
    if (group.nonEmpty) {                 

        if ([SamLibParser.listOfGroups() containsObject:group]) {
            
            [dict update: @"type" value: group];
            group = nil;
            
        } else {
            
            //if (group.first == '@' || group.first == '*') {
            //    group = group.tail;
            //    groupMark = [NSNumber numberWithChar:group.first];;
            //}
        }
        
        scanLoc = scanner.scanLocation;         
    }
    
    NSString *genre = nil;
    if (scanLoc < untilAtag.length)
        genre = [[untilAtag drop:scanLoc] trimmed];
    
    [dict updateOnly: @"rating" valueNotNil: rating];
    [dict updateOnly: @"group" valueNotNil: group];  
    //[dict updateOnly: @"groupMark" valueNotNil: groupMark];      
    [dict updateOnly: @"genre" valueNotNil: genre];            
    [dict updateOnly: @"comments" valueNotNil: comments];
}

static NSString * parseNote(NSScanner *scanner) 
{    
    if (!findTag(scanner, @"<DD>")) 
        return nil;
    
    NSString *note = nextTag(scanner, @"<font color=", @"</font>");        
    NSRange r = [note rangeOfString:@">"];
    if (r.length > 0)
        return [note drop:r.location + r.length];    
    return note;    
}

static NSDictionary* parseText(NSString *text) 
{
    
    NSScanner *scanner = [NSScanner scannerWithString: text];
        
    NSString *link = nextLink(scanner);    
    if (!link.nonEmpty) {
        DDLogCWarn(locString(@"fail scan text: no link"));
        return nil;
    }
    
    KxTuple2* t = parseLink(link);
    if (!t) {
        DDLogCWarn(locString(@"fail scan text: invalid link"));
        return nil;
    }
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];      
    
    NSString *size = nextTag(scanner, @"<b>", @"</b>");
    parseRatingGroupGenreComments(scanner, dict); 
    NSString *note = parseNote(scanner);            
 
    NSString * copyright = parseCopyright(text);    
    NSString* flagNew = parseIsNew(text);

    [dict updateOnly: @"path" valueNotNil: t.first];
    [dict updateOnly: @"title" valueNotNil: t.second];            
    [dict updateOnly: @"size" valueNotNil:size];
    [dict updateOnly: @"note" valueNotNil: note];                    
    [dict updateOnly: @"copyright" valueNotNil: copyright];            
    [dict updateOnly: @"flagNew" valueNotNil: flagNew];                

    return dict;
}

static void parseCommentName(NSString *html, NSMutableDictionary *dict)
{
    // eva
    // <font color=red>eva</font>    
    // <noindex><a href="http://samlib.ru/i/iwanow475_i_i/" rel="nofollow">Иванов475 Иван Иванович</a></noindex>
    // *<noindex><a href="http://samlib.ru/i/iwanow475_i_i/" rel="nofollow"><font color=red>Иванов475 Иван Иванович</a></noindex> 
    
    NSString *name = nil, *link = nil, *color = nil;
    
    BOOL samizdat = [html hasPrefix:@"*"];
    
    if (samizdat) {
        html = html.tail; // drop *
        [dict update:@"samizdat" value:@"samizdat"];
    }
    
    if ([html hasPrefix: @"<noindex>"]) {
        
        NSScanner *scanner = [NSScanner scannerWithString: html];    
        
        link = nextTag(scanner, @"<a href=\"", @"\"");
        
        if (findTag(scanner, @"rel=\"nofollow\">")) {
            
            if ([scanner scanString: @"<font color=" intoString:nil]) { 
                
                color = scanUpToTag(scanner, @">");
            }                
            
            NSInteger scanLoc = scanner.scanLocation;
            name = scanUpToTag(scanner, @"</a></noindex>");
            if (!name.nonEmpty) { 
                // yes, sometimes samlib.ru returns a wrong formatted html 
                // such as an unclosed tag it this case                 
                name = [[html substringFromIndex:scanLoc] removeHTML];
            }
        }
    }     
    else  {
        
        if ([html hasPrefix: @"<font color="]) {
            
            NSScanner *scanner = [NSScanner scannerWithString: html];     
            
            color = nextTag(scanner, @"<font color=", @">");
            name = scanUpToTag(scanner, @"</font>");
            
        }
        else {
            name = html; 
        }
    }
    
    [dict updateOnly:@"name" valueNotNil:name];                 
    [dict updateOnly:@"link" valueNotNil:link];
    [dict updateOnly:@"color" valueNotNil:color];    
}

static NSString * parseCommentReplyLine(NSString *line)
{
    // <b> </b>&gt;<b> <b><i><font color=6060b0>23.carol</font></i></b></b><br>
    // Взяли с своих кораблей мы и, на три толпы разделяся,</b>
    
    NSScanner *scanner = [NSScanner scannerWithString: line];     
    
    if (findTag(scanner, @"<font color") &&
        findTag(scanner, @">")) {
        NSString *s = scanUpToTag(scanner, @"</font>");
        if (s.nonEmpty)
            return s;
    }
    
    if ([line hasSuffix:@"</b>"])
        return [line take:line.length - @"</b>".length];
    
    return line;
}

static NSDictionary * parseComment(NSString *html)
{
    NSMutableDictionary * dict = [NSMutableDictionary dictionary];
    
    NSScanner *scanner = [NSScanner scannerWithString: html];    
    
    // <small>22.</small>    
    NSString * num = nextTag(scanner, @"<small>", @".</small>");
    if (!num.nonEmpty) {
        DDLogCWarn(locString(@"fail scan comment: no number"));
        return nil;
    }
    
    NSInteger inum = [num integerValue];
    if (!inum) {
        DDLogCWarn(locString(@"fail scan comment: invalid number"));
        return nil;
    }    
    [dict update:@"num" value:[NSNumber numberWithInteger:inum]]; 
    
    if ([scanner scanString:@"<small><i>Удалено" intoString:nil]) {
        
        // <small><i>Удалено написавшим. 2012/04/28 12:47 
        
        NSString *deleteMsg = scanUpToTag(scanner, @". ");
        [dict update: @"deleteMsg" value: deleteMsg.nonEmpty ? deleteMsg : @""];

        [dict updateOnly:@"date" 
                 valueNotNil:[html substringWithRange:NSMakeRange(scanner.scanLocation, 16)]];
                
        return dict;
    }
    
    NSString * name = nextTag(scanner, @"<b>", @"</b>");
    if (!name.nonEmpty) {
        DDLogCWarn(locString(@"fail scan comment: no name"));        
        return nil;
    }
    
    parseCommentName(name, dict);  
    
    // parse email    
    int scanLoc = scanner.scanLocation;    
    NSString *email = nextTag(scanner, @"(<u>", @"</u>)");
    if (email.nonEmpty)
        [dict updateOnly:@"email" valueNotNil:decodeEmail(email)];        
    else
        scanner.scanLocation = scanLoc;    

    // <small><i>2012/04/28 17:26  </i>  
    NSString *date = nextTag(scanner, @"<small><i>", @"</i>");
    if (!date.nonEmpty) {
        DDLogCWarn(locString(@"fail scan comment: no date"));                
        return nil; 
    }
    
    //[dict updateOnly:@"timestamp" valueNotNil:timestamp];             
    [dict updateOnly:@"date" valueNotNil:[date trimmed]];             
    
    scanLoc = scanner.scanLocation;    
    
    if (findTag(scanner, @"?OPERATION=edit&MSGID="))
        [dict update:@"canEdit" value: [NSNumber numberWithBool:YES]];             
    scanner.scanLocation = scanLoc;
    
    if (findTag(scanner, @"?OPERATION=delete&MSGID="))
        [dict update:@"canDelete" value: [NSNumber numberWithBool:YES]];             
    scanner.scanLocation = scanLoc;
        
    // MSGID=13354318951378"    
    if (findTag(scanner, @"MSGID=")) {
        NSString * msgid = scanUpToTag(scanner, @"\"");
        [dict updateOnly:@"msgid" valueNotNil:msgid];             
    }
    
    if (findTag(scanner, @"</small></i>") &&
        findTag(scanner, @"<br>&nbsp;&nbsp;")) {
        
        NSString * s;
        s = [html drop: scanner.scanLocation];        
        s = [s stringByReplacingOccurrencesOfString:@"&nbsp;&nbsp;" withString:@""];
        s = [s stringByReplacingOccurrencesOfString:@"\r" withString:@""]; 
        s = [s stringByReplacingOccurrencesOfString:@"\n" withString:@""];         
        s = [s stringByReplacingOccurrencesOfString:@"<br>" withString:@"\n"];
        
        NSMutableString * replyto = [NSMutableString string];
        NSMutableString * message = [NSMutableString string];
        
        for (NSString * line in [s lines]) { 
            if ([line hasPrefix:@"&gt;<b>"]) {
                
                NSString * t = parseCommentReplyLine([line substringFromIndex:@"&gt;<b>".length]);   
                if (t.nonEmpty) {
                    [replyto appendString:[t stringByReplacingOccurrencesOfString: @"</b>&gt;<b>" withString:@""]];
                    [replyto appendString:@"\n"];                
                }
            }            
            else {
                [message appendString:line];
                [message appendString:@"\n"];
            }
        }
        
        if (message.nonEmpty)
            [dict update:@"message" value:message];         
        if (replyto.nonEmpty)
            [dict update:@"replyto" value:replyto];         
    }
    
    
    return dict;
}


#pragma mark - public interface

static NSDictionary * scanAuthorInfo(NSString *html)
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    NSScanner *scanner = [NSScanner scannerWithString: html];
    NSString *nametitle = nextTag(scanner, @"<h3>", @"</h3>");
    
    if (!nametitle.nonEmpty) {
        DDLogCWarn(locString(@"fail scan author: no title"));
        return nil;
    }
    
    NSInteger scanLoc = scanner.scanLocation;
    
    // parse info
    NSString *info = nil;
    
    if (findTag(scanner, @"<!----   Блок шапки (сведения об авторе) ----------->")) {
        info = scanUpToTag(scanner, @"</table>");
    }
       
    if (!info.nonEmpty) {
        scanner.scanLocation = scanLoc;        
        info = nextTag(scanner, 
                       @"<table width=50% align=right bgcolor=\"#e0e0e0\" cellpadding=5>", 
                       @"</table>");           
    }
    
    if (!info.nonEmpty) {
        DDLogCWarn(locString(@"fail scan author: no info"));        
        return nil;    
    }
    
    info = parseTag(info, @"<ul>", @"</ul>");
    
    if (!info.nonEmpty) {
        DDLogCWarn(locString(@"fail scan author: invalid info"));        
        return nil;
    }
    
    //parse about
    
    // 
    NSString *about = nextTag(scanner, 
                   @"<b><font color=#393939>Об авторе:</font></b><i>", 
                   @"</i>");  
    
    if (about.nonEmpty) {
        about = [about stringByReplacingOccurrencesOfString:@"<dd>" withString:@"\n"];
        about = [about stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@""];        
        [dict update:@"about" value:about];
    }
        
    // parse title
    scanner = [NSScanner scannerWithString: nametitle];
    
    NSString *name = scanUpToTag(scanner, @":<br>");    
    if (!name.nonEmpty) {
        DDLogCWarn(locString(@"fail scan author: invalid title"));                
        return nil;    
    }
    
    [dict update:@"name" value:name];    
    
    NSString *title = nextTag(scanner, @"<font color=\"#cc5555\">", @"</font>");
    [dict updateOnly:@"title" valueNotNil:title];
    
    // continue to parse a info
  
    NSArray *lines = [info lines];
    
    for (NSString * line in lines) {
        
        [dict updateOnce:@"updated" with:^id{
            return substringFromPattern(line, @"Обновлялось:</font></a></b>");
        }]; 
        
        [dict updateOnce:@"size" with:^id{
            return substringFromPattern(line, @"Объем:</font></a></b>");
        }];             
        
        [dict updateOnce:@"rating" with:^id{
            return substringFromPattern(line, @"Рейтинг:</font></a></b>");
        }];                         
        
        [dict updateOnce:@"visitors" with:^id{
             return substringFromPattern(line, @"Посетителей за год:</font></a></b>");
        }];                                     
        
        [dict updateOnce:@"www" with:^id{
            if ([line contains:@"<li><b>WWW:"])
                return parseTag(line, @"<a href=\"", @"\">");
            return nil;
        }];                                      

        [dict updateOnce:@"email" with:^id{
            if ([line contains:@"<li><b>Aдpeс:"]) {
                NSString * email = parseTag(line, @"<u>", @"</u>");                    
                if (email.nonEmpty)
                    return decodeEmail(email);
            }
            return nil;            
        }];
    }
    
    return dict;
}

static NSString * scanBody(NSString *html)
{
    NSScanner * scanner = [NSScanner scannerWithString: html];
    
    NSString *result = nil;
    
    if (findTag(scanner, @"<!-------- вместо <body> вставятся ссылки на произведения! ------>")) {     
        result = scanUpToTag(scanner, @"<!--------- Подножие ------------------------------->");  
    }
        
    if (!result.nonEmpty) {
        
        DDLogCWarn(locString(@"warning by scan texts: no HTML comment"));
        
        scanner.scanLocation = 0;
        
        if (findTag(scanner, @"<b>НАШИ КОНКУРСЫ:</b><br>") &&
            findTag(scanner, @"</td></tr></table>") &&
            findTag(scanner, @"<dl>"))
        {
            result = scanUpToTag(scanner, @"<div align=right><a href=stat.shtml>");
            if (result.nonEmpty)
                result = removeHTMLComments(result);        
        }
    }

    return [result trimmed];
}

static NSArray * scanTexts(NSString *body)
{
    NSScanner *scanner = [NSScanner scannerWithString: body];
    
    NSMutableArray *books = [NSMutableArray array];
    
    NSString *text = nil;
    while (nil != (text = nextTag(scanner, @"<DL><DT><li>", @"</DL>"))) {
        
        NSDictionary * p = parseText(text);
        if (p.nonEmpty)
            [books addObject:p];
    }
    return books;
}

static NSString * scanTextData(NSString *html)
{
    NSScanner *scanner = [NSScanner scannerWithString: html];    

    if (findTag(scanner, @"<!----------- Собственно произведение --------------->")) {   
        return scanUpToTag(scanner, @"<!--------------------------------------------------->");
    }
        
    DDLogCWarn(locString(@"warning by scan text data: no HTML comment"));    
    scanner.scanLocation = 0;
    
    if (findTag(scanner, @"<tr><td valign=top colspan=3>") &&
        findTag(scanner, @"<hr size=2 noshade>"))    
        return scanUpToTag(scanner, @"<hr size=2 noshade>");

    return nil;
}

static NSArray * scanComments(NSString *html)
{  
    NSScanner *scanner = [NSScanner scannerWithString: html];    
    if (findTag(scanner, @"href=/long.shtml>Полный") &&
        findTag(scanner, @"список...&gt;&gt;</a></div>") &&
        findTag(scanner, @"</td></tr></table>")) {
        
        html = scanUpToTag(scanner, @"</center><hr align=\"CENTER\" size=\"2\" noshade>");
        
        if (html.nonEmpty) {
         
            NSMutableArray * result = [NSMutableArray array];
            NSScanner *scanner = [NSScanner scannerWithString: html];    
            
            NSString * comment;
            do {
                comment = scanUpToTag(scanner, @"<hr noshade>");                
                if (comment.nonEmpty) {
                    NSDictionary *d = parseComment(comment);
                    if (d)
                        [result addObject: d];
                }
                
            } while(comment.nonEmpty);
    
            return result;
        }
    }    
    
    return nil;
}

static BOOL scanCommentsResponse(NSString *response)
{
    return ![response contains:@"<B>Извините, слишком много сообщений подряд. Разрешено не более 2</B>"];    
}

static BOOL scanLoginResponse(NSString * response)
{
    return ![response contains:@"Извините, неверные имя или пароль"];
}


static NSDictionary * scanTextPage(NSString *html)
{
    NSScanner *scanner = [NSScanner scannerWithString: html];

    NSString *title = nextTag(scanner, @"<center><h2>", @"</h2>");
    if (!title.nonEmpty) {
        DDLogCWarn(locString(@"fail scan text: no title"));
        return nil;
    }
    
    NSInteger scanLoc = scanner.scanLocation;    
    if (!findTag(scanner, @"<!---- Блок описания произведения (слева вверху) ----------------------->"))
    {
        scanner.scanLocation = scanLoc;
        if (!findTag(scanner, @"<table width=90% border=0 cellpadding=0 cellspacing=0>")) {
            DDLogCWarn(locString(@"fail scan text: no info"));
            return nil;
        }    
    }
    
    NSString *info = nextTag(scanner, @"<small><ul>", @"</ul></small>");
    if (!info.nonEmpty) {
        DDLogCWarn(locString(@"fail scan text: invalid html"));        
        return nil;
    }
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    [dict update:@"title" value:title];
    
    NSArray *lines = [info lines];
    
    for (NSString * line in lines) {
        
        [dict updateOnce:@"comments" with:^id{
            NSString *s = substringFromPattern(line, @"Комментарии: ");
            if (s.nonEmpty) {
                // Комментарии: 90, последний от 02/05/2012.
                NSScanner *scanner1 = [NSScanner scannerWithString: s];
                NSString *count = scanUpToTag(scanner1, @",");
                NSString *data = nextTag(scanner1, @"последний от ", @".");                
                return [count stringByAppendingFormat:@" (%@)", data];
            }
            return nil;
        }]; 
        
        [dict updateOnce:@"copyright" with:^id{
            NSString *s = substringFromPattern(line, @"<li>&copy; Copyright <a href=");
            if (s.nonEmpty) {
                // <li>&copy; Copyright <a href=/i/iwanow475_i_i/>Хайдеггер</a>
                NSScanner *scanner1 = [NSScanner scannerWithString: s];
                return nextTag(scanner1, @">", @"</a>");                
            }
            return nil;
        }]; 
        
        [dict updateOnce:@"size" with:^id{
            // <li>Размещен: 21/03/2012, изменен: 21/03/2012. 12k. <a href=stat.shtml            
            NSString *s = substringFromPattern(line, @"<li>Размещен: ");
            if (s.nonEmpty) {
                s = substringFromPattern(s, @". ");
                if (s.nonEmpty) {
                    
                    NSScanner *scanner1 = [NSScanner scannerWithString: s];
                    return scanUpToTag(scanner1, @". <a href"); 
                }
            }
            return nil;
        }]; 
        
        [dict updateOnce:@"dateModified" with:^id{
            // <li>Размещен: 21/03/2012, изменен: 21/03/2012. 12k. <a href=stat.shtml            
            NSString *s = substringFromPattern(line, @"<li>Размещен: ");
            if (s.nonEmpty) {                        
                NSScanner *scanner1 = [NSScanner scannerWithString: s];
                return nextTag(scanner1, @"изменен: ", @". ");                 
            }
            return nil;
        }]; 
 
        
        [dict updateOnce:@"type" with:^id{
            // <a href=/type/index_type_5-1.shtml>Статья</a>:             
            NSString *s = substringFromPattern(line, @"<a href=/type/index_type");
            if (s.nonEmpty) {
                NSScanner *scanner1 = [NSScanner scannerWithString: s];
                return nextTag(scanner1, @">", @"</a>");     
            }
            return nil;
        }]; 
        
        [dict updateOnce:@"genre" with:^id{
            // <a href="/janr/index_janr_10-1.shtml">Переводы</a>            
            NSString *s = substringFromPattern(line, @"<a href=\"/janr/index_janr");
            if (s.nonEmpty) {
                NSScanner *scanner1 = [NSScanner scannerWithString: s];
                return nextTag(scanner1, @">", @"</a>");     
            }
            return nil;
        }]; 
        
        [dict updateOnce:@"group" with:^id{
            // <a href=index.shtml#gr1>Философы XIX века</a>
            NSString *s = substringFromPattern(line, @"<a href=index");
            if (s.nonEmpty) {
                NSScanner *scanner1 = [NSScanner scannerWithString: s];
                return nextTag(scanner1, @">", @"</a>");     
            }
            return nil;
        }]; 
    }
    
    // Оценка: <b><a href=/cgi-bin/vote_show?DIR=k/kostin_k_k&FILE=mp_30>9.51*28</a></b>
    
    scanLoc = scanner.scanLocation;
    if (findTag(scanner, @"Оценка: <b><a href=/cgi-bin/vote_show")) {
        
        NSString *rating = nextTag(scanner, @">", @"</a></b>");
        [dict updateOnly:@"rating" valueNotNil:rating];
        
    }
    else {
        scanner.scanLocation = scanLoc;
    }
    
    if (findTag(scanner, @"<ul><small><li></small><b>Аннотация:</b><br>")) {
        
        NSString *note = nextTag(scanner, @"<i>", @"</i></font");
        [dict updateOnly:@"note" valueNotNil:note];
    }
        
    return dict;
}

static NSArray * listOfGroups()
{
    static NSString * groups[] = {
        @"Роман",
        @"Повесть",
        @"Глава",
        @"Сборник рассказов",
        @"Рассказ",
        @"Поэма",
        @"Сборник стихов",
        @"Стихотворение",
        @"Эссе",
        @"Очерк",
        @"Статья",
        @"Монография",
        @"Справочник",
        @"Песня", 
        @"Новелла",
        @"Пьеса; сценарий",
        @"Миниатюра",
        @"Интервью",
    }; 

    static NSArray * array = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        array = [[NSArray alloc] initWithObjects:groups 
                                           count:sizeof(groups)/sizeof(id)];
    });
    
    return array;
}

static NSArray * scanAuthors(NSString *html)
{
    // 
    // <DL><a href=/a/a_a/>А Аяма</a> "Ситком"(45k,8)</DL>
    // DL><font color=gray size=-2>New</font><a href=/k/kolywan/>Колыван</a>
    
    NSScanner *scanner = [NSScanner scannerWithString: html];
    
    if (!findTag(scanner, @"</td></tr></table>"))
        return nil;
    
    NSMutableArray *result = [NSMutableArray array];
    
    NSString *author = nil;
    while (!scanner.isAtEnd &&
           nil != (author = nextTag(scanner, @"<DL>", @"</DL>"))) {

         NSScanner *scanner1 = [[NSScanner alloc] initWithString: author];
        
        if (findTag(scanner1, @"<a href=/")) {
                                  
            NSString *path = scanUpToTag(scanner1, @"/>");     
            if (path.nonEmpty) {
                
                path = [path drop:2];
                
                NSString *name = scanUpToTag(scanner1, @"</a>");       
                if (name.nonEmpty) {
                   
                    //NSString *info =  [author substringFromIndex:scanner1.scanLocation];                    
                    NSString *info =  nextTag(scanner1, @"\"", @"\"");
                    if (!info.nonEmpty) info = @"";
                                       
                    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                                          path, @"path", 
                                          name, @"name",
                                          info, @"info",
                                          @"samlib", @"from",                                                                
                                          nil];
                    
                    [result push: dict];
                    
                }
            }
        } 
        
        KX_RELEASE(scanner1);
    }
    
    return result;
}

typedef struct {
    unichar letter;
    char * path;
} IndexEntry;

static locale_t locale_ru() {
    
    static locale_t loc;    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        loc = newlocale(LC_CTYPE_MASK , "ru_RU", NULL);
    });
    
    return loc;
}

static NSString * cyrillicToLatin(unichar first)
{   
    IndexEntry cyrillic [33] = {
        { 1040, "a" }, // А
        { 1041, "b" }, // Б  
        { 1042, "w" }, // В
        { 1043, "g" }, // Г
        { 1044, "d" }, // Д
        { 1045, "e" }, // Е
        { 1025, "yo" }, // Ё
        { 1046, "zh" }, // Ж
        { 1047, "z" }, // З
        { 1048, "i" }, // И
        { 1049, "ij" }, // Й
        { 1050, "k" }, // К
        { 1051, "l" }, // Л
        { 1052, "m" }, // М
        { 1053, "n" }, // Н
        { 1054, "o" }, // О
        { 1055, "p" }, // П
        { 1056, "r" }, // Р
        { 1057, "s" }, // С
        { 1058, "t" }, // Т
        { 1059, "u" }, // У
        { 1060, "f" }, // Ф
        { 1061, "h" }, // Х
        { 1062, "c" }, // Ц        
        { 1063, "ch" }, // Ч
        { 1064, "sh" }, // Ш
        { 1065, "sw" }, // Щ
        { 1066, "x" }, // Ъ
        { 1067, "y" }, // Ы
        { 1068, "z" }, // Ь
        { 1069, "ae" }, // Э
        { 1070, "ju" }, // Ю
        { 1071, "ja" }, // Я
    };    
    
    first = towupper_l(first, locale_ru());
    
    for (int i = 0; i < 33; ++i) {
        if (cyrillic[i].letter == first)
            return [NSString stringWithCString:cyrillic[i].path 
                                      encoding:NSASCIIStringEncoding];
    }    
    
    return nil;
}

static NSString * captitalToPath(unichar first)
{   
    IndexEntry cyrillic [33] = {
        { 1040, "a/" }, // А
        { 1041, "b/" }, // Б  
        { 1042, "w/" }, // В
        { 1043, "g/" }, // Г
        { 1044, "d/" }, // Д
        { 1045, "e/" }, // Е
        { 1025, "e/index_yo.shtml" }, // Ё
        { 1046, "z/index_zh.shtml" }, // Ж
        { 1047, "z" }, // З
        { 1048, "i/" }, // И
        { 1049, "j/index_ij.shtml" }, // Й
        { 1050, "k/" }, // К
        { 1051, "l/" }, // Л
        { 1052, "m/" }, // М
        { 1053, "n/" }, // Н
        { 1054, "o/" }, // О
        { 1055, "p/" }, // П
        { 1056, "r/" }, // Р
        { 1057, "s/" }, // С
        { 1058, "t/" }, // Т
        { 1059, "u/" }, // У
        { 1060, "f/" }, // Ф
        { 1061, "h/" }, // Х
        { 1062, "c/" }, // Ц        
        { 1063, "c/index_ch.shtml" }, // Ч
        { 1064, "s/index_sh.shtml" }, // Ш
        { 1065, "s/index_sw.shtml" }, // Щ
        { 1066, "x/" }, // Ъ
        { 1067, "y/" }, // Ы
        { 1068, "z/" }, // Ь
        { 1069, "e/index_ae.shtml" }, // Э
        { 1070, "j/index_ju.shtml" }, // Ю
        { 1071, "j/index_ja.shtml" }, // Я
    };    
    
    if ((first > 47 && first < 58) || 
        (first > 64 && first < 91)) {
                
        first = towlower(first);
        return KxUtils.format(@"%c/index_%c.shtml", first, first);        
    }
    
    first = towupper_l(first, locale_ru());
    
    for (int i = 0; i < 33; ++i) {
        if (cyrillic[i].letter == first)
            return [NSString stringWithCString:cyrillic[i].path 
                                      encoding:NSASCIIStringEncoding];
    }    
    
    return nil;
}

SamLibParser_t SamLibParser = {
    scanAuthorInfo,
    scanBody,
    scanTexts,
    scanTextData,
    scanComments,
    scanCommentsResponse,
    scanLoginResponse,
    scanTextPage,
    listOfGroups,
    scanAuthors,
    captitalToPath,
    cyrillicToLatin,
};
