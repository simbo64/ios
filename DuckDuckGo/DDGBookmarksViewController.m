//
//  DDGBookmarksViewController.m
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 7/29/12.
//
//

#import "DDGBookmarksViewController.h"
#import "DDGBookmarksProvider.h"
#import "DDGSearchController.h"
#import "DDGUnderViewController.h"
#import "DDGPlusButton.h"
#import "DDGMenuHistoryItemCell.h"
#import "DDGMenuSectionHeaderView.h"

@interface DDGBookmarksViewController ()
@property (nonatomic, strong) UIBarButtonItem *editBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *doneBarButtonItem;
@property (nonatomic, strong) UIImage *searchIcon;

@property (nonatomic, weak) IBOutlet UIImageView *largeIconImageView;
@property (nonatomic, weak) IBOutlet UIImageView *smallIconImageView;

@end

@implementation DDGBookmarksViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Bookmarks", @"View controller title: Bookmarks");
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view setBackgroundColor:[UIColor duckNoContentColor]];
    
    [self.largeIconImageView setTintColor:[UIColor whiteColor]];
    [self.largeIconImageView setImage:[[UIImage imageNamed:@"NoFavorites"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    
    [self.smallIconImageView setTintColor:RGBA(245.0f, 203.0f, 196.0f, 1.0f)];
    [self.smallIconImageView setImage:[[UIImage imageNamed:@"inline_actions-icon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    
    NSParameterAssert(nil != self.searchController);
    
    [self.tableView registerNib:[UINib nibWithNibName:@"DDGMenuHistoryItemCell" bundle:nil] forCellReuseIdentifier:@"DDGMenuHistoryItemCell"];
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    [self.tableView setOpaque:NO];
    [self.tableView setRowHeight:44.0f];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    self.tableView.frame = self.view.bounds;
    [self.view addSubview:self.tableView];    
    
    self.searchIcon = [UIImage imageNamed:@"search_icon"];
            
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[UIImage imageNamed:@"button_menu-default"] forState:UIControlStateNormal];
    [button setImage:[UIImage imageNamed:@"button_menu-onclick"] forState:UIControlStateHighlighted];
    
    // we need to offset the triforce image by 1px down to compensate for the shadow in the image
    float topInset = 1.0f;
    button.imageEdgeInsets = UIEdgeInsetsMake(topInset, 0.0f, -topInset, 0.0f);

    [button addTarget:self action:@selector(leftButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];

    self.doneBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", @"Menu button label: Done")
                                                              style:UIBarButtonItemStyleBordered
                                                             target:self
                                                             action:@selector(editAction:)];

    self.editBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Edit", @"Menu button label: Edit")
                                                              style:UIBarButtonItemStyleBordered
                                                             target:self
                                                             action:@selector(editAction:)];    
	// force 1st time through for iOS < 6.0
	[self viewWillLayoutSubviews];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    
    UIGestureRecognizer *panGesture = [self.slideOverMenuController panGesture];
    for (UIGestureRecognizer *gr in self.tableView.gestureRecognizers) {
        if ([gr isKindOfClass:[UISwipeGestureRecognizer class]])
            [panGesture requireGestureRecognizerToFail:gr];
    }
    
    self.navigationItem.rightBarButtonItem = ([DDGBookmarksProvider sharedProvider].bookmarks.count)  ? self.editBarButtonItem : nil;
    
    if ([DDGBookmarksProvider sharedProvider].bookmarks.count == 0)
        [self showNoBookmarksView];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.tableView setEditing:NO animated:animated];
}

#pragma mark - Rotation

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    NSArray *indexPaths = [self.tableView indexPathsForVisibleRows];
    [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)viewWillLayoutSubviews
{
	CGPoint cl = self.navigationItem.leftBarButtonItem.customView.center;
//	CGPoint cr = self.navigationItem.rightBarButtonItem.customView.center;
	if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation) && ([[UIDevice currentDevice] userInterfaceIdiom]==UIUserInterfaceIdiomPhone))
	{
		self.navigationItem.leftBarButtonItem.customView.frame = CGRectMake(0, 0, 26, 21);
//		self.navigationItem.rightBarButtonItem.customView.frame = CGRectMake(0, 0, 40, 23);
	}
	else
	{
		self.navigationItem.leftBarButtonItem.customView.frame = CGRectMake(0, 0, 38, 31);
//		self.navigationItem.rightBarButtonItem.customView.frame = CGRectMake(0, 0, 58, 33);
	}
	self.navigationItem.leftBarButtonItem.customView.center = cl;
//	self.navigationItem.rightBarButtonItem.customView.center = cr;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)editAction:(UIBarButtonItem *)buttonItem
{
	BOOL edit = (buttonItem == self.editBarButtonItem);
	[self.tableView setEditing:edit animated:YES];
    [self.navigationItem setRightBarButtonItem:(edit ? self.doneBarButtonItem : self.editBarButtonItem) animated:NO];
}

-(void)leftButtonPressed
{
    [self.slideOverMenuController showMenu];
}

- (void)reenableScrollsToTop {
    self.tableView.scrollsToTop = YES;
}

#pragma mark - No Bookmarks

- (void)showNoBookmarksView {
    
    [UIView animateWithDuration:0 animations:^{
        [self.tableView removeFromSuperview];
        self.noBookmarksView.frame = self.view.bounds;
        [self.view addSubview:self.noBookmarksView];
    }];
}

- (void)hideNoBookmarksView {
    if (nil == self.tableView.superview) {
        [UIView animateWithDuration:0 animations:^{
            [self.noBookmarksView removeFromSuperview];
            self.tableView.frame = self.view.bounds;
            [self.view addSubview:self.tableView];
        }];
    }
}

- (IBAction)delete:(id)sender {
    NSSet *indexPaths = [self.deletingIndexPaths copy];
    [self cancelDeletingIndexPathsAnimated:YES];
    
    for (NSIndexPath *indexPath in indexPaths) {
        [[DDGBookmarksProvider sharedProvider] deleteBookmarkAtIndex:indexPath.row];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        if ([DDGBookmarksProvider sharedProvider].bookmarks.count == 0)
            [self performSelector:@selector(showNoBookmarksView) withObject:nil afterDelay:0.2];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSInteger count = [DDGBookmarksProvider sharedProvider].bookmarks.count;
	((UIButton*)self.navigationItem.rightBarButtonItem.customView).hidden = !count;
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *bookmark = [[[DDGBookmarksProvider sharedProvider] bookmarks] objectAtIndex:indexPath.row];
    DDGMenuHistoryItemCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DDGMenuHistoryItemCell"];
    cell.auxiliaryViewHidden = NO;
    cell.content = bookmark[@"title"];
    __weak typeof(self) weakSelf = self;
    [cell setDeleteBlock:^(id sender) {
        [weakSelf delete:sender];
    }];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 50.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UINib *nib = [UINib nibWithNibName:@"DDGMenuSectionHeaderView" bundle:nil];
    DDGMenuSectionHeaderView *sectionHeaderView = (DDGMenuSectionHeaderView *)[nib instantiateWithOwner:nil options:nil][0];
    sectionHeaderView.title = @"Favorites";
    return sectionHeaderView;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *bookmark = [[DDGBookmarksProvider sharedProvider].bookmarks objectAtIndex:indexPath.row];
    [self.searchHandler loadQueryOrURL:[bookmark objectForKey:@"url"]];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
