//
//  SHKDropbox.m
//  iSamizdat
//
//  Created by Kolyvan on 17.07.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//

#import "SHKDropbox.h"
#import <DropboxSDK/DropboxSDK.h>
#import "DropboxService.h"
#import "SamLibStorage.h"
#import "KxUtils.h"
#import "NSString+Kolyvan.h"

@implementation SHKDropbox

#pragma mark -
#pragma mark Configuration : Service Defination

// Enter the name of the action
+ (NSString *)sharerTitle
{
	return @"Dropbox";
}

+ (BOOL)canShareURL
{
	return YES;
}

+ (BOOL)canShareFile
{
	return YES;
}

+ (BOOL)shareRequiresInternetConnection
{
	return YES;
}

+ (BOOL)requiresAuthentication
{
	return NO;
}


#pragma mark -
#pragma mark Configuration : Dynamic Enable

+ (BOOL)canShare
{
	return [[DropboxService shared] isLinked];
}

#pragma mark -
#pragma mark Implementation

// When an attempt is made to share the item, verify that it has everything it needs, otherwise display the share form

- (BOOL)validateItem
{ 
	// The super class will verify that:
	// -if sharing a url	: item.url != nil
	// -if sharing an image : item.image != nil
	// -if sharing text		: item.text != nil
	// -if sharing a file	: item.data != nil
 
	// You only need to implement this if you need to check additional variables.
 
    if (!item.filename)
        return NO;
    
	return [super validateItem];
}

// Performs the action
- (BOOL)send
{	
	// Make sure that the item has minimum requirements
	if (![self validateItem])
		return NO;
	
	// Implement your action here
	
	// If the action is asynchronous and will not be completed by the time send returns
	// call [self sendDidStart] after you start your action
	// then after the action completes, fails or is cancelled, call one of these on 'self':
	// - (void)sendDidFinish (if successful)
	// - (void)sendDidFailShouldRelogin (if failed because the user's current credentials are out of date)
	// - (void)sendDidFailWithError:(NSError *)error shouldRelogin:(BOOL)shouldRelogin
	// - (void)sendDidCancel
       
    NSString *localFolder;
    NSString *remoteFolder;        
    NSString *filename;
        
    if ([item.filename contains:@"/"]) {
        
        NSArray *a = [item.filename split:@"/"];
        if (a.count != 2)
            return NO;
        
        NSString *author = [a objectAtIndex:0];
        
        filename = KxUtils.format(@"%@.html", [a objectAtIndex:1]);        
        remoteFolder = KxUtils.format(@"/texts/%@", author);
        localFolder = KxUtils.format(@"/%@/%@", SamLibStorage.textsPath(), author); 

    } else {
    
        filename = item.filename;
        remoteFolder = @"/authors";
        localFolder = SamLibStorage.authorsPath();        
    }
    
    [self sendDidStart];
    
    [[DropboxService shared] sync:filename 
                            local:localFolder
                           remote:remoteFolder
                       completion:^(id<DropboxTask> task, NSError *error) {
                           
                           if (error) {
                               
                               [self sendDidFailWithError:error shouldRelogin:NO];                           
                               
                           } else if (task.mode == DropboxTaskModeCanceled) {
                               
                               [self sendDidCancel];
                               
                           } else  {  
                               
                               [self sendDidFinish];
                               
                               // todo: refresh text info
                           }
                       }];
    
    	
	return YES; // return YES if the action has started or completed
}


@end
