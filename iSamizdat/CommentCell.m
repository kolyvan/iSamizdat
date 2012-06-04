//
//  CommentCell.m
//  iSamizdat
//
//  Created by Kolyvan on 04.06.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//

#import "CommentCell.h"
#import "KxArc.h"
#import "KxUtils.h"
#import "NSString+Kolyvan.h"
#import "NSDate+Kolyvan.h"
#import "SamLibComment+IOS.h"
#import "SamLibComments.h"
#import "CommentsViewController.h"
#import "TextLine.h"
#import "UIFont+Kolyvan.h"

////

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
    BOOL _swipe;
    KX_WEAK CommentsViewController * _controller;
}
@end

@implementation CommentCell

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
          controller:(CommentsViewController *)controller 
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) 
    {
        _controller = controller;
        
		self.backgroundColor = [UIColor whiteColor];
		self.opaque = YES;
        
        // configure "backView"
        /*
        UIButton* replyButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        replyButton.frame = CGRectMake(5, 5, 60, 30);
        [replyButton setTitle:@"Reply" forState:UIControlStateNormal];        
        [replyButton addTarget:self action:@selector(replyPressed) forControlEvents:UIControlEventTouchUpInside];        
        replyButton.tag = 0;        
        [self.backView addSubview:replyButton];
        
        UIButton* deleteButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        deleteButton.frame = CGRectMake(75, 5, 60, 30);
        [deleteButton setTitle:@"Delete" forState:UIControlStateNormal];        
        [deleteButton addTarget:self action:@selector(deletePressed) forControlEvents:UIControlEventTouchUpInside];        
        deleteButton.tag = 1;
        [self.backView addSubview:deleteButton];
        
        UIButton* editButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        editButton.frame = CGRectMake(145, 5, 60, 30);
        [editButton setTitle:@"Edit" forState:UIControlStateNormal];        
        [editButton addTarget:self action:@selector(editPressed) forControlEvents:UIControlEventTouchUpInside];                
        editButton.tag = 2;        
        [self.backView addSubview:editButton];
        self.backView.hidden = YES;        
        
        self.backView.backgroundColor = [UIColor groupTableViewBackgroundColor];
        */ 
        
    }
    return self;
}

/*
- (void) prepareForReuse 
{
	[super prepareForReuse];    
    self.backView.hidden = YES;    
}

- (void) setEditing:(BOOL)editing animated:(BOOL)animated {
    // Do not call the super method. It shows a delete button by deafult
	// [super setEditing:editing animated:animated];
    
    if (_comment.deleteMsg.nonEmpty)
        return;
	
    if (editing) {
        // swipe
        
        if (!_swipe) {
            _swipe = YES;
            
            self.backView.hidden = NO;        
            [self.backView viewWithTag:1].hidden = !_comment.canDelete;
            [self.backView viewWithTag:2].hidden = !_comment.canEdit;
            
            [UIView beginAnimations:@"" context:nil];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
            CGRect frame = self.contentView.frame;
            // this makes visible just 10 points of the contentView
            frame.origin.x = self.contentView.frame.size.width - 10;
            self.contentView.frame = frame;
            [UIView commitAnimations];
        }
        
    } else {
        
        if (_swipe) {
            // swipe finished
            _swipe = NO;
            [UIView beginAnimations:@"" context:nil];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
            CGRect frame = self.contentView.frame;
            frame.origin.x = 0;
            self.contentView.frame = frame;
            [UIView commitAnimations];        
        }
        else {
            // ? [self setNeedsDisplay];
        }
    } 
}

- (void) swipeClose
{
    UIView* view = self.superview;
    if ([view isKindOfClass:[UITableView class]]) {
        UITableView* table = (UITableView*)view;
        [table setEditing:NO animated:YES];
    }
}
 
- (void) replyPressed 
{    
    NSLog(@"replyPressed");
    [self swipeClose];   
    
    [_controller goReplyView];
    
}

- (void) deletePressed 
{    
    NSLog(@"rdeletePressed");    
    [self swipeClose];
}

- (void) editPressed 
{    
    NSLog(@"editPressed");    
    [self swipeClose];
}
 */

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