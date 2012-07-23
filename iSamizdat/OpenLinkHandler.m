//
//  OpenUrlActionSheet.m
//  iSamizdat
//
//  Created by Kolyvan on 23.07.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//

#import "OpenLinkHandler.h"
#import "KxMacros.h"
#import "KxTuple2.h"
#import "NSString+Kolyvan.h"
#import "SamLib.h"
#import "SamLibModel.h"
#import "SamLibAuthor.h"
#import "SamLibText.h"

#if __has_feature(objc_arc)
#warning This file must be compiled without ARC. Use -fno-objc-arc flag 
#endif

@interface OpenLinkHandler() <UIActionSheetDelegate> {    
    NSString *_link;
    KxTuple2 *_tuple;
    OpenLinkHandlerInAppBlock _block;
}

@end

@implementation OpenLinkHandler

- (BOOL) hasInApp
{
    return  _tuple != nil;
}

- (id) initWithLink: (NSString *) link
              block: (OpenLinkHandlerInAppBlock) block
{
    self = [super init];
    if (self) {
     
        _link = [link copy];        
        _tuple = [isLinkToSamlibAuthorOrText(link) retain];      
        _block = _tuple ? _Block_copy(block) : nil;
        
    }
    return self;
}

- (void) dealloc
{
    NSLog(@"%@ dealloc", [self class]);
    
    [_link release];
    [_tuple release];
    _Block_release(_block);    
    [super dealloc];
}

+ (void) handleOpenLink: (NSString *) link
       fromController: (UIViewController *) vc 
                  block: (OpenLinkHandlerInAppBlock) block;
{   
    OpenLinkHandler *hander = [[OpenLinkHandler alloc] initWithLink: link block: block];
   
    NSString *openInApp = hander.hasInApp ? locString(@"Open in App") : nil;
    
    UIActionSheet *actionSheet;
    actionSheet = [[UIActionSheet alloc] initWithTitle:locString(@"Open URL")
                                                    delegate:hander
                                           cancelButtonTitle:locString(@"Cancel") 
                                      destructiveButtonTitle:nil
                                           otherButtonTitles:locString(@"Open in Safari"), openInApp, nil];

    [actionSheet showFromTabBar:vc.tabBarController.tabBar];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{   
    //if (buttonIndex != actionSheet.cancelButtonIndex)
      
    if (_tuple &&
        _block &&
        buttonIndex == actionSheet.firstOtherButtonIndex + 1) {
        
        SamLibModel *model = [SamLibModel shared];    
        SamLibAuthor *author = [model findAuthor:_tuple.first];
        
        if (!author) {
            author = [[SamLibAuthor alloc] initWithPath:_tuple.first];
            [model addAuthor:author];
            [author autorelease];
        }
        
        SamLibText * text = nil;
        if (_tuple.second)
            text = [author findText:_tuple.second];

        _block(author, text);
        
    } else if (buttonIndex == actionSheet.firstOtherButtonIndex) {
        
        NSURL *url = [NSURL URLWithString:_link];
        [UIApplication.sharedApplication openURL: url];  
    }
    
    [self release];
}

@end
