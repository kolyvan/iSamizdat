//
//  OpenUrlActionSheet.h
//  iSamizdat
//
//  Created by Kolyvan on 23.07.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//

#import <UIKit/UIKit.h>

@class SamLibAuthor;
@class SamLibText;

typedef void(^OpenLinkHandlerInAppBlock)(SamLibAuthor *, SamLibText *);

@interface OpenLinkHandler : NSObject

+ (void) handleOpenLink: (NSString *) link 
         fromController: (UIViewController *) vc 
                  block: (OpenLinkHandlerInAppBlock) block;

@end
