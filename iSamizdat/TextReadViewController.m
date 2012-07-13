//
//  TextReadViewController.m
//  iSamizdat
//
//  Created by Kolyvan on 31.05.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//
//  https://github.com/kolyvan/iSamizdat
//  this file is part of iSamizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt
// 

#import "TextReadViewController.h"
#import "SamLibText.h"
#import "SamLibText+IOS.h"
#import "SamLibAuthor.h"
#import "SamLibAuthor+IOS.h"
#import "SamLibHistory.h"
#import "KxUtils.h"
#import "NSString+Kolyvan.h"
#import "NSDate+Kolyvan.h"
#import "NSDictionary+Kolyvan.h"
#import "AppDelegate.h"
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
    
    template = [template stringByReplacingOccurrencesOfString:@"<!-- TEXT_AUTHOR -->" 
                                                   withString:text.author.name];   

    template = [template stringByReplacingOccurrencesOfString:@"<!-- TEXT_NAME -->" 
                                                   withString:text.title];    

    NSString * date = [[NSDate date] formattedDatePattern:@"d MMM yyyy HH:mm Z" 
                                                 timeZone:nil 
                                                   locale:[[NSLocale alloc] initWithLocaleIdentifier:@"ru_RU"]];
    
    template = [template stringByReplacingOccurrencesOfString:@"<!-- TEXT_DATE -->" 
                                                   withString:date];
    
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
    BOOL _fullScreen;
    BOOL _prevNavBarTranslucent;
    UISwipeGestureRecognizer *gestureRecognizer; 
    UIPinchGestureRecognizer *pinchGestureRecognizer;
    CGFloat _prevScale;
}
@property (nonatomic, strong) IBOutlet UIWebView * webView;
@property (nonatomic, strong) SSPullToRefreshView *pullToRefreshView;
@property (nonatomic, strong) UIBarButtonItem *stopButton;
@end

@implementation TextReadViewController

@synthesize text = _text;
@synthesize webView = _webView;
@synthesize pullToRefreshView, stopButton;

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
    self = [self initWithNibName:@"TextReadViewController" bundle:nil];
    if (self) {
        self.title = locString(@"Text");
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.webView.delegate = self;
        
    gestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self 
                                                                  action:@selector(handleSwipe:)];    

    gestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight  | UISwipeGestureRecognizerDirectionLeft; 
    //gestureRecognizer.delegate = self;    
    [self.webView addGestureRecognizer:gestureRecognizer];
    
    pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self 
                                                                       action:@selector(handlePinch:)];  
    [self.webView addGestureRecognizer:pinchGestureRecognizer];
    
    self.pullToRefreshView = [[SSPullToRefreshView alloc] initWithScrollView:self.webView.scrollView
                                                                    delegate:self];
        
    self.stopButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop 
                                                                    target:self 
                                                                    action:@selector(goStop)];

}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (_needReload) {        
        _needReload = NO;
        _needRestoreOffset = YES;
        [self reloadWebView];        
        //DDLogInfo(@"reload text %@", _text.path);   
    }
    
    _prevScale = 1.0f;
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //[self performSelector:@selector(fullscreenMode:) 
    //           withObject:[NSNumber numberWithBool:YES] 
    //           afterDelay:1];        
    //[self fullscreenMode: YES];
    
    //_prevNavBarTranslucent = self.navigationController.navigationBar.translucent;
    //self.navigationController.navigationBar.translucent = YES;
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
       
    CGFloat offset = 0;
    CGFloat value = _webView.scrollView.contentOffset.y;
    if (value > 10) {
        CGFloat size = _webView.scrollView.contentSize.height;
        offset = value / size;
    }
    _text.scrollOffset = offset;
    //DDLogInfo(@"store offset %f", offset); 
    
    if (_fullScreen)
        [self fullscreenMode: NO];
    
    if (_text.htmlFile.nonEmpty)
        [[SamLibHistory shared] addText:_text];
    
    //self.navigationController.navigationBar.translucent = _prevNavBarTranslucent;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    _webView.delegate = nil;
    
    [self.webView removeGestureRecognizer:gestureRecognizer];
    gestureRecognizer = nil;
    
    self.pullToRefreshView = nil;
    self.stopButton = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - pull to refresh

- (void) showSuccessNoticeAboutReloadResult: (NSString *) message
{        
    [[AppDelegate shared] successNoticeInView:self.view 
                                        title:message.nonEmpty ? message : locString(@"Reload success")];    
}

- (void) showFailureNoticeAboutReloadResult: (NSString *) message
{   
    [[AppDelegate shared] errorNoticeInView:self.view 
                                      title:locString(@"Reload failure") 
                                    message:message.nonEmpty ? message : @""];        
}

- (void) handleStatus: (SamLibStatus) status 
          withMessage: (NSString *)message
{
    if (status == SamLibStatusFailure) {
        
        [self performSelector:@selector(showFailureNoticeAboutReloadResult:) 
                   withObject:message
                   afterDelay:0.3];
        
    } else if (status == SamLibStatusSuccess) {            
        
        [self performSelector:@selector(showSuccessNoticeAboutReloadResult:) 
                   withObject:message
                   afterDelay:0.3];
        
    }  else if (status == SamLibStatusNotModifed) {            
        
        [self performSelector:@selector(showSuccessNoticeAboutReloadResult:) 
                   withObject:locString(@"Not modified")
                   afterDelay:0.3];
    }
    
    if (status == SamLibStatusSuccess) {
        [self reloadWebView];
    }
}

- (IBAction) goStop
{
    SamLibAgent.cancelAll();
    [self.pullToRefreshView finishLoading];
    self.navigationItem.rightBarButtonItem = nil;    
}

- (void)pullToRefreshViewDidStartLoading:(SSPullToRefreshView *)view 
{   
    self.navigationItem.rightBarButtonItem = self.stopButton;
    
    [self.pullToRefreshView.contentView setLastUpdatedAt:_text.timestamp
                                   withPullToRefreshView:self.pullToRefreshView]; 
    
    [self.pullToRefreshView startLoading];  
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
           
    [_text update:^(SamLibText *text, SamLibStatus status, NSString *error) {
                        
        [self.pullToRefreshView finishLoading];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;        
        self.navigationItem.rightBarButtonItem = nil;
        
        NSString *message = (status == SamLibStatusFailure) ? error : nil;
        [self handleStatus: status withMessage:message];        
    }
         progress: nil
        formatter: ^(SamLibText *text, NSString * html) { 
            return mkHTMLPage(text, html); 
        } 
     ];
}

#pragma mark - private

- (void)handleSwipe:(UISwipeGestureRecognizer *)sender 
{   
    if (sender.state == UIGestureRecognizerStateEnded) {

        [self fullscreenMode: !_fullScreen];        
    } 
}

- (void)handlePinch:(UIPinchGestureRecognizer *)sender 
{
    if (sender.state == UIGestureRecognizerStateChanged) {
               
        if (fabs(_prevScale - sender.scale) > 0.05) {

            _prevScale = sender.scale;
            NSString *js = KxUtils.format(@"document.body.style.zoom = %.2f;", sender.scale);
            [self.webView stringByEvaluatingJavaScriptFromString: js];
        }
    } 
}

/*
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    CGPoint pt = [touch locationInView:self.webView];
    CGRect bounds = self.webView.bounds;
    CGFloat w = bounds.size.width;
    CGFloat l = bounds.origin.x + w * .33;
    CGFloat r = bounds.origin.x + w * .66;    
    
    if ((pt.x > l) && (pt.x < r)) {
        DDLogInfo(@"gestureRecognizer");
        return YES;        
    }
    
    return NO;
}
 */

- (void) fullscreenMode: (BOOL) on
{   
    //self.wantsFullScreenLayout = YES;    
    
    _fullScreen = on;
    
    [UIView transitionWithView:self.view
                      duration:0.2
                       options:UIViewAnimationOptionTransitionNone
                    animations:^{
                        
                        UIApplication *app = [UIApplication sharedApplication];
                        
                        CGRect bounds = [UIScreen mainScreen].bounds;    
                        
                        if (on) {        
                            
                            CGFloat tabbarHeight = self.tabBarController.tabBar.bounds.size.height;                            
                                                                 
                            bounds.origin.y = -20;
                            bounds.size.height += 20;
                            bounds.size.height += tabbarHeight;
                        }
                        
                        [app setStatusBarHidden:on withAnimation:UIStatusBarAnimationSlide];    
                        app.keyWindow.frame = bounds;                        
                        [self.navigationController setNavigationBarHidden:on animated:YES];
                        [self.tabBarController.tabBar setHidden:on];
                        
                    }
                    completion:nil];
}

- (void) restoreOffset
{
    if (_needRestoreOffset) {
        _needRestoreOffset = NO;        
        CGFloat offset = _text.scrollOffset;
        if (offset > 0) {                   
            //DDLogInfo(@"restore offset %f", offset);             
            CGFloat size = _webView.scrollView.contentSize.height;
            //CGRect frame = _webView.scrollView.frame;            
            //frame.origin.y = offset * size;                                
            //[_webView.scrollView scrollRectToVisible:frame animated:NO];            
            [_webView.scrollView setContentOffset:CGPointMake(0, offset * size) animated:NO]; 
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
    [_webView loadRequest:[NSURLRequest requestWithURL: [NSURL URLWithString: @"about:blank"]]];
    
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
    /*
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
    */ 
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
