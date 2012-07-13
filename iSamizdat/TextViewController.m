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
#import "AuthorViewController.h"
#import "TextContainerController.h"
#import "UIFont+Kolyvan.h"
#import "DDLog.h"
#import "SHK.h"

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

@property (nonatomic, strong) VoteViewController *voteViewController;
@property (nonatomic, strong) AuthorViewController *authorViewController;

@end

@implementation TextViewController

@synthesize text = _text;
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
    }
    return self;
}

- (void)viewDidLoad
{    
    [super viewDidLoad];
    
    UIBarButtonItem *goButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction 
                                                                               target:self 
                                                                               action:@selector(goShare)];

    self.navigationItem.rightBarButtonItem = goButton;    
   
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

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (_text.changedSize || (_text.isNew && _text.flagNew != nil)) {
        
        [_text flagAsChangedNone];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"samLibTextChanged" object:nil];        
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.navigationItem.rightBarButtonItem = nil;
    self.voteViewController = nil;
    self.authorViewController = nil;
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];            
    self.voteViewController = nil;    
    self.authorViewController = nil;
}

#pragma mark - private

- (void) prepareData
{
    NSMutableArray *ma = [NSMutableArray array];
            
    [ma push: $int(RowTitle)];
        
    NSArray * controllers = self.navigationController.viewControllers;
    UIViewController *backView =[controllers objectAtIndex: controllers.count - 2];
    if (![backView isKindOfClass:[AuthorViewController class]])
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
    
    if ([_text commentsObject:NO] != nil ||
        _text.htmlFile.nonEmpty ||         
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

- (void) goShare
{   
    SHKItem *item = [SHKItem URL:[NSURL URLWithString: [@"http://" stringByAppendingString: _text.url]] 
                           title:KxUtils.format(@"%@. %@.", _text.author.name, _text.title) 
                     contentType:(SHKURLContentTypeWebpage)];
    SHKActionSheet *actionSheet = [SHKActionSheet actionSheetForItem:item];
    [SHK setRootViewController:self];
    [actionSheet showFromBarButtonItem:self.navigationItem.rightBarButtonItem 
                              animated:YES]; 
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
    [actionSheet showFromTabBar:self.tabBarController.tabBar];
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
    [actionSheet showFromTabBar:self.tabBarController.tabBar];
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
        cell.accessoryView = [[UIImageView alloc] initWithImage: [UIImage imageNamed:@"download.png"]];
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
       
        UITableViewCell *cell = [self mkCell: @"TitleCell" withStyle:UITableViewCellStyleDefault];                   
        cell.textLabel.text = _text.title;
        cell.textLabel.numberOfLines = 0;
        //[cell.textLabel sizeToFit];       
        cell.accessoryView = [[UIImageView alloc] initWithImage: _text.favoritedImage];                          
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
        cell.textLabel.text = locString(@"Comments");
        cell.detailTextLabel.text = [_text commentsWithDelta: @" "];  
        return cell;
        
    } else if (RowRead == row) {
        
        UITableViewCell *cell = [self mkCell: @"ReadCell" withStyle:UITableViewCellStyleValue1];                    
        cell.textLabel.text = locString(@"The text from");
        cell.detailTextLabel.text = _text.dateModified.nonEmpty ? _text.dateModified : @"?";          
        return cell;
        
    } else if (RowUpdate == row) {
        
        UITableViewCell *cell = [self mkDownloadCell];
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
        cell.accessoryView = [[UIImageView alloc] initWithImage: [UIImage imageNamed:@"trash"]];                        
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
    
    if (RowTitle == row) {
        
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        
        _text.favorited = !_text.favorited;
        ((UIImageView *)cell.accessoryView).image = _text.favoritedImage;               
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"samLibTextChanged" object:nil];
    
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
        
    }  else if (RowUpdate == row ||
                RowDownload == row) {
        
        [self goDownload];
        
    } else if (RowCleanup == row) {
        
        [self goCleanup];
        
    } else if (RowRead == row ||
               RowComments == row) {        
        
        if ([self.parentViewController isKindOfClass:[TextContainerController class]]) {
            TextContainerController *container = (TextContainerController *)self.parentViewController; 
            [container setSelected:RowRead == row ? TextReadViewSelected  : TextCommentsViewSelected
                          animated:YES];
        }
    } 
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - VoteViewController delagate

- (void) sendVote: (NSInteger) vote
{        
    NSInteger row = [_rows indexOfObject:$int(RowMyVote)];
    
    NSIndexPath *indexPath;
    UITableViewCell *cell;
    indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    cell = [self.tableView cellForRowAtIndexPath:indexPath];
    
    cell.detailTextLabel.text = @"..";
    
    if (0 == _text.myVote || 0 == vote)
        [[NSNotificationCenter defaultCenter] postNotificationName:@"samLibTextChanged" object:nil];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [_text vote: vote
         block: ^(SamLibText *text, SamLibStatus status, NSString *error) {             
             
             [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

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
