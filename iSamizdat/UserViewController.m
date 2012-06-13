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

#define USER_SECTION 0
#define ACCOUNT_SECTION 1
#define NAME_ROW 0
#define URL_ROW 1
#define EMAIL_ROW 2
#define LOGIN_ROW 0
#define PASSWORD_ROW 1
#define ENABLE_ROW 2 

@interface UserViewTextCell : UITableViewCell 
@property (readonly, nonatomic) UILabel * nameLabel;
@property (readonly, nonatomic) UITextField * textField;
@end

@implementation UserViewTextCell
@synthesize nameLabel = _nameLabel;
@synthesize textField = _textField;

- (id) initWithStyle:(UITableViewCellStyle)style 
     reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) 
    {
        _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 10, 85, 21)];
        _nameLabel.font = [UIFont boldSystemFontOfSize:15];        
        [self.contentView addSubview:_nameLabel];
        
        _textField = [[UITextField alloc] initWithFrame:CGRectMake(105, 10, 180, 31)];
        _textField.font = [UIFont systemFontOfSize:15];         
        _textField.autocapitalizationType = NO;
        _textField.autocorrectionType = NO;       
        _textField.textColor = [UIColor colorWithRed:0 green:51.0/255 blue:102.0/255 alpha:1];
        [self.contentView addSubview:_textField];
    }
    return self;
}

@end


@interface UserViewSwitchCell : UITableViewCell
@property (readonly, nonatomic) UILabel * nameLabel;
@property (readonly, nonatomic) UISwitch * switchButton;
@end

@implementation UserViewSwitchCell
@synthesize nameLabel = _nameLabel;
@synthesize switchButton = _switchButton;

- (id) initWithStyle:(UITableViewCellStyle)style 
     reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) 
    {   
        _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 10, 85, 21)];
        _nameLabel.font = [UIFont boldSystemFontOfSize:14];        
        [self.contentView addSubview:_nameLabel];
        
        _switchButton = [[UISwitch alloc] initWithFrame:CGRectMake(210, 8, 60, 26)];
        [self.contentView addSubview:_switchButton];        
    }
    return self;
}

@end

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
    UserViewSwitchCell * cell = (UserViewSwitchCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    
    BOOL enableAccount = [[SamLibAgent.settings() get: @"user.enableAccount"] boolValue];
    if (cell.switchButton.on != enableAccount) {
        
        [SamLibAgent.settings() update: @"user.enableAccount" 
                                 value: [NSNumber numberWithBool:cell.switchButton.on]];   
        changed = YES;        
    }

    BOOL dismiss = YES;
    
    if (self.delegate && changed) {
        dismiss = [delegate userInfoChanged];
    }

    if (dismiss)
        [self dismissViewControllerAnimated:YES 
                                 completion:NULL];
    
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

- (UserViewTextCell *) mkTextCell
{
    static NSString *CellIdentifier = @"TextCell";
    UserViewTextCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UserViewTextCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }    
    [cell.textField addTarget:self 
                       action:@selector(textFieldDoneEditing:) 
             forControlEvents:UIControlEventEditingDidEndOnExit];    
    return cell;
}

- (UserViewSwitchCell *) mkSwitchCell
{
    static NSString *CellIdentifier = @"SwitchCell";
    UserViewSwitchCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UserViewSwitchCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }    
    //[cell.button addTarget:self 
    //                action:@selector(textFieldDoneEditing:) 
    //         forControlEvents:UIControlEventTouchUpInside];    
    return cell;
}

- (NSString *) textForRow: (NSInteger ) row inSection: (NSInteger) section
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection: section];
    UserViewTextCell * cell = (UserViewTextCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    return cell.textField.text;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SamLibUser *user = [SamLibUser currentUser];
    
    if (indexPath.section == ACCOUNT_SECTION &&
        indexPath.row == ENABLE_ROW) {
        
        UserViewSwitchCell *cell = [self mkSwitchCell];        
        cell.nameLabel.text = locString(@"Enable");
        BOOL f = [[SamLibAgent.settings() get: @"user.enableAccount"] boolValue];
        cell.switchButton.on = f;
        return cell;
    }
    
    UserViewTextCell *cell = [self mkTextCell];
    
    if (indexPath.section == USER_SECTION) {
        
        switch (indexPath.row) {
            case NAME_ROW:                
                cell.nameLabel.text = locString(@"Name");
                cell.textField.placeholder = locString(@"required");
                cell.textField.keyboardType = UIKeyboardTypeDefault;
                cell.textField.text = user.name.nonEmpty ? user.name : @"";
                break;
                
            case URL_ROW:                
                cell.nameLabel.text = locString(@"URL");                
                cell.textField.placeholder = locString(@"optional");
                cell.textField.keyboardType = UIKeyboardTypeURL;
                cell.textField.text = user.url.nonEmpty ? user.url : @"";
                break;
                
            case EMAIL_ROW:                
                cell.nameLabel.text = locString(@"Email");
                cell.textField.placeholder = locString(@"optional");
                cell.textField.keyboardType = UIKeyboardTypeEmailAddress;                
                cell.textField.text = user.email.nonEmpty ? user.email : @"";                
                break;
        }
        
        cell.textField.secureTextEntry = NO;
        
    } else {
        
        switch (indexPath.row) {
            case LOGIN_ROW:                
                cell.nameLabel.text = locString(@"Login");
                cell.textField.secureTextEntry = NO;                
                cell.textField.keyboardType = UIKeyboardTypeASCIICapable;  
                cell.textField.text = user.login.nonEmpty ? user.login : @"";                
                break;
                
            case PASSWORD_ROW:
                cell.nameLabel.text = locString(@"Password");
                cell.textField.secureTextEntry = YES;
                cell.textField.keyboardType = UIKeyboardTypeASCIICapable;                
                cell.textField.text = (user.login.nonEmpty && user.pass.nonEmpty) ? user.pass : @"";                
                break;
                
            case ENABLE_ROW:
                break;
                
        }
        
        cell.textField.placeholder = @"";
    }
    
    return cell;
}

#pragma mark - Table view delegate

@end
