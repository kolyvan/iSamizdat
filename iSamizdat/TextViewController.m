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
#import "SamLibComments.h"
#import "SamLibAuthor.h"
#import "SamLibAuthor+IOS.h"
#import "SamLibText+IOS.h"
#import "NSString+Kolyvan.h"
#import "NSArray+Kolyvan.h"
#import "NSDate+Kolyvan.h"
#import "FastCell.h"
#import "TextReadViewController.h"
#import "CommentsViewController.h"
#import "AuthorViewController.h"
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
    CGRect bounds = CGRectInset(self.imageView.frame, -10, -10);
    if (CGRectContainsPoint(bounds, loc)) {

        controller.text.favorited = !controller.text.favorited;
        self.imageView.image = controller.text.image;        
    }
}

@end

////

enum {
    RowTitle,
    RowAuthor,
    RowSize,
    RowUpdate,    
    RowDownload,  
    RowRating,
    RowMyVote,    
    RowNote,
    RowGenre,
    RowComments,
    RowRead,
    RowCleanup, 
};

@interface TextViewController () {
    BOOL _needReload;
    id _version;
    NSArray *_rows;
}

@property (nonatomic, strong) TextReadViewController *textReadViewController;
@property (nonatomic, strong) CommentsViewController *commentsViewController;
@property (nonatomic, strong) VoteViewController *voteViewController;
@property (nonatomic, strong) AuthorViewController *authorViewController;

@end

@implementation TextViewController

@synthesize text = _text;
@synthesize textReadViewController;
@synthesize commentsViewController;
@synthesize voteViewController;
@synthesize authorViewController;

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
    self = [self initWithNibName:@"TextViewController" bundle:nil];
    if (self) {
        self.title = locString(@"Text Info");
    }
    return self;
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
        //self.title = _text.title;   
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
    self.authorViewController = nil;
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];         
    self.textReadViewController = nil;
    self.commentsViewController = nil;    
    self.voteViewController = nil;    
    self.authorViewController = nil;
}

#pragma mark - private

- (void) prepareData
{
    NSMutableArray *ma = [NSMutableArray array];
    
    NSLog(@"%@ prepareData", [self class]);
    
    [ma push: $int(RowTitle)];
        
    [ma push: $int(RowAuthor)];
            
    [ma push: $int(RowSize)];
      
    [ma push: $int(RowComments)];
     
    // fixme: below is most likely wrong code
    if (_text.htmlFile.nonEmpty) {
        
        if (_text.changedSize && _text.canUpdate)
            [ma push: $int(RowUpdate)];
        
        [ma push: $int(RowRead)];
        
    } else {
    
        if (_text.changedSize)
            [ma push: $int(RowUpdate)];
        else    
            [ma push: $int(RowDownload)];
    }
   
    if (_text.note.nonEmpty)
        [ma push: $int(RowNote)];
        
    if (_text.ratingFloat > 0)
        [ma push: $int(RowRating)];          
    
    [ma push: $int(RowMyVote)];  
    
    if (_text.htmlFile.nonEmpty || 
        _text.commentsFile.nonEmpty) {
        
        [ma push: $int(RowCleanup)];
    }        
    
    if (_text.genre.nonEmpty ||
        _text.type.nonEmpty) {
        
        [ma push: $int(RowGenre)];          
    }

    _rows = [ma toArray];
}

- (NSDate *) lastUpdateDate
{
    return _text.timestamp;
}

- (void) refresh: (void(^)(SamLibStatus status, NSString *error)) block
{
    [_text update:^(SamLibText *text, SamLibStatus status, NSString *error) {
        
        NSString *message = (status == SamLibStatusFailure) ? error : nil;
        block(status, message);        
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

- (void) goDownload
{
    UIActionSheet *actionSheet;
    actionSheet = [[UIActionSheet alloc] initWithTitle:locString(@"Download text?")
                                              delegate:self
                                     cancelButtonTitle:locString(@"Cancel") 
                                destructiveButtonTitle:nil
                                     otherButtonTitles:locString(@"Download"), nil];
    
    actionSheet.tag = 0;
    [actionSheet showInView:self.view];
}

- (void) goCleanup
{
    UIActionSheet *actionSheet;
    actionSheet = [[UIActionSheet alloc] initWithTitle:locString(@"Remove text and comments?")
                                              delegate:self
                                     cancelButtonTitle:locString(@"Cancel") 
                                destructiveButtonTitle:nil
                                     otherButtonTitles:locString(@"Remove"), nil];
    
    actionSheet.tag = 1;
    [actionSheet showInView:self.view];
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
    } else  if (RowTitle == row) { 
              
        CGFloat h = [_text.title sizeWithFont:[UIFont boldSystemFont16] 
                            constrainedToSize:CGSizeMake(246, 9999) 
                                lineBreakMode:UILineBreakModeWordWrap].height;
        
        return MAX(self.tableView.rowHeight, h + 20);
    }
    return self.tableView.rowHeight;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{   
    return _rows.count;    
}

- (UITableViewCell *) mkDownloadCell
{
    static NSString *CellIdentifier = @"DownloadCell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                      reuseIdentifier:CellIdentifier];   
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];        
        button.frame = CGRectMake(0, 0, 24, 24);        
        [button addTarget:self 
                   action:@selector(goDownload) 
        forControlEvents:UIControlEventTouchUpInside];        
        [button setBackgroundImage:[UIImage imageNamed:@"download.png"]
                          forState:UIControlStateNormal];
        cell.accessoryView = button;
    }
    return cell;    
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
            cell = [[TitleCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"TitleCell"];                
        }
        
        cell.controller = self;
        cell.textLabel.text = _text.title;
        cell.textLabel.numberOfLines = 0;
        cell.imageView.image = _text.image;
                        
        return cell;
        
    } else  if (RowSize == row) { 
        
        UITableViewCell *cell = [self mkCell: @"SizeCell" withStyle:UITableViewCellStyleValue1];            
        cell.textLabel.text = locString(@"Size");
        cell.detailTextLabel.text = [_text sizeWithDelta: @" "];
        return cell;    
    
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
        
    } else if (RowUpdate == row) {
        
        UITableViewCell *cell = [self mkDownloadCell];
        //[self mkCell: @"UpdateCell" withStyle:UITableViewCellStyleDefault];  
        cell.textLabel.textColor = [UIColor blueColor];
        cell.textLabel.text = locString(@"Update is available");
        return cell; 
       
    } else if (RowDownload == row) {   
         
        UITableViewCell *cell = [self mkDownloadCell];                    
        cell.textLabel.text = locString(@"Download text");        
        cell.textLabel.textColor = [UIColor darkTextColor];        
        return cell; 
        
    } else if (RowMyVote == row) {
        
        UITableViewCell *cell = [self mkCell: @"VoteCell" withStyle:UITableViewCellStyleValue1];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;        
        cell.textLabel.text = locString(@"My vote");
        cell.detailTextLabel.text = [self textVoteString];
        return cell;
        
    } else if (RowCleanup == row) {
        
        UITableViewCell *cell = [self mkCell: @"CleanupCell" withStyle:UITableViewCellStyleDefault];
        cell.textLabel.text = locString(@"Cleanup cached");
        //cell.detailTextLabel.text = locString(@"cached text and comments");
                
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(0, 0, 24, 24);                    
        [button addTarget:self 
                   action:@selector(goCleanup) 
         forControlEvents:UIControlEventTouchUpInside];                    
        [button setBackgroundImage:[UIImage imageNamed:@"recycle"]
                          forState:UIControlStateNormal];
        cell.accessoryView = button;
        
        return cell;
        
    } else if (RowAuthor == row) {
        
        SamLibAuthor *author = _text.author;
        UITableViewCell *cell = [self mkCell: @"AuthorCell" withStyle:UITableViewCellStyleDefault];                    
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.text = author.name.nonEmpty ? author.name : author.path;          
        return cell;        
        
    } else if (RowRating == row) {

        UITableViewCell *cell = [self mkCell: @"RatingCell" withStyle:UITableViewCellStyleValue1];
        cell.textLabel.text = locString(@"Rating");     
        cell.detailTextLabel.text = [_text ratingWithDelta:@" "];        
        
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
        
        
    } else if (RowAuthor == row) {
        
        NSArray *controllers = self.navigationController.viewControllers;
        
        AuthorViewController *found;
        for (UIViewController *vc in controllers) {
            if ([vc isKindOfClass:[AuthorViewController class]]) {
                found = (AuthorViewController *)vc;
                break;
            }
        }
        
        if (found) {
            
            found.author = _text.author;
            [self.navigationController popToViewController:found animated:YES];
            
        } else {
            
            if (!self.authorViewController)
                self.authorViewController = [[AuthorViewController alloc] init];
            self.authorViewController.author = _text.author;            
            [self.navigationController pushViewController:self.authorViewController
                                                 animated:YES];
        }
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

#pragma mark - UIActionSheet delegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != actionSheet.cancelButtonIndex) {
      
        if (actionSheet.tag == 0) {
            
            [self forceRefresh];
            
        } else {
            
            [_text freeCommentsObject];
            [_text removeTextFiles:YES andComments:YES];   
            [self prepareData];
            [self.tableView reloadData];
            
        }
    }
}

@end
