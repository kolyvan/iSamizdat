//
//  SSPullToRefreshView+Kolyvan.h
//  iSamizdat
//
//  Created by Kolyvan on 14.06.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//

#import "SSPullToRefreshView.h"
#import "SSPullToRefreshDefaultContentView.h"

@interface SSPullToRefreshView (Kolyvan)

- (void) startLoadingAndForceExpand;

@end

@interface LocalizedPullToRefreshContentView : SSPullToRefreshDefaultContentView
@end 