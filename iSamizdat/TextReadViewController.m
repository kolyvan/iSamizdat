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
#import "SamLibModel.h"
#import "SamLibText.h"
#import "SamLibText+IOS.h"
#import "SamLibAuthor.h"
#import "SamLibAuthor+IOS.h"
#import "SamLibHistory.h"
#import "KxUtils.h"
#import "NSString+Kolyvan.h"
#import "NSDate+Kolyvan.h"
#import "NSDictionary+Kolyvan.h"
#import "UITabBarController+Kolyvan.h"
#import "AppDelegate.h"
#import "KxMacros.h"
#import "UrlImageViewController.h"
#import "AuthorViewController.h"
#import "TextContainerController.h"
#import "OpenLinkHandler.h"
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
                                                   //withString:KxUtils.pathForResource(@"text.css")];
                                                   withString:@"../../text.css"];
    
    template = [template stringByReplacingOccurrencesOfString:@"<!-- TEXT_AUTHOR -->" 
                                                   withString:text.author.name];   

    template = [template stringByReplacingOccurrencesOfString:@"<!-- TEXT_NAME -->" 
                                                   withString:text.title];    

    NSString * date;
    
    date = [[NSDate date] formattedDatePattern:@"d/MM/yyyy HH:mm Z" 
                                      timeZone:nil 
                                        locale:[[NSLocale alloc] initWithLocaleIdentifier:@"ru_RU"]];
    
    template = [template stringByReplacingOccurrencesOfString:@"<!-- TEXT_DATE_LOADED -->"
                                                   withString:date];
    
    template = [template stringByReplacingOccurrencesOfString:@"<!-- TEXT_DATE_MODIFIED -->" 
                                                   withString:text.dateModified.nonEmpty ? text.dateModified : @""];
    
    template = [template stringByReplacingOccurrencesOfString:@"<!-- TEXT_SIZE -->" 
                                                   withString:text.size.nonEmpty ? text.size : @""];
    
    if (text.note.nonEmpty)
        template = [template stringByReplacingOccurrencesOfString:@"<!-- TEXT_NOTE -->" 
                                                       withString:text.note];
    
    return [template stringByReplacingOccurrencesOfString:@"<!-- DOWNLOADED_TEXT -->" 
                                               withString:html];
}

void ensureTextCSSInCacheFolder(BOOL force)
{    
    NSFileManager *fm = KxUtils.fileManager();
    
    NSString *cssPath = [KxUtils.cacheDataPath() stringByAppendingPathComponent:@"text.css"];
    
    if (force || ![fm isReadableFileAtPath:cssPath]) {
        
        [fm copyItemAtPath:KxUtils.pathForResource(@"text.css")
                    toPath:cssPath
                     error:nil];
}
}

NSDictionary * determineTextFileMetaInfo (NSString *path)
{
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath: path];   
    
    if (!fileHandle)
        return nil;
    
    NSData *data = [fileHandle readDataOfLength:2048];
    [fileHandle closeFile];    
    
    if (data.length == 0)
        return nil;

    // if try to create a string via stringFromUtf8Bytes
    // it may break since there is a partial utf8 stream    
    NSString *s = [NSString stringFromAsciiBytes:data];
    if (!s.nonEmpty)
        return nil;
    
    NSScanner *scanner = [NSScanner scannerWithString:s];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSArray *keys = KxUtils.array(@"textLoaded", @"textModifed", @"textSize", nil);    
    
    for (NSString *key in keys) {
    
        if (scanner.isAtEnd)
            break;
        
        NSString *tag = KxUtils.format(@"<span id='%@'>", key);
        
        NSString *value;
        
        if ([scanner scanUpToString:tag intoString:nil] &&
            [scanner scanString:tag intoString:nil] &&
            [scanner scanUpToString:@"</span>" intoString:&value]) {
            
            [dict update:key value:value];
        }        
    }
    
    return dict;
}

/////

#define SLIDER_FATE_TIME 3

@interface TextReadViewController () <UIActionSheetDelegate> {
    BOOL _needReload;
    id _version;
    BOOL _fullScreen;
    BOOL _prevNavBarTranslucent;
    UISwipeGestureRecognizer *gestureRecognizer;     
    CGFloat _prevScale;
    BOOL _resetingWebView;
    UISlider *_slider;
    NSTimer *_sliderTimer;
    NSDate *_sliderTimestamp;
}
@property (nonatomic, strong) IBOutlet UIWebView * webView;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) SSPullToRefreshView *pullToRefreshView;
@property (nonatomic, strong) UIBarButtonItem *stopButton;
@property (nonatomic, strong) UrlImageViewController *urlImageViewController;
@property (nonatomic, strong) UIBarButtonItem *goSlideButton;
@property (nonatomic, strong) AuthorViewController *authorViewController;
@property (nonatomic, strong) TextContainerController *textContainerController;
@end

@implementation TextReadViewController

@synthesize text = _text;
@synthesize webView = _webView;
@synthesize pullToRefreshView, stopButton;
@synthesize urlImageViewController;
@synthesize activityIndicator;
@synthesize goSlideButton;
@synthesize authorViewController;
@synthesize textContainerController;

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

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    
    self.pullToRefreshView = [[SSPullToRefreshView alloc] initWithScrollView:self.webView.scrollView
                                                                    delegate:self];
    self.pullToRefreshView.contentView = [[LocalizedPullToRefreshContentView alloc] initWithFrame:CGRectZero];    
        
    self.stopButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop 
                                                                    target:self 
                                                                    action:@selector(goStop)];
    
    self.goSlideButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"slide"] 
                                                          style:UIBarButtonItemStylePlain
                                                         target:self 
                                                         action:@selector(goSlide)];
    
    self.navigationItem.rightBarButtonItem = self.goSlideButton;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(samLibTextSettingsChanged:)
                                                 name:@"SamLibTextSettingsChanged" 
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dropboxDownloadCompleted:)
                                                 name:@"DropboxDownloadCompleted" 
                                               object:nil];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    ensureTextCSSInCacheFolder(NO);
    
    if (_needReload) {        
        _needReload = NO;
        [self reloadWebView];       
        [self refreshLastUpdated];
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
       
    _text.scrollOffset = [self computeOffset];
    //DDLogInfo(@"store offset %f", offset); 
    
    //if (_fullScreen)
    //    [self fullscreenMode: NO];
    
    if (_text.htmlFile.nonEmpty)
        [[SamLibHistory shared] addText:_text];
    
    //self.navigationController.navigationBar.translucent = _prevNavBarTranslucent;
    
    [self.activityIndicator stopAnimating];  
    
    if (_sliderTimer) {
        [_sliderTimer invalidate];
        _sliderTimer = nil;
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    _webView.delegate = nil;
    
    [self.webView removeGestureRecognizer:gestureRecognizer];
    gestureRecognizer = nil;
    
    self.pullToRefreshView = nil;
    self.stopButton = nil;
    self.urlImageViewController = nil;
    self.authorViewController = nil;
    self.textContainerController = nil;    
    self.goSlideButton = nil;
    self.navigationItem.rightBarButtonItem = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning]; 
    self.urlImageViewController = nil;
    self.authorViewController = nil;
    self.textContainerController = nil;    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    
}

- (void) samLibTextSettingsChanged:(NSNotification *)notification
{
    _needReload = YES;
}

- (void) dropboxDownloadCompleted: (NSNotification *)notification
{
    NSString *path = [notification.userInfo get:@"path"];
    
    if ([path isEqualToString:_text.htmlFile]) {
        
        _needReload = YES;        
    }
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

        [self refreshLastUpdated];
        
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
    //self.navigationItem.rightBarButtonItem = self.bookmarkButton;    
}

- (void) refreshLastUpdated
{
    [self.pullToRefreshView.contentView setLastUpdatedAt:_text.timestamp
                                   withPullToRefreshView:self.pullToRefreshView]; 
}

- (void)pullToRefreshViewDidStartLoading:(SSPullToRefreshView *)view 
{   
    self.navigationItem.rightBarButtonItem = self.stopButton;
        
    [self.pullToRefreshView startLoading];  
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
           
    [_text update:^(SamLibText *text, SamLibStatus status, NSString *error) {
                        
        [self.pullToRefreshView finishLoading];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;        
        self.navigationItem.rightBarButtonItem = nil;
        self.navigationItem.rightBarButtonItem = self.goSlideButton;
        
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

- (void) fullscreenMode: (BOOL) on
{   
    _fullScreen = on;    
    UIApplication *app = [UIApplication sharedApplication];    
    [app setStatusBarHidden:on withAnimation:UIStatusBarAnimationSlide];        
    [self.navigationController setNavigationBarHidden:on animated:YES];
    [self.tabBarController setTabBarHidden:on animated:YES];   
}

- (CGFloat) computeOffset
{
    CGFloat offset = 0;
    CGFloat value = _webView.scrollView.contentOffset.y;
    if (value > 10) {
        CGFloat size = _webView.scrollView.contentSize.height;
        offset = value / size;
    }
    return offset;
}

- (void) goSlide
{
    if (!_slider) {
        
        CGSize size = self.view.bounds.size;
        CGRect frame;
        frame.origin.x = -size.width / 2;
        frame.origin.y = size.height / 2 - 20;        
        frame.size.width = size.height - 20;
        frame.size.height = 30; 
        
        _slider = [[UISlider alloc] initWithFrame:frame];        
        [self.view addSubview:_slider];
        
        _slider.transform = CGAffineTransformMakeRotation(M_PI_2);
        _slider.continuous = YES;
        _slider.hidden = YES;        
        
        [_slider addTarget:self 
                    action:@selector(sliderValueChanged:) 
          forControlEvents:UIControlEventValueChanged]; 
    }
    
    _slider.hidden = !_slider.hidden;
        
    if (_sliderTimer) {
        [_sliderTimer invalidate];
        _sliderTimer = nil;
    }
    
    if (!_slider.hidden) {
      
        _slider.value = [self computeOffset];
        
        _sliderTimestamp = [NSDate date];
        
        _sliderTimer = [NSTimer timerWithTimeInterval:1 
                                               target:self 
                                             selector:@selector(checkSliderVisibility) 
                                             userInfo:nil 
                                              repeats:YES];
        
        [[NSRunLoop currentRunLoop] addTimer:_sliderTimer 
                                     forMode:NSRunLoopCommonModes];
    } 
}

- (void) checkSliderVisibility
{
    NSTimeInterval t = [[NSDate date] timeIntervalSinceDate:_sliderTimestamp];
    
    if (t > SLIDER_FATE_TIME) {
    
        [_sliderTimer invalidate];
        _sliderTimer = nil;
        
        [UIView beginAnimations:nil context:NULL];
        _slider.hidden = YES;
        [UIView commitAnimations];
    }
}

- (void) sliderValueChanged: (UISlider *) sender
{    
    _sliderTimestamp = [NSDate date];
    CGFloat offset = (sender.value - sender.minimumValue) / sender.maximumValue;    
    CGFloat size = _webView.scrollView.contentSize.height;
    [_webView.scrollView setContentOffset:CGPointMake(0, offset * size) animated:NO]; 
}

- (void) restoreOffset
{   
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

- (void) reloadWebView
{    
    NSString *path = _text.htmlFile;
    if (!path)
        path = KxUtils.pathForResource(@"empty.html");
    [self loadWebViewFromPath: path];
}

- (void) loadWebViewFromPath: (NSString *) path
{
    _resetingWebView = YES;
   [_webView loadRequest:[NSURLRequest requestWithURL: [NSURL URLWithString: @"about:blank"]]];
    
    if (path.nonEmpty) {

        [self.activityIndicator startAnimating];        
        NSURL *url = [NSURL fileURLWithPath:path isDirectory: NO];
        NSURLRequest * request = [NSURLRequest requestWithURL: url];    
        [_webView loadRequest:request];
    }
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
    CGFloat zoom = SamLibAgent.settingsFloat(@"text.zoom", 1);
    if (fabs(zoom - 1) > 0.05) {
        
        NSString *js = KxUtils.format(@"document.body.style.zoom = %.2f;", zoom);        
        [self.webView stringByEvaluatingJavaScriptFromString: js];
    }    
}

- (void) showRemoteImage: (NSURL *) url
{
    if (!self.urlImageViewController)
        self.urlImageViewController = [[UrlImageViewController alloc] init];    
    self.urlImageViewController.url = url;
    self.urlImageViewController.fullscreen = _fullScreen;
    [self.navigationController pushViewController:self.urlImageViewController 
                                         animated:YES];
}

- (void) handleLink: (NSString *) link
{
    [OpenLinkHandler handleOpenLink:link 
                     fromController:self 
                              block:^(SamLibAuthor *author, SamLibText *text) {
                                  
                                  if (text) {
                                      
                                      if (!self.textContainerController) {
                                          self.textContainerController = [[TextContainerController alloc] init];
                                      }                                          
                                      self.textContainerController.text = text;
                                      self.textContainerController.selected = TextInfoViewSelected;
                                      [self.navigationController pushViewController:self.textContainerController 
                                                                           animated:YES];
                                  } else {
                                      
                                      if (!self.authorViewController) {
                                          self.authorViewController = [[AuthorViewController alloc] init];
                                      }
                                      self.authorViewController.author = author;
                                      [self.navigationController pushViewController:self.authorViewController 
                                                                           animated:YES];
                                  }
                              }];
}

#pragma mark - UIWebView delegate

- (void)webViewDidFinishLoadDeferred
{
    //DDLogInfo(@"webViewDidFinishLoadDeferred %@", _text.path);    
    
    [self prepareHTML];    
    [self restoreOffset];
    
    [self.activityIndicator stopAnimating];        
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if (_resetingWebView) {
        _resetingWebView = NO;
        return;
    }
    
    //DDLogInfo(@"webViewDidFinishLoad %@", _text.path);    
    
    // UIWebView can fire webViewDidFinishLoad twice
    // so workaroud here
    
    [self->isa cancelPreviousPerformRequestsWithTarget:self 
                                              selector:@selector(webViewDidFinishLoadDeferred) 
                                                object:nil];
    
    [self performSelector:@selector(webViewDidFinishLoadDeferred) 
               withObject:nil 
               afterDelay:0.2];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{    
}

- (BOOL)webView:(UIWebView *)webView 
shouldStartLoadWithRequest:(NSURLRequest *)request 
 navigationType:(UIWebViewNavigationType)navigationType
{
    //DDLogInfo(@"webView %d %@ %@", navigationType, request.URL.absoluteURL, request.URL.pathExtension);
    
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
        
        NSString *ext = request.URL.pathExtension;
        if ([ext isEqualToString:@"png"] ||
            [ext isEqualToString:@"jpg"] ||
            [ext isEqualToString:@"jpeg"] ||
            [ext isEqualToString:@"gif"]) {
                       
            [self showRemoteImage: request.URL];
            return NO;
        }
        
        [self handleLink: request.URL.absoluteString];

        return NO;
        
    }
    
    if (navigationType == UIWebViewNavigationTypeReload) {
        
        return NO;
    }
       
    return YES;
}

@end
