//
//  DDGNewsSourcesViewController.m
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 7/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DDGNewsSourcesViewController.h"
#import "DDGStoriesProvider.h"
#import "DDGCache.h"
#import "UIImageView+AFNetworking.h"

@implementation DDGNewsSourcesViewController

#pragma mark - View controller methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"News Sources";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd 
                                                                                           target:self 
                                                                                           action:@selector(addButtonPressed)];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return IPAD || (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - Adding custom news sources

-(void)addButtonPressed {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Add Custom News Source" 
                                                    message:@"Enter a keyword to see related news topics" 
                                                   delegate:self 
                                          cancelButtonTitle:@"Cancel" 
                                          otherButtonTitles:@"OK", nil];
    [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [alert show];
}

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section==0)
        return 0;
    else // section==1
        return [[DDGStoriesProvider sharedProvider] sources].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if(!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.imageView.contentMode = UIViewContentModeScaleAspectFill;
        cell.indentationLevel = 1;
        cell.indentationWidth = 10;
    }
    
    NSDictionary *source = [[[DDGStoriesProvider sharedProvider] sources] objectAtIndex:indexPath.row];
    
    cell.textLabel.text = [source objectForKey:@"title"];
    cell.detailTextLabel.text = [source objectForKey:@"description"];
    cell.imageView.image = [UIImage imageWithData:[DDGCache objectForKey:[source objectForKey:@"image"] inCache:@"sourceImages"]];
    
    if([[source objectForKey:@"enabled"] boolValue])
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *source = [[[DDGStoriesProvider sharedProvider] sources] objectAtIndex:indexPath.row];

    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if(cell.accessoryType == UITableViewCellAccessoryCheckmark) {
        cell.accessoryType = UITableViewCellAccessoryNone;
        [[DDGStoriesProvider sharedProvider] setSourceWithID:[source objectForKey:@"id"] enabled:NO];
    } else {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        [[DDGStoriesProvider sharedProvider] setSourceWithID:[source objectForKey:@"id"] enabled:YES];
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end