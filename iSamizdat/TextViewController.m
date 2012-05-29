//
//  TextViewController.m
//  iSamizdat
//
//  Created by Kolyvan on 29.05.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//

#import "TextViewController.h"
#import "SamLibText.h"
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
}

- (void) viewWillAppear:(BOOL)animated 
{    
    [super viewWillAppear:animated];
    if (_needReload) {
        _needReload = NO;
        //self.title = _text.title;
        //[self prepareData];
        [self.tableView reloadData];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
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
    if (indexPath.section == 0 && indexPath.row == TextViewSection0_RowNote)
        return [[NoteCell class] computeHeight:_text.note 
                                      forWidth:tableView.frame.size.width];
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
            return cell;
            
        } else  if (TextViewSection0_RowTitle == indexPath.row) { 
            
            UITableViewCell *cell = [self mkCell: @"TitleCell" withStyle:UITableViewCellStyleValue1];
            cell.textLabel.text = _text.title;
            cell.detailTextLabel.text = [_text ratingWithDelta:@" "];
            return cell;
            
        } else  if (TextViewSection0_RowSize == indexPath.row) { 
           
            UITableViewCell *cell = [self mkCell: @"TitleCell" withStyle:UITableViewCellStyleValue1];            
            cell.textLabel.text = @"Size";
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
            cell.textLabel.text = @"Comments";
            cell.detailTextLabel.text = [_text commentsWithDelta: @" "];  
            return cell;
            
        } else if (TextViewSection0_RowSaved1 == indexPath.row) {
            
            UITableViewCell *cell = [self mkCell: @"CommentsCell" withStyle:UITableViewCellStyleDefault];                    
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.text = @"Saved copy";
            return cell;
        }        
    }

    return nil;
}


#pragma mark - Table view delegate

@end
