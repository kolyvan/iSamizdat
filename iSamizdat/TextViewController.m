//
//  TextViewController.m
//  iSamizdat
//
//  Created by Kolyvan on 29.05.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//
//  https://github.com/kolyvan/iSamizdat
//  this file is part of iSamizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt
// 

#import "TextViewController.h"
#import "KxArc.h"
#import "SamLibText.h"
#import "SamLibText+IOS.h"
#import "KxMacros.h"
#import "KxUtils.h"
#import "NSString+Kolyvan.h"
#import "FastCell.h"

@interface NoteCell : FastCell

@property (nonatomic, strong) NSString *note;

+ (CGFloat) computeHeight: (NSString *) note 
                 forWidth: (CGFloat) width;

@end

@implementation NoteCell

@synthesize note = _note;

static UIFont* systemFont14 = nil;

+ (void)initialize
{
	if (self == [NoteCell class])
	{		
		systemFont14 = [UIFont systemFontOfSize:14];     
	}
}

+ (CGFloat) computeHeight: (NSString *) note 
                 forWidth: (CGFloat) width
{    
    return [note sizeWithFont:systemFont14 
            constrainedToSize:CGSizeMake(width - 20, 999999) 
                lineBreakMode:UILineBreakModeTailTruncation].height + 20;  
}

- (void) drawContentView:(CGRect)rect 
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	[[UIColor whiteColor] set];
	CGContextFillRect(context, rect);
    
    [[UIColor darkTextColor] set];
    [_note drawInRect: CGRectInset(rect, 10, 10)
              withFont:systemFont14 
         lineBreakMode:UILineBreakModeTailTruncation];    
}

@end

////

@interface TitleCell : UITableViewCell

@property (nonatomic, KX_PROP_WEAK) TextViewController *controller;

@end

@implementation TitleCell

@synthesize controller;

- (void)touchesEnded:(NSSet *)touches
           withEvent:(UIEvent *)event
{   
    UITouch *t = [touches anyObject];
    if ([t tapCount] > 1)
        return;  // double tap
            
    CGPoint loc = [t locationInView:self];     
    if (CGRectContainsPoint(self.imageView.frame, loc)) {

        controller.text.favorited = !controller.text.favorited;
        self.imageView.image = controller.text.favoritedImage;        
    }
}

@end
////

#define TextViewSection0_RowTitle 0
#define TextViewSection0_RowSize  1    
#define TextViewSection0_RowNote  2        
#define TextViewSection0_RowGenre 3
#define TextViewSection0_RowComments 4
#define TextViewSection0_RowSaved1 5
#define TextViewSection0_RowSaved2 6


@interface TextViewController () {
    BOOL _needReload;
    id _version;
}
@end

@implementation TextViewController

@synthesize text = _text;

- (void) setText:(SamLibText *)text 
{    
    if (text != _text || 
        ![text.version isEqual:_version]) {        
        
        _version = text.version;
        _text = text;
        _needReload = YES;
    }
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *goButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks 
                                                                               target:self 
                                                                               action:@selector(goRead)];
    
    self.navigationItem.rightBarButtonItem = goButton;
    
    self.title = locString(@"Text");
}

- (void) viewWillAppear:(BOOL)animated 
{    
    [super viewWillAppear:animated];
    if (_needReload) {
        _needReload = NO;        
        [self.tableView reloadData];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.navigationItem.rightBarButtonItem = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

/*
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{   
    if (section == 0)
        return _text.title;
    return @"";
}
*/

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath 
{  
    if (indexPath.section == 0 && indexPath.row == TextViewSection0_RowNote) {
        return [[NoteCell class] computeHeight:_text.note 
                                      forWidth:tableView.frame.size.width];
        
    //    return [_text.note sizeWithFont:[UIFont systemFontOfSize: 14] 
    //                  constrainedToSize:CGSizeMake(tableView.frame.size.width - 20, 999999) 
    //                      lineBreakMode:UILineBreakModeTailTruncation].height + 20;
        
    }
    return self.tableView.rowHeight;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{   
    return 6;    
}

- (id) mkCell: (NSString *) cellIdentifier
    withStyle: (UITableViewCellStyle) style
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:style reuseIdentifier:cellIdentifier];                
    }
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        
        if (TextViewSection0_RowNote == indexPath.row) { 
            
            static NSString *CellIdentifier = @"NoteCell";
            NoteCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];            
            if (cell == nil) {
                cell = [[NoteCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                              reuseIdentifier:CellIdentifier];
            }
            cell.note = _text.note;
           
            /*
            UITableViewCell *cell = [self mkCell: @"NoteCell" withStyle:UITableViewCellStyleValue1];
            cell.textLabel.text = _text.note;
            cell.textLabel.numberOfLines = 0;
            cell.textLabel.font = [UIFont systemFontOfSize: 14];
            */
            return cell;
            
        } else  if (TextViewSection0_RowTitle == indexPath.row) { 
            
            //UITableViewCell *cell = [self mkCell: @"TitleCell" withStyle:UITableViewCellStyleValue1];
            
            TitleCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"TitleCell"];    
            if (cell == nil) {
                cell = [[TitleCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"TitleCell"];                
            }
            
            cell.controller = self;
            cell.textLabel.text = _text.title;
            cell.textLabel.numberOfLines = 0;
            cell.imageView.image = _text.favoritedImage;
            cell.detailTextLabel.text = [_text ratingWithDelta:@" "];
            return cell;
            
        } else  if (TextViewSection0_RowSize == indexPath.row) { 
           
            UITableViewCell *cell = [self mkCell: @"SizeCell" withStyle:UITableViewCellStyleValue1];            
            cell.textLabel.text = locString(@"Size");
            cell.detailTextLabel.text = [_text sizeWithDelta: @" "];
            return cell;    
            
        } else if (TextViewSection0_RowGenre == indexPath.row) {
                            
            UITableViewCell *cell = [self mkCell: @"GenreCell" withStyle:UITableViewCellStyleDefault];             
            NSMutableString *ms = [NSMutableString string];
                
            if (_text.type.nonEmpty) {
                [ms appendString:_text.type];                
            }
            if (_text.genre.nonEmpty) {
                if (ms.length > 0)
                    [ms appendString:@", "];
                [ms appendString:_text.genre];                                
            }            
            cell.textLabel.text = ms;
            return cell;
            
        } else if (TextViewSection0_RowComments == indexPath.row) {
        
            UITableViewCell *cell = [self mkCell: @"CommentsCell" withStyle:UITableViewCellStyleValue1];                    
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.text = locString(@"Comments");
            cell.detailTextLabel.text = [_text commentsWithDelta: @" "];  
            return cell;
            
        } else if (TextViewSection0_RowSaved1 == indexPath.row) {
            
            UITableViewCell *cell = [self mkCell: @"CommentsCell" withStyle:UITableViewCellStyleDefault];                    
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.text = locString(@"Saved copy");
            return cell;
        }        
    }

    return nil;
}


#pragma mark - Table view delegate

@end
