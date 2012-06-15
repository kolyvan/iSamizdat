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
#import "SamLibAuthor.h"
#import "SamLibAuthor+IOS.h"
#import "SamLibText+IOS.h"
#import "NSString+Kolyvan.h"
#import "NSArray+Kolyvan.h"
#import "NSDate+Kolyvan.h"
#import "FastCell.h"
#import "TextReadViewController.h"
#import "CommentsViewController.h"
#import "UIFont+Kolyvan.h"
#import "DDLog.h"

extern int ddLogLevel;

@interface NoteCell : FastCell

@property (nonatomic, strong) NSString *note;

+ (CGFloat) computeHeight: (NSString *) note 
                 forWidth: (CGFloat) width;

@end

@implementation NoteCell

@synthesize note = _note;


+ (CGFloat) computeHeight: (NSString *) note 
                 forWidth: (CGFloat) width
{    
    return [note sizeWithFont:[UIFont systemFont14] 
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
              withFont:[UIFont systemFont14]  
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
    //RowGroup,    
    RowGenre,
    RowComments,
    RowMakeDiff,            
    RowRead,
    RowDiff, 
    RowMyVote,
    //RowMyMemo,
};

@interface TextViewController () {
    BOOL _needReload;
    id _version;
    NSArray *_rows;
}

@property (nonatomic, strong) TextReadViewController *textReadViewController;
@property (nonatomic, strong) CommentsViewController *commentsViewController;
@property (nonatomic, strong) VoteViewController *voteViewController;

@end

@implementation TextViewController

@synthesize text = _text;
@synthesize textReadViewController;
@synthesize commentsViewController;
@synthesize voteViewController;

- (void) setText:(SamLibText *)text 
{    
    if (text != _text || 
        ![text.version isEqual:_version]) {        
        
        _version = text.version;
        _text = text;
        _needReload = YES;
    }
}


- (id) init
{
    return [self initWithNibName:@"TextViewController" bundle:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *goButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction 
                                                                               target:self 
                                                                               action:@selector(goSafari)];
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back.png"]
                                                                   style:UIBarButtonItemStylePlain                                                                                           target:nil                                                                                            action:nil];
    

    self.navigationItem.rightBarButtonItem = goButton;    
    self.navigationItem.backBarButtonItem = backButton;

}

- (void) viewWillAppear:(BOOL)animated 
{    
    [super viewWillAppear:animated];
    if (_needReload) {
        _needReload = NO;           
        self.title = _text.author.name;        
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
    self.commentsViewController = nil;
    self.voteViewController = nil;
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];         
    self.textReadViewController = nil;
    self.commentsViewController = nil;    
    self.voteViewController = nil;    
}

#pragma mark - private

- (void) prepareData
{
    NSMutableArray *ma = [NSMutableArray array];
    
    [ma push: $int(RowTitle)];
        
    [ma push: $int(RowSize)];
      
    [ma push: $int(RowComments)];
     
    // fixme: below is most likely wrong code
    if (_text.htmlFile.nonEmpty) {
        
        if (_text.canUpdate)
            [ma push: $int(RowUpdate)];
        
        [ma push: $int(RowRead)];
    } else {
    
        if (_text.changedSize &&
            _text.canUpdate)
            [ma push: $int(RowUpdate)];
    }
    
    if (_text.canMakeDiff)
        [ma push: $int(RowMakeDiff)];

    if (_text.diffFile.nonEmpty)
        [ma push: $int(RowDiff)];
    
    if (_text.note.nonEmpty)
        [ma push: $int(RowNote)];
        
    //if (_text.group.nonEmpty)
    //    [ma push: $int(RowGroup)];
        
    if (_text.genre.nonEmpty ||
        _text.type.nonEmpty)
        [ma push: $int(RowGenre)];  
    
    [ma push: $int(RowMyVote)];  

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
        formatter: ^(SamLibText *text, NSString * html) { 
            return mkHTMLPage(text, html); 
        } 
     ];

}

- (NSString *) textVoteString
{
     NSInteger myVote = _text.myVote;
    if (myVote == 0)
        return locString(@"none");
    else if (myVote > 0 && myVote < 11)
        return KxUtils.format(@"%ld", myVote);  
    else
        return @"ERR";
}

- (void) goSafari
{    
    NSURL *url = [NSURL URLWithString: [@"http://" stringByAppendingString: _text.url]];
    [UIApplication.sharedApplication openURL: url];                     
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
        
    //} else if (RowGroup == row) {
    //    
    //    UITableViewCell *cell = [self mkCell: @"GenreCell" withStyle:UITableViewCellStyleDefault];             
    //    cell.textLabel.text = _text.group;
    //    return cell;
    
    } else if (RowGenre == row) {
        
        UITableViewCell *cell = [self mkCell: @"GenreCell" withStyle:UITableViewCellStyleDefault];             
        NSMutableString *ms = [NSMutableString string];
        
        if (_text.group.nonEmpty) {
            [ms appendString:_text.group];                
        }        
        if (_text.type.nonEmpty) {
            if (ms.length > 0)
                [ms appendString:@", "];
            [ms appendString:_text.type];                
        }
        if (_text.genre.nonEmpty) {
            if (ms.length > 0)
                [ms appendString:@", "];
            [ms appendString:_text.genre];                                
        }            
        cell.textLabel.text = ms;
        cell.textLabel.numberOfLines = 2;
        cell.textLabel.font = [UIFont boldSystemFont14];
        return cell;
        
    } else if (RowComments == row) {
        
        UITableViewCell *cell = [self mkCell: @"CommentsCell" withStyle:UITableViewCellStyleValue1];                    
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.text = locString(@"Comments");
        cell.detailTextLabel.text = [_text commentsWithDelta: @" "];  
        return cell;
        
    } else if (RowRead == row) {
        
        UITableViewCell *cell = [self mkCell: @"ReadCell" withStyle:UITableViewCellStyleValue1];                    
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.text = locString(@"The text from");
        cell.detailTextLabel.text = _text.dateModified;          
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
        
    } else if (RowMyVote == row) {
        
        UITableViewCell *cell = [self mkCell: @"VoteCell" withStyle:UITableViewCellStyleValue1];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;        
        cell.textLabel.text = locString(@"My vote");
        cell.detailTextLabel.text = [self textVoteString];
        return cell;
    }        
    
    return nil;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = [[_rows objectAtIndex:indexPath.row] integerValue];     
    
    if (RowRead == row) {
        
        if (!self.textReadViewController) {
            self.textReadViewController = [[TextReadViewController alloc] init];
        }
        
        self.textReadViewController.text = _text;
        [self.navigationController pushViewController:self.textReadViewController 
                                             animated:YES]; 
        
    } else if (RowComments == row) {
        
        if (!self.commentsViewController) {
            self.commentsViewController = [[CommentsViewController alloc] init];
        }
        
        self.commentsViewController.comments = [_text commentsObject:YES];
        [self.navigationController pushViewController:self.commentsViewController 
                                             animated:YES]; 
        
    } else if (RowMyVote == row) {
        
        if (!self.voteViewController) {
            self.voteViewController = [[VoteViewController alloc] init];
            self.voteViewController.delegate = self;
        }
        
        self.voteViewController.myVote = _text.myVote;
        [self.navigationController pushViewController:self.voteViewController 
                                             animated:YES]; 
        
    }

}

#pragma mark - VoteViewController delagate

- (void) sendVote: (NSInteger) vote
{
    //NSLog(@"send vote: %d", vote);
    
    NSInteger row = [_rows indexOfObject:$int(RowMyVote)];
    
    NSIndexPath *indexPath;
    UITableViewCell *cell;
    indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    cell = [self.tableView cellForRowAtIndexPath:indexPath];
    
    cell.detailTextLabel.text = @"..";
    
    [_text vote: vote
         block: ^(SamLibText *text, SamLibStatus status, NSString *error) {             

             if (status == SamLibStatusSuccess)
                 cell.detailTextLabel.text = [self textVoteString];
             else
                 cell.detailTextLabel.text = @"ERR";
             
         }];
}

@end
