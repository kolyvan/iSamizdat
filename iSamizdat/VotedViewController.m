//
//  VotedViewController.m
//  iSamizdat
//
//  Created by Kolyvan on 17.07.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//

#import "VotedViewController.h"
#import "KxMacros.h"
#import "KxUtils.h"
#import "NSArray+Kolyvan.h"
#import "NSDictionary+Kolyvan.h"
#import "SamLibModel.h"
#import "SamLibAuthor.h"
#import "SamLibText.h"

#import "SamLibText+IOS.h"

static UIImage * mkVoteImage(NSInteger number)
{
    static NSMutableDictionary *cache;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [[NSMutableDictionary alloc] init];
    });
    
    NSString *text;
    if (number > 9)
        text = @"X";
    else
        text = KxUtils.format(@"%ld", number);
    
    return [cache get:text orSet:^id{
        
        const float R = 0; 
        const float G = 51.0/255;
        const float B = 102.0/255;
        
        CGSize size = {24,24};
        
        UIGraphicsBeginImageContext(size);
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        CGRect rect = CGRectMake(0, 0, size.width, size.height);
        CGContextClipToRect(context, rect);
        
        //[[UIColor lightGrayColor] set];
        [[UIColor clearColor] set];
        UIRectFill(rect);
        
        CGRect circle = CGRectInset(rect, 1.0f, 1.0f);
        CGContextSetRGBStrokeColor(context, R, G, B, 0.5f); 
        //CGContextSetRGBFillColor(context, R, G, B, 0.2f);
        CGContextSetLineWidth(context, 2.0f);
        //CGContextFillEllipseInRect(context, circle);
        CGContextStrokeEllipseInRect(context, circle);
        
        //[[UIColor darkTextColor] set]; 
        [[UIColor colorWithRed:R green:G blue:B alpha:1] set]; 
        rect.origin.x += 1;
        rect.size.width -= 1; 
        [text drawInRect:rect
                withFont:[UIFont boldSystemFontOfSize:20] 
           lineBreakMode:UILineBreakModeTailTruncation 
               alignment:UITextAlignmentCenter];
        
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();        
        return image;
    }];
}


@interface VotedViewController () {
    BOOL _sortByVote;
}
@end

@implementation VotedViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.title = locString(@"Voted");
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:locString(@"Voted")
                                                        image:[UIImage imageNamed:@"voted"] 
                                                          tag:0];
 
    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
        
    
    UIBarButtonItem *sortBtn =  [[UIBarButtonItem alloc] initWithTitle:locString(@"by vote")
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(toggleSort:)];
    
    self.navigationItem.rightBarButtonItem = sortBtn;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.navigationItem.rightBarButtonItem = nil;
    _sortByVote = NO;
}

- (void) toggleSort: (UIBarButtonItem *) button
{
    _sortByVote = !_sortByVote;
    button.title = _sortByVote ? locString(@"by author") : locString(@"by vote");
    [self refreshView];
}

- (NSArray *) prepareData
{
    NSArray *authors = [SamLibModel shared].authors;
    
    NSMutableArray *ma = [NSMutableArray array];
    
    for (SamLibAuthor *author in authors) {
        if (!author.ignored) {
            for (SamLibText *text in author.texts) {            
                if (text.myVote != 0)
                    [ma push:text];  
            }
        }
    }
    
    if (_sortByVote) {
    
        return [ma sortWith:^(SamLibText *l, SamLibText *r) {
            // reversi order
            if (l.myVote > r.myVote) return NSOrderedAscending;
            if (l.myVote < r.myVote) return NSOrderedDescending;
            return NSOrderedSame;            
        }];
    }
    
    return ma;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    UITableViewCell *cell; 
    cell = [self mkCell: @"Cell" withStyle:UITableViewCellStyleSubtitle];    
                
    SamLibText *text = [self.texts objectAtIndex:indexPath.row];     
    cell.textLabel.text = text.title;
    cell.detailTextLabel.text = text.author.name;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.imageView.image = mkVoteImage(text.myVote);
    return cell;
}

@end
