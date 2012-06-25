//
//  SSPullToRefreshView+Kolyvan.m
//  iSamizdat
//
//  Created by Kolyvan on 14.06.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//

#import "SSPullToRefreshView+Kolyvan.h"

@implementation SSPullToRefreshView (Kolyvan)

- (void) startLoadingAndForceExpand  
{
    [self startLoadingAndExpand: YES];

    // fixes an issue with hidden content view (pullToRefresh)    
    UIScrollView *scrollView = self.scrollView;    
    if ((scrollView.contentSize.height + 20) > scrollView.frame.size.height) {
        
        [scrollView setContentOffset:CGPointMake(0, -self.expandedHeight) 
                            animated:YES];
    }
}
    
@end
