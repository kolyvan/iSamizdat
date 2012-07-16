//
//  SSPullToRefreshView+Kolyvan.m
//  iSamizdat
//
//  Created by Kolyvan on 14.06.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//

#import "SSPullToRefreshView+Kolyvan.h"
#import "KxMacros.h"
#import "KxUtils.h"
#import "NSDate+Kolyvan.h"

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


@implementation LocalizedPullToRefreshContentView {
    UIImageView *_arrowImageView;
}

- (id)initWithFrame:(CGRect)frame 
{	
    if ((self = [super initWithFrame:frame]))  {
        
        _arrowImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"arrow"]];
		_arrowImageView.frame = CGRectMake(15.0f, 0.0f, 23.0f, 60.0f);
		[self addSubview:_arrowImageView];
	}
	return self;
}

- (void)setState:(SSPullToRefreshViewState)state withPullToRefreshView:(SSPullToRefreshView *)view {	
	switch (state) {
		case SSPullToRefreshViewStateReady: {
			self.statusLabel.text = locString(@"Release to refresh...");            
            [UIView beginAnimations:nil context:NULL];
            _arrowImageView.hidden = NO;            
            _arrowImageView.transform = CGAffineTransformMakeRotation((M_PI / 180.0) * 180.0f);
            [UIView commitAnimations];
			[self.activityIndicatorView stopAnimating];
			break;
		}
			
		case SSPullToRefreshViewStateNormal: {
			self.statusLabel.text = locString(@"Pull down to refresh...");
            [UIView beginAnimations:nil context:NULL];            
            _arrowImageView.hidden = NO;    
            _arrowImageView.transform = CGAffineTransformIdentity;
            [UIView commitAnimations];            
			[self.activityIndicatorView stopAnimating];
			break;
		}
            
		case SSPullToRefreshViewStateLoading:
		case SSPullToRefreshViewStateClosing: {
			self.statusLabel.text = locString(@"Loading...");
            _arrowImageView.hidden = YES;
			[self.activityIndicatorView startAnimating];
			break;
		}
	}
}

- (void)setLastUpdatedAt:(NSDate *)date withPullToRefreshView:(SSPullToRefreshView *)view
{
    self.lastUpdatedAtLabel.text = date ? 
        KxUtils.format(locString(@"Last Updated: %@"), date.shortRelativeFormatted) :
        locString(@"No updated");
}


@end
