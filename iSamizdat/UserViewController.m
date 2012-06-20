//
//  UserViewController.m
//  iSamizdat
//
//  Created by Kolyvan on 04.06.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//
//  https://github.com/kolyvan/iSamizdat
//  this file is part of iSamizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt
// 

#import "UserViewController.h"
#import "KxMacros.h"
#import "NSString+Kolyvan.h"
#import "NSDictionary+Kolyvan.h"
#import "SamLibUser.h"
#import "SamLibAgent.h"
#import "AppDelegate.h"
#import "UIFont+Kolyvan.h"
#import "UIColor+Kolyvan.h"

#define USER_SECTION 0
#define ACCOUNT_SECTION 1
#define NAME_ROW 0
#define URL_ROW 1
#define EMAIL_ROW 2
#define LOGIN_ROW 0
#define PASSWORD_ROW 1
#define ENABLE_ROW 2 

////

@interface UserViewController () {
}

@end

@implementation UserViewController

@synthesize delegate;

- (id) init
{
    self = [self initWithNibName:@"UserViewController" bundle:nil];
    if (self) {
        self.title = locString(@"User info");
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave 
                                                                                target:self 
                                                                                action:@selector(goSave)];
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back.png"]
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(goBack)];

    //saveButton.enabled = NO;
    self.navigationItem.rightBarButtonItem = saveButton;
    self.navigationItem.leftBarButtonItem = backButton;    
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];    
    [self.tableView reloadData];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.navigationItem.rightBarButtonItem = nil;
    self.navigationItem.leftBarButtonItem = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (IBAction) textFieldDoneEditing: (id) sender
{
    [sender resignFirstResponder];
    
    //self.navigationItem.rightBarButtonItem.enabled = YES;
}

- (void) goSave
{
    SamLibUser *user = [SamLibUser currentUser];
    
    NSString *name = [self textForRow:NAME_ROW inSection:USER_SECTION];
    NSString *url = [self textForRow:URL_ROW inSection:USER_SECTION];    
    NSString *email = [self textForRow:EMAIL_ROW inSection:USER_SECTION];            
    NSString *login = [self textForRow:LOGIN_ROW inSection:ACCOUNT_SECTION];            
    NSString *pass = [self textForRow:PASSWORD_ROW inSection:ACCOUNT_SECTION];

    BOOL changed = NO;

    if (![name isEqualToString:user.name]) {
        user.name = name;
        changed = YES;
    }

    if (![url isEqualToString:user.url]) {
        user.url = url;
        changed = YES;
    }

    if (![email isEqualToString:user.email]) {
        user.email = email;
        changed = YES;
    }
    
    if (![login isEqualToString:user.login]) {
        user.login = login;
        changed = YES;
    }
    
    if (user.login.nonEmpty &&
        ![pass isEqualToString:user.pass]) {
        user.pass = pass;
        changed = YES;
    }
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:ENABLE_ROW inSection: ACCOUNT_SECTION];
    UITableViewCell * cell = [self.tableView cellForRowAtIndexPath:indexPath];
    BOOL on = ((UISwitch *)cell.accessoryView).on;  
    
    BOOL enableAccount = SamLibAgent.settingsBool(@"user.enableAccount", NO);
    if (on != enableAccount) {
        
        SamLibAgent.setSettingsBool(@"user.enableAccount", on, NO); 
        changed = YES;  
    }
    
    BOOL dismiss = YES;
    
    if (self.delegate && changed) {
        dismiss = [delegate userInfoChanged];
    }

    if (dismiss)
        [self dismissViewControllerAnimated:YES 
                                 completion:NULL];

    
    if (changed) {
        
        [[AppDelegate shared] checkLogin];
    }
}

- (void) goBack
{
    [self dismissViewControllerAnimated:YES 
                             completion:NULL];
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView 
heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView 
titleForHeaderInSection:(NSInteger)section
{
    if (section == USER_SECTION)
        return locString(@"Post comment as");
    return locString(@"Samizdat account"); 
}


- (UITableViewCell *) mkTextCell
{
    static NSString *CellIdentifier = @"TextCell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                       reuseIdentifier:CellIdentifier];
    }    
    
    UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 180, 21)];
    textField.font = [UIFont systemFont14];         
    textField.autocapitalizationType = NO;
    textField.autocorrectionType = NO;       
    textField.textColor = [UIColor secondaryTextColor];
           
    [textField addTarget:self 
                  action:@selector(textFieldDoneEditing:) 
        forControlEvents:UIControlEventEditingDidEndOnExit];    
   
    cell.accessoryView = textField;
    
    return cell;
}

- (UITableViewCell *) mkSwitchCell
{
    static NSString *CellIdentifier = @"SwitchCell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                      reuseIdentifier:CellIdentifier];
    }    
    
    UISwitch * button = [[UISwitch alloc] initWithFrame:CGRectZero]; 
    cell.accessoryView = button;
    
    return cell;
}

- (NSString *) textForRow: (NSInteger ) row inSection: (NSInteger) section
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection: section];
    UITableViewCell * cell = [self.tableView cellForRowAtIndexPath:indexPath];
    UITextField *textField = (UITextField *)cell.accessoryView;
    return textField.text;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SamLibUser *user = [SamLibUser currentUser];
    
    if (indexPath.section == ACCOUNT_SECTION &&
        indexPath.row == ENABLE_ROW) {
        
        UITableViewCell *cell = [self mkSwitchCell];        
        cell.textLabel.text = locString(@"Enable");
        BOOL f = SamLibAgent.settingsBool(@"user.enableAccount", NO);
        ((UISwitch *)cell.accessoryView).on = f;        
        return cell;
    }
    
    UITableViewCell *cell = [self mkTextCell];
    UITextField *textField = (UITextField *)cell.accessoryView;
    
    if (indexPath.section == USER_SECTION) {
        
        switch (indexPath.row) {
            case NAME_ROW:                
                cell.textLabel.text = locString(@"Name");
                textField.placeholder = locString(@"required");
                textField.keyboardType = UIKeyboardTypeDefault;
                textField.text = user.name.nonEmpty ? user.name : @"";
                break;
                
            case URL_ROW:                
                cell.textLabel.text = locString(@"URL");                
                textField.placeholder = locString(@"optional");
                textField.keyboardType = UIKeyboardTypeURL;
                textField.text = user.url.nonEmpty ? user.url : @"";
                break;
                
            case EMAIL_ROW:                
                cell.textLabel.text = locString(@"Email");
                textField.placeholder = locString(@"optional");
                textField.keyboardType = UIKeyboardTypeEmailAddress;                
                textField.text = user.email.nonEmpty ? user.email : @"";                
                break;
        }
        
        textField.secureTextEntry = NO;
        
    } else {
        
        switch (indexPath.row) {
            case LOGIN_ROW:                
                cell.textLabel.text = locString(@"Login");
                textField.secureTextEntry = NO;                
                textField.keyboardType = UIKeyboardTypeASCIICapable;  
                textField.text = user.login.nonEmpty ? user.login : @"";                
                break;
                
            case PASSWORD_ROW:
                cell.textLabel.text = locString(@"Password");
                textField.secureTextEntry = YES;
                textField.keyboardType = UIKeyboardTypeASCIICapable;                
                textField.text = (user.login.nonEmpty && user.pass.nonEmpty) ? user.pass : @"";                
                break;
                
            case ENABLE_ROW:
                break;
        }
        
        textField.placeholder = @"";
    }
    
    return cell;
}

#pragma mark - Table view delegate

@end
