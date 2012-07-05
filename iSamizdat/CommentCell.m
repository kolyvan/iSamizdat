//
//  CommentCell.m
//  iSamizdat
//
//  Created by Kolyvan on 04.06.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//
//  https://github.com/kolyvan/iSamizdat
//  this file is part of iSamizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt
// 

#import "CommentCell.h"
#import "KxArc.h"
#import "KxUtils.h"
#import "NSString+Kolyvan.h"
#import "NSDate+Kolyvan.h"
#import "NSArray+Kolyvan.h"
#import "SamLibComment+IOS.h"
#import "SamLibComments.h"
#import "CommentsViewController.h"
#import "TextLine.h"
#import "UIFont+Kolyvan.h"
#import <objc/runtime.h>

////

#define BUTTON_REPLY 1
#define BUTTON_EDIT 2
#define BUTTON_DELETE 3
#define BUTTON_EMAIL 4
#define BUTTON_URL 5
#define BUTTON_SIZE 44
#define BUTTON_INTERVAL_X 4
#define BUTTON_INTERVAL_Y 4

static void drawDashLine(CGPoint from, CGPoint to, UIColor *color) 
{    
    UIBezierPath *bezierPath = [UIBezierPath bezierPath];            
    
    CGFloat lineDash[2] = {2,2};
    [bezierPath setLineDash:lineDash count:2 phase:0.0];            
    [bezierPath setLineWidth: 1];
    [bezierPath moveToPoint: from];        
    [bezierPath addLineToPoint: to]; 
    if (color) [color set];
    [bezierPath stroke];
    
}

static void drawLine(CGPoint from, CGPoint to, UIColor *color, CGFloat width) 
{    
    UIBezierPath *bezierPath = [UIBezierPath bezierPath];            
    
    [bezierPath setLineWidth: width];
    [bezierPath moveToPoint: from];        
    [bezierPath addLineToPoint: to]; 
    if (color) [color set];
    [bezierPath stroke];
    
}

////

@interface CommentCell() {
    int _wantTouches;
}
@end

@implementation CommentCell

@synthesize delegate = _delegate;
@synthesize comment = _comment;

- (void) setComment:(SamLibComment *)comment
{
    if (comment != _comment) {
        _comment = comment;
        _wantTouches = -1;
        [self setNeedsDisplay];        
    }
}

- (BOOL) wantTouches
{
    if (_wantTouches < 0) {
        
        if (_comment.link.nonEmpty) {
            
            _wantTouches = YES;
        } else {
            
            _wantTouches = NO;            
            for (TextLine *p in [_comment messageLines]) {
                if (p.link.nonEmpty) {
                    _wantTouches = YES;
                    break;
                }
            }        
        }
    }
    
    return _wantTouches;
}

- (id) initWithStyle:(UITableViewCellStyle)style 
     reuseIdentifier:(NSString *)reuseIdentifier      
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) 
    {                
        self.selectionStyle = UITableViewCellSelectionStyleNone;
		self.backgroundColor = [UIColor whiteColor];
		self.opaque = YES;
        
        // configure "backView"
        
        UIButton* replyButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        [replyButton setImage:[UIImage imageNamed:@"reply"] forState:UIControlStateNormal];
        [replyButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];         
        replyButton.tag = BUTTON_REPLY;
        
        UIButton* editButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [editButton setImage:[UIImage imageNamed:@"edit"] forState:UIControlStateNormal];
        [editButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];        
        editButton.tag = BUTTON_EDIT;
        
        UIButton* deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [deleteButton setImage:[UIImage imageNamed:@"cross"] forState:UIControlStateNormal];
        [deleteButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];                
        deleteButton.tag = BUTTON_DELETE;
        
        UIButton* emailButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [emailButton setImage:[UIImage imageNamed:@"email"] forState:UIControlStateNormal];
        [emailButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];        
        emailButton.tag = BUTTON_EMAIL;
        
        UIButton* urlButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [urlButton setImage:[UIImage imageNamed:@"url"] forState:UIControlStateNormal];
        [urlButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];        
        urlButton.tag = BUTTON_URL;
                 
        [self.backView addSubview:replyButton];        
        [self.backView addSubview:editButton];                
        [self.backView addSubview:deleteButton];                
        [self.backView addSubview:emailButton];
        [self.backView addSubview:urlButton];
                
        //self.backView.hidden = YES;
        //self.backView.alpha = 0;
        self.backView.backgroundColor = [UIColor underPageBackgroundColor]; // scrollViewTexturedBackgroundColor        
    }
    return self;
}

- (void) prepareForReuse 
{
	[super prepareForReuse];    
    //self.backView.hidden = YES; 
    //self.backView.alpha = 0;
}

- (NSArray *) prepareButtons
{        
    NSMutableArray * buttons = [NSMutableArray array];
    
    UIView *btn;    
    btn = [self.backView viewWithTag:BUTTON_REPLY];
    btn.hidden = YES;
    [buttons push:btn];
    
    btn = [self.backView viewWithTag:BUTTON_EDIT];
    btn.hidden = YES;    
    
    if (_comment.canEdit)
        [buttons push:btn];

    btn = [self.backView viewWithTag:BUTTON_DELETE];
    btn.hidden = YES;    
    if (_comment.canDelete)
        [buttons push:btn];
    
    btn = [self.backView viewWithTag:BUTTON_URL];
    btn.hidden = YES;    
    if (_comment.link.nonEmpty)
        [buttons push:btn];
    
    btn = [self.backView viewWithTag:BUTTON_EMAIL];
    btn.hidden = YES;
    [buttons push:btn];
     
    CGFloat width = buttons.count * (BUTTON_SIZE + BUTTON_INTERVAL_X);
    
    CGRect bounds = self.backView.bounds;
    
    CGFloat x = 0 + (bounds.size.width - width) / 2.0;
    CGFloat y = 0 + (bounds.size.height - BUTTON_SIZE + BUTTON_INTERVAL_Y * 2) / 2.0;
    
    for (UIView * btn in buttons) {

        btn.frame = CGRectMake(x, y, BUTTON_SIZE, BUTTON_SIZE);
        x += (BUTTON_SIZE + BUTTON_INTERVAL_X); 
        btn.alpha = 0;
        btn.hidden = NO;
        btn.transform = CGAffineTransformMakeScale(2, 2);       
    } 
    
    return buttons;
}

- (void) animateButtons: (NSArray *) buttons
{
    [UIView animateWithDuration:0.05 
                          delay:0.02 
                        options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionNone
                     animations:^{
                         
                         UIView * v = buttons.first;
                         v.alpha = 1.0;
                         
                         //CGRect bounds = v.frame;
                         //bounds.size = CGSizeMake(BUTTON_SIZE, BUTTON_SIZE);
                         //v.frame = bounds;
                         
                         v.transform = CGAffineTransformIdentity;
                     } 
                     completion:^(BOOL finished) {
                         if (finished && buttons.count > 1) {                            
                             [self animateButtons: buttons.tail];                            
                         }
                     }];
     
}

 
#define TRANSITION_OPTIONS UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionShowHideTransitionViews


- (void) swipeOpen
{   
    NSArray *buttons = [self prepareButtons];
        
    [UIView transitionFromView:self.contentView 
                        toView:self.backView
                      duration:0.2
                       options:TRANSITION_OPTIONS
                    completion:^(BOOL finished){
                        
                        [self animateButtons: buttons];
                    }];
}

- (void) swipeClose
{        
    [UIView transitionFromView:self.backView 
                        toView:self.contentView
                      duration:0.2
                       options:TRANSITION_OPTIONS
                    completion:nil];
}

- (void) buttonPressed: (id) sender
{
    NSInteger tag = [sender tag];
    switch (tag) {
        case BUTTON_REPLY:  [self replyPressed]; break;
        case BUTTON_EDIT:   [self editPressed]; break;
        case BUTTON_DELETE: [self deletePressed]; break;
//        case BUTTON_EMAIL:  [self emailPressed]; break;            
//        case BUTTON_URL:    [self urlPressed]; break;
        default:
            break;
    }
}

- (void) replyPressed 
{    
    [self swipeClose];       
    [_delegate replyPost: _comment];    
}

- (void) deletePressed 
{   
    [self swipeClose];
    [_delegate deletePost: _comment];    
}

- (void) editPressed 
{    
    [self swipeClose];
    [_delegate editPost: _comment];    
}

+ (CGFloat) heightForComment:(SamLibComment *) comment 
                   withWidth:(CGFloat) width
{
    CGFloat height = 15;
    CGFloat widthr = width - 10;
    
    height += [UIFont boldSystemFont16].lineHeight;
    
    if (comment.replyto.nonEmpty) {
        
        height += 10;        
        for (TextLine * line in [comment replytoLines]) {
            height += [line computeSize:widthr - 10 withFont:[UIFont systemFont12]].height;
        }
    }
    
    if (comment.message.nonEmpty) {
        
        height += 10;                
        for (TextLine * line in [comment messageLines]) {
            height += [line computeSize:widthr withFont:[UIFont systemFont14]].height;
        }
        
    }
    
    if (!comment.deleteMsg.nonEmpty) {
        
        height += 2;
        NSString * date = [comment.timestamp shortRelativeFormatted]; 
        height += [date sizeWithFont:[UIFont systemFont12] 
                   constrainedToSize:CGSizeMake(widthr, 999999) 
                       lineBreakMode:UILineBreakModeTailTruncation].height;
    }
    
	return height;
}

- (void) drawContentView:(CGRect)rect 
{
	CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGSize size;
    CGFloat h = 0;
    CGFloat x = 5, y = 5, w = rect.size.width - 10;    
	
	[[UIColor whiteColor] set];
	CGContextFillRect(context, rect);
    
    h = [UIFont boldSystemFont16].lineHeight;
    
    float headerHeight = h + 5;
    
    [[UIColor colorWithWhite:0.8 alpha:1] set];
	CGContextFillRect(context, CGRectMake(0, y, rect.size.width, headerHeight));
    
    // draw number
    
    if (_comment.isNew)
        [[UIColor orangeColor] set];
    else        
        [[UIColor blackColor] set];
    
    NSString * number = KxUtils.format(@"%ld", _comment.number);         
    
    size = [number sizeWithFont:[UIFont systemFont12] 
              constrainedToSize:CGSizeMake(w, 999999) 
                  lineBreakMode:UILineBreakModeTailTruncation];    
    
    [number drawInRect:CGRectMake(w - size.width, 
                                  y + 3, 
                                  size.width, 
                                  rect.size.height - y) 
              withFont:[UIFont systemFont12] 
         lineBreakMode:UILineBreakModeTailTruncation];    
    
    ///
    
    
    if (_comment.name.nonEmpty) 
    {   
        TextLine *nameLine = _comment.nameLine;
        y += [nameLine drawInRect:CGRectMake(x, y + 2, w - size.width, rect.size.height - y) 
                         withFont:[UIFont boldSystemFont16] 
                         andColor:_comment.nameColor].height;
        
    } else if (_comment.deleteMsg.nonEmpty) {
        
        [[UIColor darkGrayColor] set]; 
        NSString *s = KxUtils.format(@"deleted %@", _comment.deleteMsg);
        y += [s drawInRect:CGRectMake(x, y + 2, w - size.width, rect.size.height - y) 
                  withFont:[UIFont systemFont12]  
             lineBreakMode:UILineBreakModeTailTruncation].height;
        
        
    }
    
    if (_comment.replyto.nonEmpty) {
        
        y += 10;        
        
        [[UIColor grayColor] set];         
        
        for (TextLine * line in [_comment replytoLines]) {
            
            y += [line drawInRect:CGRectMake(x + 10, y, w - 10, rect.size.height - y)  
                         withFont:[UIFont systemFont12] 
                         andColor:nil].height;
        }
    }    
    
    if (_comment.message.nonEmpty) {
        
        y +=10;
        
        for (TextLine * line in [_comment messageLines]) {
            
            y += [line drawInRect:CGRectMake(x, y, w, rect.size.height - y)  
                         withFont:[UIFont systemFont14] 
                         andColor:line.link.nonEmpty ? [UIColor blueColor] : [UIColor blackColor]].height;
        }
        
    }
    
    if (!_comment.deleteMsg.nonEmpty) {
        
        y += 2;
        NSString * date = [_comment.timestamp shortRelativeFormatted]; 
        
        float dx = [date sizeWithFont:[UIFont systemFont12] 
                    constrainedToSize:CGSizeMake(w, 999999) 
                        lineBreakMode:UILineBreakModeTailTruncation].width;
        
        y += [date drawInRect:CGRectMake(w - dx , y, dx, rect.size.height - y) 
                     withFont:[UIFont systemFont12] 
                lineBreakMode:UILineBreakModeTailTruncation].height;
    }   
}

- (void) touchUpInside:(CGPoint)loc
{
    if (self.wantTouches) {
        
        if (_comment.link.nonEmpty) {
            
            if (CGRectContainsPoint(_comment.nameLine.bounds, loc)) {
                
                NSURL *url = [NSURL URLWithString: _comment.link];
                [UIApplication.sharedApplication openURL: url];                     
                return;
                
            }
        }
        
        for (TextLine *line in [_comment messageLines]) {
            
            if (line.link.nonEmpty) {
                
                if (CGRectContainsPoint(line.bounds, loc)) {
                    
                    NSURL *url = [NSURL URLWithString: line.link];
                    [UIApplication.sharedApplication openURL: url];                     
                    break;
                    
                }
            }
        }   
    }
}



@end