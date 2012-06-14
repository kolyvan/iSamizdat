//
//  ReplyViewController.m
//  iSamizdat
//
//  Created by Kolyvan on 04.06.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//
//  https://github.com/kolyvan/iSamizdat
//  this file is part of iSamizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt
// 

#import "PostViewController.h"
#import "KxMacros.h"
#import "NSString+Kolyvan.h"
#import "SamLibComments.h"
#import "SamLibUser.h"

////

@implementation PostData
@synthesize message, msgid, isEdit;
@end

////

@interface PostViewController () {
    BOOL _needReload;
}
@property (nonatomic, readwrite, strong) UIBarButtonItem *sendButton;
@end

@implementation PostViewController

@synthesize comment = _comment;
@synthesize isEdit;
@synthesize textView;
@synthesize delegate;
@synthesize sendButton;

- (void) setComment:(SamLibComment *)comment
{
    _comment = comment;
    _needReload = YES;
}

- (id) init
{
    return [self initWithNibName:@"PostViewController" bundle:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //set notification for when keyboard shows/hides
	[[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(keyboardWillShow:) 
                                                 name:UIKeyboardWillShowNotification 
                                               object:nil];
    
    
    self.sendButton = [[UIBarButtonItem alloc] initWithTitle:@"Send"
                                                       style:UIBarButtonItemStylePlain 
                                                      target:self 
                                                      action:@selector(sendPressed)];
    
    self.sendButton.enabled = NO;
    self.navigationItem.rightBarButtonItem = self.sendButton;
    self.textView.delegate = self;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillDisappear:animated];    
    //[_textView becomeFirstResponder];
    self.textView.frame = self.view.bounds;
    
    if (_needReload) {
        
        _needReload = NO;
        
        if (_comment) {
            
            NSMutableString * ms = [NSMutableString string];
            
            if (self.isEdit) {
                
                for (NSString * s in [_comment.message lines]) {
                    if (s.nonEmpty) {
                        [ms appendString:[s trimmed]];
                        [ms appendString:@"\n"];
                    }
                }
                
            } else {
                
                [ms appendFormat: @"> > [%ld.%@]\n", _comment.number, _comment.name];
                
                for (NSString * s in [_comment.message lines]) {
                    if (s.nonEmpty) {
                        [ms appendString:@">"];
                        [ms appendString:[s trimmed]];
                        [ms appendString:@"\n"];
                    }
                }
            }
            
            self.textView.text = ms;
            
        } else {    
            self.textView.text = @"";
        }
        
    }
        
    self.sendButton.enabled = self.textView.text.nonEmpty;
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];    
    [self.textView resignFirstResponder];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.textView.delegate = nil;
    self.sendButton = nil;
    self.comment = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)textViewDidChange:(UITextView *)textView
{
    self.sendButton.enabled = self.textView.text.nonEmpty;
}

- (void) sendPressed
{   
    SamLibUser *user = [SamLibUser currentUser];        
    
    if (user.name.isEmpty) {
        
                
        UserViewController *userViewController = [[UserViewController alloc] init];        
        UINavigationController *navigationController = [[UINavigationController alloc]
                                                        initWithRootViewController:userViewController];        
        
        userViewController.delegate = self;
        [self presentViewController:navigationController 
                           animated:YES 
                         completion:NULL];
        
    } else {    
        
        [self.navigationController popViewControllerAnimated:YES];
        
        if (self.delegate) {
            
            NSString * message = self.textView.text;    
            if (message.nonEmpty) {   
                PostData *p = [[PostData alloc] init];
                p.message = message;
                p.msgid = self.comment.msgid;
                p.isEdit = self.isEdit;    
                
                [self.delegate sendPost:p];             
            }
        }
        
        self.comment = nil;    
        
    }
}

- (BOOL) userInfoChanged
{
    SamLibUser *user = [SamLibUser currentUser];        
    
    if (user.name.isEmpty) {
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:locString(@"Warning") 
                                                            message:locString(@"No username") 
                                                           delegate:nil 
                                                  cancelButtonTitle:locString(@"Ok") 
                                                  otherButtonTitles:nil];
        
        [alertView show];
        
        return NO;
        
    } else {    
        
        //[self sendPressed];            
        return YES;        
    }
}

-(void) keyboardWillShow:(NSNotification *)note
{    
	CGRect bounds;
    [[note.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey]
     getValue: &bounds];
    
    bounds = [self.view.window convertRect:bounds fromWindow:nil];
    bounds = [self.view convertRect:bounds fromView:nil];
    
	CGFloat height = bounds.origin.y;    	
	CGRect frame = self.textView.frame;
    
    if (frame.size.height != height) {
        
        frame.size.height = height;        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [UIView setAnimationDuration:0.3f];    
        self.textView.frame = frame;
        [UIView commitAnimations];
    }
}

@end
