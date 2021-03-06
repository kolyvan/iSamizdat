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
#import "KxMacros.h"
#import "NSString+Kolyvan.h"
#import "NSDate+Kolyvan.h"
#import "NSArray+Kolyvan.h"
#import "SamLibComment+IOS.h"
#import "SamLibComments.h"
#import "SamLibModel.h"
#import "SamLibModerator.h"
#import "CommentsViewController.h"
#import "TextLine.h"
#import "UIFont+Kolyvan.h"
#import "UIColor+Kolyvan.h"
#import <objc/runtime.h>

////

enum {
    BUTTON_REPLY    = 1,
    BUTTON_EDIT,
    BUTTON_DELETE,
    BUTTON_EMAIL,
    BUTTON_URL,
    BUTTON_AUTHOR_ADD,       
    BUTTON_AUTHOR_GO, 
    BUTTON_BAN, 
    BUTTON_UNBAN,     
};

#define BUTTON_SIZE 36
#define BUTTON_INTERVAL_X 8
#define BUTTON_INTERVAL_Y 8

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
    NSMutableArray *_buttons;
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
        self.backView.backgroundColor = [UIColor scrollViewTexturedBackgroundColor]; //underPageBackgroundColor
    }
    return self;
}

- (void) prepareForReuse 
{
	[super prepareForReuse];    
    
    _buttons = nil;

    for (UIView *v in self.backView.subviews)
        [v removeFromSuperview];
}

+ (CGFloat) minimumHeight
{
   return ([UIFont boldSystemFont16].lineHeight + 5) + BUTTON_SIZE + BUTTON_INTERVAL_Y;
}

- (void) prepareBackView
{      
    if (self.backView.subviews.isEmpty) {
        
        const char * names[9] = {
            "comment", "edit", "cross", "email", "safari", "author_add", "author_go", "ban", "unban"
        };
        
        for (int i = 0; i < 9; ++i) {
            
            NSString *name = [NSString stringWithCString:names[i] encoding:NSUTF8StringEncoding];            
            UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];            
            [button setImage:[UIImage imageNamed:name] forState:UIControlStateNormal];
            [button addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];         
            button.tag = i + 1;
            [self.backView addSubview:button]; 
        } 
    }
    
    if (!_buttons) {
        
        NSMutableArray *buttons = [NSMutableArray array];
        
        const NSInteger AUTHOR_GO =  1;
        const NSInteger AUTHOR_ADD = 2;
        
        NSInteger authorFlag = 0;
        
        for (UIView * v in self.backView.subviews) {
            
            if ([v isKindOfClass:[UIButton class]]) {
                
                v.hidden = YES;
                
                switch (v.tag) {
                    case BUTTON_REPLY:  
                        [buttons push:v]; 
                        break;
                        
                    case BUTTON_EDIT:
                        if (_comment.canEdit)
                            [buttons push:v];
                        break;
                        
                    case BUTTON_DELETE:
                        if (_comment.canDelete)
                            [buttons push:v];
                        break;
                        
                    case BUTTON_URL:  
                        if (_comment.link.nonEmpty) {
                            [buttons push:v]; 
                            
                            if (_comment.isSamizdat) {
                                
                                NSString *path = _comment.link.lastPathComponent;
                                id author = [[SamLibModel shared] findAuthor:path];
                                authorFlag = author ? AUTHOR_GO : AUTHOR_ADD;                            
                            }
                        }
                        break;
                        
                    case BUTTON_EMAIL:  
                        if (_comment.email.nonEmpty)
                            [buttons push:v]; 
                        break;
                        
                    case BUTTON_AUTHOR_ADD:
                        if (authorFlag == AUTHOR_ADD) 
                            [buttons push:v]; 
                        break;                    
                        
                    case BUTTON_AUTHOR_GO:
                        if (authorFlag == AUTHOR_GO) 
                            [buttons push:v]; 
                        break;
                        
                    case BUTTON_BAN:  
                        if (!_comment.isHidden)
                            [buttons push:v];
                        break;                            
                        
                    case BUTTON_UNBAN:  
                        if (_comment.isHidden)                        
                            [buttons push:v];
                        break;        
                        
                    default:
                        break;
                }            
            }        
        }        
         _buttons = [NSArray arrayWithArray:buttons];
    }    
    
    CGRect bounds;
    bounds = self.contentView.frame;
    bounds.origin.y += ([UIFont boldSystemFont16].lineHeight + 5);
    bounds.size.height = BUTTON_SIZE + BUTTON_INTERVAL_Y;
    self.backView.frame = bounds;
  
    CGFloat width = _buttons.count * (BUTTON_SIZE + BUTTON_INTERVAL_X);            
    CGFloat x = (bounds.size.width - width) / 2.0;
    CGFloat y = BUTTON_INTERVAL_Y / 2;
    
    for (UIView * btn in _buttons) {
        
        btn.frame = CGRectMake(x, y, BUTTON_SIZE, BUTTON_SIZE);
        x += (BUTTON_SIZE + BUTTON_INTERVAL_X); 
        btn.alpha = 0;
        btn.hidden = NO;
        btn.transform = CGAffineTransformMakeScale(2, 2);       
    }  
}

- (void) animateButtons: (NSArray *) buttons
{
    [UIView animateWithDuration:0.04 
                          delay:0.02 
                        options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionNone
                     animations:^{
                         
                         UIView * v = buttons.first;
                         v.alpha = 1.0;
                         v.transform = CGAffineTransformIdentity;
                     } 
                     completion:^(BOOL finished) {
                         if (finished && buttons.count > 1) {                            
                             [self animateButtons: buttons.tail];                            
                         }
                     }];
}
 
#define TRANSITION_OPTIONS UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionCrossDissolve 

//| UIViewAnimationOptionShowHideTransitionViews

- (void) swipeOpen
{   
    [self prepareBackView];
     
    [UIView animateWithDuration:0.2 
                          delay:0 
                        options:TRANSITION_OPTIONS 
                     animations:^{
                         
                         [self bringSubviewToFront: self.backView];
                     } 
                     completion:^(BOOL finished){
                         
                         [self animateButtons: _buttons];
                     }];
    
}

- (void) swipeCloseAnimated: (BOOL) animated
{   
    if (animated) {
        
        [UIView animateWithDuration:0.2 
                              delay:0 
                            options:TRANSITION_OPTIONS 
                         animations:^{
                             
                             [self bringSubviewToFront: self.contentView];
                         } 
                         completion:nil];
        
    } else {
        
        [self bringSubviewToFront: self.contentView];
    }    
}

- (void) buttonPressed: (id) sender
{
    [self swipeCloseAnimated: YES];
    
    NSInteger tag = [sender tag];
    switch (tag) {
        case BUTTON_REPLY:      [_delegate replyPost: _comment]; break;
        case BUTTON_EDIT:       [_delegate editPost: _comment]; break;
        case BUTTON_DELETE:     [_delegate deletePost: _comment]; break;
        case BUTTON_EMAIL:      [self openUrl: KxUtils.format(@"mailto:%@", _comment.email)]; break;            
        case BUTTON_URL:        [self openUrl: _comment.link]; break;
            
        case BUTTON_AUTHOR_ADD: //fallback
        case BUTTON_AUTHOR_GO:  [_delegate goAuthor:_comment.link.lastPathComponent]; break; 
        
        case BUTTON_BAN:        //fallback
        case BUTTON_UNBAN:      [self.delegate toggleCommentCell:self];                        
        default:
            break;
    }
}

- (void) openUrl: (NSString *) s;
{
    NSURL *url = [NSURL URLWithString: s];
    [UIApplication.sharedApplication openURL: url];  
}

+ (CGFloat) heightForComment:(SamLibComment *) comment 
                   withWidth:(CGFloat) width
{
    CGFloat height = 10;
    CGFloat widthr = width - 8;
    
    height += [UIFont boldSystemFont16].lineHeight;
    
    if (comment.deleteMsg.nonEmpty) {

         return height;        
        
    } else if (comment.isHidden) {
        
        return self.minimumHeight;
        
    } else if (comment.message.nonEmpty) {
        
        height += 5;                
        
        NSArray *lines = comment.messageLines;        
        BOOL isQuote = lines.nonEmpty ? [lines.first isQuote] : NO;
        
        for (TextLine * line in lines) {
                        
            if (isQuote != line.isQuote) 
                height += 2;
            isQuote = line.isQuote;
            
            if (line.isQuote)
                height += [line computeSize:widthr - 10 withFont:[UIFont systemFont12]].height;            
            else
                height += [line computeSize:widthr withFont:[UIFont systemFont14]].height;
            
        }
    }
        
    height += 2;
    NSString * date = [comment.timestamp shortRelativeFormatted]; 
    height += [date sizeWithFont:[UIFont systemFont12] 
               constrainedToSize:CGSizeMake(widthr, 999999) 
                   lineBreakMode:UILineBreakModeTailTruncation].height;
    
    return MAX(height, self.minimumHeight);
}

- (void) drawContentView:(CGRect)rect 
{
	CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGSize size;
    CGFloat h = 0;
    CGFloat x = 4, y = 1, w = rect.size.width - 8;    
	
	[[UIColor whiteColor] set];
	CGContextFillRect(context, rect);
    
    h = [UIFont boldSystemFont16].lineHeight;

    float headerHeight = h + 4;

    [[UIColor colorWithWhite:0.85 alpha:1] set];
	CGContextFillRect(context, CGRectMake(0, y, rect.size.width, headerHeight));
    
    // render number
    
    if (_comment.isNew)
        [[UIColor altBlueColor] set];
    else        
        [[UIColor blackColor] set];
    
    NSString * number = KxUtils.format(@"%ld", _comment.number);         
    
    size = [number sizeWithFont:[UIFont systemFont12] 
              constrainedToSize:CGSizeMake(w, 999999) 
                  lineBreakMode:UILineBreakModeTailTruncation];    
    
    [number drawInRect:CGRectMake(w - size.width,                                  
                                  y + 4, 
                                  size.width, 
                                  headerHeight) 
              withFont:[UIFont systemFont12] 
         lineBreakMode:UILineBreakModeTailTruncation];    
    
    // render name or delete message
    
    if (_comment.deleteMsg.nonEmpty) {
       
        [[UIColor darkGrayColor] set]; 
        NSString *s = KxUtils.format(locString(@" - deleted %@"), _comment.deleteMsg);
        [s drawInRect:CGRectMake(x, y + 2, w - size.width, headerHeight) 
             withFont:[UIFont systemFont12]  
        lineBreakMode:UILineBreakModeTailTruncation];
        
        return;
        
    } 
        
    if (_comment.name.nonEmpty) {
          
        TextLine *nameLine = _comment.nameLine;
        [nameLine drawInRect:CGRectMake(x, y + 2, w - size.width, headerHeight) 
                    withFont:[UIFont boldSystemFont16] 
                    andColor:_comment.nameColor];
    }
    
    // render message
    
    y += headerHeight;
    
    if (_comment.isHidden) {
        
        [[UIColor grayColor] set];
        
        y += 5;
        
        NSString *s = locString(@"hidden comment");
        float dx = [s sizeWithFont:[UIFont systemFont14] 
                 constrainedToSize:CGSizeMake(w, 20) 
                     lineBreakMode:UILineBreakModeClip].width;
        
        dx = (w - dx) * .5;
        
        [s drawInRect:CGRectMake(x + dx, y, w  - dx, rect.size.height - y)
             withFont:[UIFont systemFont14]  
        lineBreakMode:UILineBreakModeClip];

        
    } else if (_comment.message.nonEmpty) {

        y += 5;      
        NSArray *lines = _comment.messageLines;        
        BOOL isQuote = lines.nonEmpty ? [lines.first isQuote] : NO;
        
        for (TextLine * line in lines) {
            
            if (isQuote != line.isQuote) 
                y += 2;
            isQuote = line.isQuote;
            
            if (line.isQuote) {
                                
                y += [line drawInRect:CGRectMake(x + 5, y, w - 5, rect.size.height - y)  
                             withFont:[UIFont systemFont12] 
                             andColor:[UIColor grayColor]].height;            
            }
            
            else {
                
                y += [line drawInRect:CGRectMake(x, y, w, rect.size.height - y)  
                             withFont:[UIFont systemFont14] 
                             andColor:line.link.nonEmpty ? [UIColor altBlueColor] : [UIColor blackColor]].height;
            }

        }
    }
    
    // render timestamp
    
    y += 2;
    [[UIColor grayColor] set];
    NSString * date = [_comment.timestamp shortRelativeFormatted]; 
    
    float dx = [date sizeWithFont:[UIFont systemFont12] 
                constrainedToSize:CGSizeMake(w, 999999) 
                    lineBreakMode:UILineBreakModeTailTruncation].width;
    
    y += [date drawInRect:CGRectMake(w - dx , y, dx, rect.size.height - y) 
                 withFont:[UIFont systemFont12] 
            lineBreakMode:UILineBreakModeTailTruncation].height;     
 
}

- (void) touchUpInside:(CGPoint)loc
{
    if (self.wantTouches) {
               
        for (TextLine *line in [_comment messageLines]) {
            
            if (line.link.nonEmpty) {
                
                if (CGRectContainsPoint(line.bounds, loc)) {
                    
                    //[self openUrl:line.link];
                    [self.delegate handleLink: line.link];
                    break;
                    
                }
            }
        }   
    }
}



@end