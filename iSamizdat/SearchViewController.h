//
//  SearchAuthorViewController.h
//  iSamizdat
//
//  Created by Kolyvan on 16.06.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KxArc.h"

@class SamLibAuthor;
@protocol SearchViewDelegate <NSObject>
- (void) searchAuthorResult: (SamLibAuthor *) author;
@end

@interface SearchViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate>
@property (nonatomic, KX_PROP_WEAK) id<SearchViewDelegate> delegate;
@end
