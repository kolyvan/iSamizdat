//
//  FavoritesViewController.m
//  iSamizdat
//
//  Created by Kolyvan on 17.07.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//

#import "FavoritesViewController.h"
#import "KxMacros.h"
#import "KxUtils.h"
#import "NSArray+Kolyvan.h"
#import "SamLibModel.h"
#import "SamLibAuthor.h"
#import "SamLibText.h"

@interface FavoritesViewController ()

@end

@implementation FavoritesViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.title = locString(@"Favorites");        
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:locString(@"Favorites")
                                                        image:[UIImage imageNamed:@"favorites"] 
                                                          tag:0];
    }
    return self;
}

- (NSArray *) prepareData
{
    NSArray *authors = [SamLibModel shared].authors;
    
    NSMutableArray *ma = [NSMutableArray array];
    
    for (SamLibAuthor *author in authors) {
        if (!author.ignored) {
            for (SamLibText *text in author.texts) {            
                if (text.favorited)
                    [ma push:text];
            }
        }
    }
    
    return ma;
}

- (BOOL) canRemoveText: (SamLibText *) text
{
    return YES;
}

- (void) handleRemoveText: (SamLibText *) text
{
    text.favorited = NO;            
}

@end
