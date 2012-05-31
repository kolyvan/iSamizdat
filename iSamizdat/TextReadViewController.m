//
//  TextReadViewController.m
//  iSamizdat
//
//  Created by Kolyvan on 31.05.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//

#import "TextReadViewController.h"
#import "SamLibText.h"
#import "SamLibText+IOS.h"
#import "SamLibAuthor.h"
#import "SamLibAuthor+IOS.h"
#import "KxUtils.h"
#import "NSString+Kolyvan.h"
#import "NSDate+Kolyvan.h"
#import "NSDictionary+Kolyvan.h"
#import "KxMacros.h"
#import "DDLog.h"

extern int ddLogLevel;

NSString * mkHTMLPage(SamLibText * text, NSString * html)
{
    NSString *path = KxUtils.pathForResource(@"text.html");
    NSError *error;
    NSString *template = [NSString stringWithContentsOfFile:path 
                                                   encoding:NSUTF8StringEncoding 
                                                      error:&error];            
    if (!template.nonEmpty) {
        DDLogCWarn(@"file error %@", 
                   KxUtils.completeErrorMessage(error));
        return html;                
    }
    
    // replase css link from relative to absolute         
    template = [template stringByReplacingOccurrencesOfString:@"text.css" 
                                                   withString:KxUtils.pathForResource(@"text.css")];
    
    template = [template stringByReplacingOccurrencesOfString:@"<!-- TEXT_DATE -->" 
                                                   withString:text.dateModified];
    
    template = [template stringByReplacingOccurrencesOfString:@"<!-- TEXT_SIZE -->" 
                                                   withString:[text sizeWithDelta:@" "]];
    
    template = [template stringByReplacingOccurrencesOfString:@"<!-- TEXT_RATING -->" 
                                                   withString:[text ratingWithDelta:@" "]];
    
    if (text.note.nonEmpty)
        template = [template stringByReplacingOccurrencesOfString:@"<!-- TEXT_NOTE -->" 
                                                       withString:text.note];
    
    return [template stringByReplacingOccurrencesOfString:@"<!-- DOWNLOADED_TEXT -->" 
                                               withString:html];
}

/////

@interface TextReadViewController () {
    BOOL _needReload;
    BOOL _needRestoreOffset;
    id _version;
}
@property (nonatomic, strong) IBOutlet UIWebView * webView;
@end

@implementation TextReadViewController

@synthesize text = _text;
@synthesize webView = _webView;


- (void) setText:(SamLibText *)text 
{
    if (text != _text || 
        ![text.version isEqual:_version]) {        
        
        _version = text.version;
        _text = text;
        _needReload = YES;        
    }
}

- (id) init
{
    return [self initWithNibName:@"TextReadViewController" bundle:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.webView.delegate = self;    
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (_needReload) {        
        _needReload = NO;
        _needRestoreOffset = YES;
        self.title = _text.author.name;
        [self reloadWebView];
        //DDLogInfo(@"reload text %@", _text.path);           
    }
}


- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
   
    CGFloat y = _webView.scrollView.contentOffset.y;
    if (y < 10) 
        y = 0;
    _text.htmlOffset = y;
    //DDLogInfo(@"store offset %f", y);    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    _webView.delegate = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - private

- (void) restoreOffset
{
    if (_needRestoreOffset) {
        _needRestoreOffset = NO;        
        CGFloat y = _text.htmlOffset;
        if (y > 0) {            
            //DDLogInfo(@"restore offset %f", y);
            [_webView.scrollView setContentOffset:CGPointMake(0, y) 
                                         animated:YES]; 
        }
    }
}

- (void) reloadWebView
{    
    NSString *path = _text.htmlFile;
    if (!path)
        path = KxUtils.pathForResource(@"text.html");            
    [self loadWebViewFromPath: path];
}

- (void) loadWebViewFromPath: (NSString *) path
{
    NSURL *url = [NSURL fileURLWithPath:path isDirectory: NO];
    NSURLRequest * request = [NSURLRequest requestWithURL: url];    
    [_webView loadRequest:request];
}

- (void) selElement: (NSString *) idName 
              value: (NSString *) value 
{
    //NSString *js = KxUtils.format(@"setElement('%@', '%@');", idName, value);
    NSString *js =KxUtils.format(@"document.getElementById('%@').innerText = '%@';", idName, value);
    [_webView stringByEvaluatingJavaScriptFromString: js];
}

- (void) prepareHTML
{
    [self selElement:@"textName" value:_text.title];    
    
    if (_text.group.nonEmpty)
        [self selElement:@"textGroup" value:_text.group];        
    
    if (_text.type.nonEmpty)
        [self selElement:@"textType" value:_text.type];            
    
    if (_text.genre.nonEmpty)    
        [self selElement:@"textGenre" value:_text.genre];
    
    [self selElement:@"textFiletime" value:[_text.filetime shortRelativeFormatted]];                        
    
    [self selElement:@"commentsCount" value:[_text commentsWithDelta:@" "]];  
    
    if (_text.canUpdate) {
         NSString *s = KxUtils.format(locString(@"new version: %@"), [_text sizeWithDelta:@" "]);
        [self selElement:@"textReload"
                   value:s];
    }
}

#pragma mark - UIWebView delegate

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self prepareHTML];
    [self restoreOffset];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{    
}

- (BOOL)webView:(UIWebView *)webView 
shouldStartLoadWithRequest:(NSURLRequest *)request 
 navigationType:(UIWebViewNavigationType)navigationType
{
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        NSString *last = [request.URL lastPathComponent];
        
        if ([last isEqualToString:@"author"]) {
            
            NSURL *url = [NSURL URLWithString: KxUtils.format(@"http://%@", _text.author.url)];
            [UIApplication.sharedApplication openURL: url];            
            return NO;
        }
        
        if ([last isEqualToString:@"reload"]) {
            
            //[self reloadText];
            return NO;
        }
    }
    
    if (navigationType == UIWebViewNavigationTypeReload) {
        
        return NO;
    }
    
    return YES;
}

@end
