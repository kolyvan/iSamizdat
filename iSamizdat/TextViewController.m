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
#define NSNUMBER_SHORTHAND
#import "KxMacros.h"
#import "KxUtils.h"
#import "SamLibText.h"
#import "SamLibText+IOS.h"
#import "NSString+Kolyvan.h"
#import "NSArray+Kolyvan.h"
#import "NSDate+Kolyvan.h"
#import "FastCell.h"
#import "TextReadViewController.h"
#import "DDLog.h"

extern int ddLogLevel;

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

enum {
    RowTitle,
    RowSize,
    RowUpdate,    
    RowNote,
    RowGenre,
    RowComments,
    RowMakeDiff,            
    RowSaved1,
    RowSaved2,
    RowDiff, 
};

@interface TextViewController () {
    BOOL _needReload;
    id _version;
    NSArray *_rows;
}

@property (nonatomic, strong) TextReadViewController *textReadViewController;

@end

@implementation TextViewController

@synthesize text = _text;
@synthesize textReadViewController;

- (void) setText:(SamLibText *)text 
{    
    if (text != _text || 
        ![text.version isEqual:_version]) {        
        
        _version = text.version;
        _text = text;
        _needReload = YES;
    }
}

+ (NSString *) mkHTMLPage: (NSString *) html
{
    NSString *path = KxUtils.pathForResource(@"text.html");
    NSError *error;
    NSString *template = [NSString stringWithContentsOfFile:path 
                                                   encoding:NSUTF8StringEncoding 
                                                      error:&error];            
    if (!template.nonEmpty) {
        DDLogCWarn(@"file error %@", 
                   KxUtils.completeErrorMessage(error));
        return html;                
    }
    
    // replase css link from relative to absolute         
    template = [template stringByReplacingOccurrencesOfString:@"text.css" 
                                                   withString:KxUtils.pathForResource(@"text.css")];
    
    return [template stringByReplacingOccurrencesOfString:@"<!-- DOWNLOADED_TEXT -->" 
                                               withString:html];
}

- (id) init
{
    return [self initWithNibName:@"TextViewController" bundle:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *goButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks 
                                                                               target:self 
                                                                               action:@selector(goRead)];
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back.png"]
                                                                   style:UIBarButtonItemStylePlain                                                                                           target:nil                                                                                            action:nil];
    

    self.navigationItem.rightBarButtonItem = goButton;    
    self.navigationItem.backBarButtonItem = backButton;
    
    self.title = locString(@"Text");
}

- (void) viewWillAppear:(BOOL)animated 
{    
    [super viewWillAppear:animated];
    if (_needReload) {
        _needReload = NO;   
        
        [self prepareData];       
        [self.tableView reloadData];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.navigationItem.rightBarButtonItem = nil;
    self.navigationItem.backBarButtonItem = nil;
    self.textReadViewController = nil;
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];         
    self.textReadViewController = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - private

- (void) prepareData
{
    NSMutableArray *ma = [NSMutableArray array];
    
    [ma push: $int(RowTitle)];
    [ma push: $int(RowSize)];
    
    if (_text.note.nonEmpty)
        [ma push: $int(RowNote)];
    
    if (_text.genre.nonEmpty ||
        _text.type.nonEmpty)
        [ma push: $int(RowGenre)];

    [ma push: $int(RowComments)];
        
    if (_text.htmlFile.nonEmpty) {
        
        if (_text.canUpdate)
            [ma push: $int(RowUpdate)];
        
        [ma push: $int(RowSaved1)];
    }
    
    if (_text.canMakeDiff)
        [ma push: $int(RowMakeDiff)];

    if (_text.diffFile.nonEmpty)
        [ma push: $int(RowDiff)];

    _rows = [ma toArray];
}

- (NSDate *) lastUpdateDate
{
    return _text.timestamp;
}

- (void) refresh: (void(^)(SamLibStatus status, NSString *error)) block
{
    [_text update:^(SamLibText *text, SamLibStatus status, NSString *error) {
        
        block(status, error);        
        
    }
         progress: nil
        formatter: ^(NSString * html) { return [self->isa mkHTMLPage: html]; } 
     ];

}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath 
{  
    NSInteger row = [[_rows objectAtIndex:indexPath.row] integerValue];   
    if (RowNote == row) {
        return [[NoteCell class] computeHeight:_text.note 
                                      forWidth:tableView.frame.size.width];
    }
    return self.tableView.rowHeight;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{   
    return _rows.count;    
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{         
    NSInteger row = [[_rows objectAtIndex:indexPath.row] integerValue];    
        
    if (RowNote == row) { 
        
        static NSString *CellIdentifier = @"NoteCell";
        NoteCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];            
        if (cell == nil) {
            cell = [[NoteCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                   reuseIdentifier:CellIdentifier];
        }
        cell.note = _text.note;        
        return cell;
        
    } else  if (RowTitle == row) { 
        
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
        
    } else  if (RowSize == row) { 
        
        UITableViewCell *cell = [self mkCell: @"SizeCell" withStyle:UITableViewCellStyleValue1];            
        cell.textLabel.text = locString(@"Size");
        cell.detailTextLabel.text = [_text sizeWithDelta: @" "];
        return cell;    
        
    } else if (RowGenre == row) {
        
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
        
    } else if (RowComments == row) {
        
        UITableViewCell *cell = [self mkCell: @"CommentsCell" withStyle:UITableViewCellStyleValue1];                    
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.text = locString(@"Comments");
        cell.detailTextLabel.text = [_text commentsWithDelta: @" "];  
        return cell;
        
    } else if (RowSaved1 == row) {
        
        UITableViewCell *cell = [self mkCell: @"SavedCell" withStyle:UITableViewCellStyleValue1];                    
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.text = locString(@"Saved");
        cell.detailTextLabel.text = [_text.filetime shortRelativeFormatted];          
        return cell;
        
    } else if (RowDiff == row) {
        
        UITableViewCell *cell = [self mkCell: @"DiffCell" withStyle:UITableViewCellStyleDefault];                    
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.text = locString(@"Show Diff");
        return cell;
        
    } else if (RowUpdate == row) {
        
        UITableViewCell *cell = [self mkCell: @"UpdateCell" withStyle:UITableViewCellStyleDefault];                    
        cell.textLabel.text = locString(@"Update is available");
        cell.textLabel.textColor = [UIColor blueColor];
        return cell;
        
    } else if (RowMakeDiff == row) {
        
        UITableViewCell *cell = [self mkCell: @"MakeDiffCell" withStyle:UITableViewCellStyleDefault];                            
        cell.textLabel.text = locString(@"Make diff");
        return cell;
    }         
    
    return nil;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = [[_rows objectAtIndex:indexPath.row] integerValue];     
    
    if (RowSaved1 == row) {
        
        if (!self.textReadViewController) {
            self.textReadViewController = [[TextReadViewController alloc] init];
        }
        
        self.textReadViewController.text = _text;
        [self.navigationController pushViewController:self.textReadViewController 
                                             animated:YES]; 
    }
}


@end
