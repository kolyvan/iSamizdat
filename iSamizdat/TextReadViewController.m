//
//  TextReadViewController.m
//  iSamizdat
//
//  Created by Kolyvan on 31.05.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//

#import "TextReadViewController.h"
#import "SamLibText.h"
#import "SamLibAuthor.h"
#import "SamLibAuthor+IOS.h"
#import "KxUtils.h"
#import "NSString+Kolyvan.h"
#import "KxMacros.h"

@interface TextReadViewController () {
    BOOL _needReload;
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
        self.title = _text.author.name;
        [self reloadWebView];
    }
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
    
    if (_text.dateModified.nonEmpty)        
        [self selElement:@"textDate" value:_text.dateModified];                    
    
    if (_text.note.nonEmpty)
        [self selElement:@"textNote" value:_text.note];  
    
    [self selElement:@"textSize" value:[_text sizeWithDelta:@" "]];    
    [self selElement:@"textRating" value:[_text ratingWithDelta:@" "]];                        
    
    [self selElement:@"commentsCount" value:[_text commentsWithDelta:@" "]];  
    
    if (_text.canUpdate)
        [self selElement:@"textReload"
                   value:locString(@"a new version is available")];
    
}

#pragma mark - UIWebView delegate

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self prepareHTML];
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
