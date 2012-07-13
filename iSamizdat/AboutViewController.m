//
//  AboutViewController.m
//  iSamizdat
//
//  Created by Kolyvan on 13.07.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//

#import "AboutViewController.h"
#import "KxMacros.h"
#import "KxUtils.h"
#import "NSDictionary+Kolyvan.h"
#import <Twitter/Twitter.h>

enum {

    AboutViewRowCopyrigth,    
    AboutViewRowVersion,
    AboutViewRowLink,
    AboutViewRowTwitter,
    AboutViewRowEmail,   
    
    AboutViewRowsCount,
};


@interface AboutViewController ()
@property (readonly) UITableView *tableView;
@end

@implementation AboutViewController

@synthesize tableView = _tableView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
         self.title = locString(@"About");
    }
    return self;
}

- (void) loadView
{
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero 
                                              style:UITableViewStyleGrouped];
    
    self.view = _tableView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _tableView.delegate = self;
    _tableView.dataSource = self;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void) openUrl: (NSString *) s;
{
    NSURL *url = [NSURL URLWithString: s];
    [UIApplication.sharedApplication openURL: url];  
}

- (void) tweetFeedback
{
    if (![TWTweetComposeViewController canSendTweet])
        return;
    
    TWTweetComposeViewController *twitter = [[TWTweetComposeViewController alloc] init];
   
    NSDictionary *dict = [[NSBundle mainBundle] infoDictionary]; 
    [twitter setInitialText:KxUtils.format(@"%@@ ", [dict get:@"SamLibAboutTwitter" orElse:@"?"])];
          
    twitter.completionHandler = ^(TWTweetComposeViewControllerResult result)
    {
        [self dismissViewControllerAnimated:YES completion:nil];
        
        switch (result) {                
            case TWTweetComposeViewControllerResultDone:               
            case TWTweetComposeViewControllerResultCancelled:
            default:
                break;
        }
    };

    [self presentViewController:twitter animated:YES completion:nil];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{    
    return AboutViewRowsCount;
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
    UITableViewCell *cell;
    
    NSDictionary *dict = [[NSBundle mainBundle] infoDictionary];
    
    if (AboutViewRowVersion == indexPath.row) {
        
        cell = [self mkCell:@"Cell" withStyle:UITableViewCellStyleValue1];
        cell.textLabel.text = locString(@"Version");   
        cell.detailTextLabel.text = [dict get:@"CFBundleShortVersionString" orElse:@"?"];           
        
    } else if (AboutViewRowLink == indexPath.row) {

        cell = [self mkCell:@"LinkCell" withStyle:UITableViewCellStyleValue1];
        cell.textLabel.text = locString(@"Site");
        cell.detailTextLabel.text = [dict get:@"SamLibAboutSite" orElse:@"?"];        
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
    } else if (AboutViewRowCopyrigth == indexPath.row) {        
        
        cell = [self mkCell:@"TextCell" withStyle:UITableViewCellStyleSubtitle];
        cell.textLabel.text = [dict get:@"NSHumanReadableCopyright" orElse:@"?"]; 
        cell.detailTextLabel.text = @"Copyright (c) 2012";
        
    } else if (AboutViewRowTwitter == indexPath.row) {        

        BOOL canSendTweet = [TWTweetComposeViewController canSendTweet];
        
        cell = [self mkCell:@"LinkCell" withStyle:UITableViewCellStyleDefault];
        cell.textLabel.text = locString(@"Twit feedback");   
        if (canSendTweet) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;        
            cell.textLabel.textColor = [UIColor darkTextColor];
            
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;        
            cell.textLabel.textColor = [UIColor grayColor];            
        }
        
    } else if (AboutViewRowEmail == indexPath.row) {        
        
        cell = [self mkCell:@"LinkCell" withStyle:UITableViewCellStyleDefault];
        cell.textLabel.text = locString(@"Mail feedback");   
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
     
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *dict = [[NSBundle mainBundle] infoDictionary];
    
    if (AboutViewRowLink == indexPath.row) {
        
        [self openUrl: KxUtils.format(@"http://%@", [dict get:@"SamLibAboutSite" orElse:@"?"])];
        
    } else if (AboutViewRowTwitter == indexPath.row) {
        
        [self tweetFeedback];
        
    } else if (AboutViewRowEmail == indexPath.row) {        

        [self openUrl: KxUtils.format(@"mailto:%@?subject=iSamizdat", [dict get:@"SamLibAboutEmail" orElse:@"?"])];
    }

    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];    
}

@end
