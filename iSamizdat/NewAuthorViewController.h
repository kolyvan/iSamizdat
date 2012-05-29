//
//  AddAuthorViewController.h
//  iSamizdat
//
//  Created by Kolyvan on 29.05.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//

#import <UIKit/UIKit.h>

@class SamLibAuthor;

@protocol NewAuthorViewDelegate <NSObject>
- (void) addNewAuthor: (SamLibAuthor *) author;
@end

@interface NewAuthorViewController : UIViewController<UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, weak) id<NewAuthorViewDelegate> delegate;
@end
