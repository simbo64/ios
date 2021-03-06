//
//  DDGHistoryViewController.m
//  DuckDuckGo
//
//  Created by Johnnie Walker on 10/04/2013.
//
//

#import "DDGHistoryViewController.h"
#import "DDGHistoryItem.h"
#import "DDGPlusButton.h"
#import "DDGStoryFeed.h"
#import "DDGStory.h"
#import "DDGSettingsViewController.h"
#import "DDGSearchController.h"
#import "DDGHistoryItemCell.h"

#import "DDGMenuHistoryItemCell.h"
#import "DDGMenuSectionHeaderView.h"


@interface DDGHistoryViewController () <UIGestureRecognizerDelegate> {
    BOOL _showingNoResultsSection;
}
@property (nonatomic, weak, readwrite) id <DDGSearchHandler> searchHandler;
@property (nonatomic, strong, readwrite) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSMutableSet *deletingIndexPaths;
@property (nonatomic) DDGHistoryViewControllerMode mode;
@property (nonatomic, weak) IBOutlet UIImageView *chatBubbleImageView;
@end

@implementation DDGHistoryViewController

-(id)initWithSearchHandler:(id <DDGSearchHandler>)searchHandler managedObjectContext:(NSManagedObjectContext *)managedObjectContext mode:(DDGHistoryViewControllerMode)mode;
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.managedObjectContext = managedObjectContext;
        self.searchHandler = searchHandler;
        self.deletingIndexPaths = [NSMutableSet set];
        self.overhangWidth = 6.0;
        self.showsHistory = YES;
        self.mode = mode;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (nil == self.tableView) {
        UITableView *tableView = nil;
        tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
        
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        
        tableView.backgroundColor = [UIColor clearColor];
        tableView.opaque = NO;
        tableView.rowHeight = 44.0;
        [tableView registerNib:[UINib nibWithNibName:@"DDGMenuHistoryItemCell" bundle:nil] forCellReuseIdentifier:@"DDGMenuHistoryItemCell"];
        
        [self.view addSubview:tableView];
        self.tableView = tableView;
    }
    
    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeft:)];
    swipeLeft.direction = (UISwipeGestureRecognizerDirectionLeft);
    swipeLeft.delegate = self;
    
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight:)];
    swipeRight.direction = (UISwipeGestureRecognizerDirectionRight);
    swipeRight.delegate = self;
    
    [self.tableView addGestureRecognizer:swipeLeft];
    [self.tableView addGestureRecognizer:swipeRight];    
        
    [self fetchedResultsController];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self.tableView reloadRowsAtIndexPaths:[self.tableView indexPathsForVisibleRows] withRowAnimation:UITableViewRowAnimationAutomatic];
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

- (void)reenableScrollsToTop {
    self.tableView.scrollsToTop = YES;
}

- (void)cancelDeletingIndexPathsAnimated:(BOOL)animated
{
    for (NSIndexPath *indexPath in self.deletingIndexPaths) {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        [(DDGMenuHistoryItemCell *)cell setDeletable:NO animated:animated];
    }
    [self.deletingIndexPaths removeAllObjects];
}

- (void)swipeLeft:(UISwipeGestureRecognizer *)swipe
{
    [self swipe:swipe direction:UISwipeGestureRecognizerDirectionLeft];
}

- (void)swipeRight:(UISwipeGestureRecognizer *)swipe
{
    [self swipe:swipe direction:UISwipeGestureRecognizerDirectionRight];
}

- (void)swipe:(UISwipeGestureRecognizer *)swipe direction:(UISwipeGestureRecognizerDirection)direction {
    if (swipe.state == UIGestureRecognizerStateEnded) {
        CGPoint point = [swipe locationInView:self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
        
        // Workaround for the bug mentioned in http://openradar.io/13187897
        if (indexPath) {
            CGRect rect = [self.tableView rectForHeaderInSection:indexPath.section];
            if (CGRectContainsPoint(rect, point)) {
                return;
            }
        }
        
        NSInteger additionalSections = [self.additionalSectionsDelegate numberOfAdditionalSections];

        if (indexPath.section < additionalSections)
            return;

        if (indexPath.section == additionalSections + [[self.fetchedResultsController sections] count])
            return;
        
        if (nil != indexPath) {
            [self.deletingIndexPaths removeObject:indexPath];
            
            [self cancelDeletingIndexPathsAnimated:YES];
            
            BOOL deleting = (direction == UISwipeGestureRecognizerDirectionLeft);
            
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            [(DDGMenuHistoryItemCell *)cell setDeletable:deleting animated:YES];

            if (deleting)
                [self.deletingIndexPaths addObject:indexPath];            
        }
    }
}

- (NSInteger)historySectionForTableSection:(NSInteger)section {
    return section - [self.additionalSectionsDelegate numberOfAdditionalSections];
}

- (NSInteger)tableSectionForHistorySection:(NSInteger)section {
    return section + [self.additionalSectionsDelegate numberOfAdditionalSections];
}

- (NSIndexPath *)historyIndexPathForTableIndexPath:(NSIndexPath *)indexPath {
    return [NSIndexPath indexPathForRow:indexPath.row inSection:[self historySectionForTableSection:indexPath.section]];
}

- (NSIndexPath *)tableIndexPathForHistoryIndexPath:(NSIndexPath *)indexPath {
    return [NSIndexPath indexPathForRow:indexPath.row inSection:[self tableSectionForHistorySection:indexPath.section]];
}

- (IBAction)delete:(id)sender {
    NSSet *indexPaths = [self.deletingIndexPaths copy];
    [self cancelDeletingIndexPathsAnimated:YES];
    
    for (NSIndexPath *indexPath in indexPaths) {
        NSIndexPath *historyIndexPath = [self historyIndexPathForTableIndexPath:indexPath];
        DDGHistoryItem *historyItem = [self.fetchedResultsController objectAtIndexPath:historyIndexPath];
        [historyItem.managedObjectContext deleteObject:historyItem];
    }
}

- (NSFetchedResultsController *)fetchedResultsController {
    if (nil == _fetchedResultsController && self.showsHistory) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[DDGHistoryItem entityName]];
        NSSortDescriptor *timeSort = [NSSortDescriptor sortDescriptorWithKey:@"timeStamp" ascending:NO];
        NSSortDescriptor *sectionSort = [NSSortDescriptor sortDescriptorWithKey:@"section" ascending:YES];
        [request setSortDescriptors:@[sectionSort, timeSort]];
        
        NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                                                   managedObjectContext:self.managedObjectContext
                                                                                                     sectionNameKeyPath:@"section"
                                                                                                              cacheName:nil];
        fetchedResultsController.delegate = self;
        
        NSError *error = nil;
        if (![fetchedResultsController performFetch:&error])
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        
        self.fetchedResultsController = fetchedResultsController;
    }
    
    return _fetchedResultsController;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

    if (nil == self.view) {
        self.fetchedResultsController = nil;
    }
}

- (UIImage *)searchControllerBackButtonIconDDG {
    return [[UIImage imageNamed:@"Home"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

- (IBAction)plus:(id)sender {
    UIButton *button = nil;
    if ([sender isKindOfClass:[UIButton class]])
        button = (UIButton *)sender;
    
    if (button) {
        CGPoint tappedPoint = [self.tableView convertPoint:button.center fromView:button.superview];
        NSIndexPath *tappedIndex = [self.tableView indexPathForRowAtPoint:tappedPoint];
        NSIndexPath *historyIndexPath = [self historyIndexPathForTableIndexPath:tappedIndex];
        DDGHistoryItem *historyItem = [self.fetchedResultsController objectAtIndexPath:historyIndexPath];
        DDGSearchController *searchController = [self searchControllerDDG];
        if (searchController) {
            DDGAddressBarTextField *searchField = searchController.searchBar.searchField;
            [searchField becomeFirstResponder];
            searchField.text = historyItem.title;
            [searchController searchFieldDidChange:nil];            
        } else if ([self.searchHandler respondsToSelector:@selector(beginSearchInputWithString:)]) {
            [self.searchHandler beginSearchInputWithString:historyItem.title];
        }
    }
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
    
    if ([self shouldShowNoHistoryView]) {
        [self showNoResultsView];
    } else {
        [self.noResultsView removeFromSuperview];
        self.noResultsView = nil;
    }
    
    if ([self shouldShowNoHistorySection]) {
        [self showNoResultsSection];
    }
}

- (BOOL)shouldShowNoHistorySection {
    return ([[self.fetchedResultsController fetchedObjects] count] == 0)
    && nil != self.additionalSectionsDelegate
    && self.showsHistory;
}

- (void)showNoResultsSection {
    if (!_showingNoResultsSection) {
        _showingNoResultsSection = YES;
        [self.tableView beginUpdates];
        
        NSInteger additionalSections = [self.additionalSectionsDelegate numberOfAdditionalSections];
        NSInteger sections = [[self.fetchedResultsController sections] count];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:(sections + additionalSections)];
        
        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        [self.tableView endUpdates];
    }
}

- (void)hideNoResultsSection {
    if (_showingNoResultsSection) {
        _showingNoResultsSection = NO;
        [self.tableView beginUpdates];
        
        NSInteger additionalSections = [self.additionalSectionsDelegate numberOfAdditionalSections];
        NSInteger sections = [[self.fetchedResultsController sections] count];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:(sections + additionalSections)];
        
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
        
        [self.tableView endUpdates];        
    }
}

- (BOOL)shouldShowNoHistoryView {
    return ([[self.fetchedResultsController fetchedObjects] count] == 0)
    && nil == self.additionalSectionsDelegate
    && self.showsHistory;
}

- (void)showNoResultsView {
    if (nil == self.additionalSectionsDelegate) {
        // show no results view
        if (nil == self.noResultsView) {
            if ([[NSUserDefaults standardUserDefaults] boolForKey:DDGSettingRecordHistory])
                [[NSBundle mainBundle] loadNibNamed:@"DDGHistoryNoResultsView" owner:self options:nil];
            else
                [[NSBundle mainBundle] loadNibNamed:@"DDGHistoryNoResultsDisabledView" owner:self options:nil];
        }
        [self.noResultsView setTintColor:[UIColor whiteColor]];
        [self.chatBubbleImageView setImage:[[UIImage imageNamed:@"Chat"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        [self.noResultsView setFrame:[self.view bounds]];
        [self.view addSubview:self.noResultsView];
        
    } else {
        // show an extra cell
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    UIGestureRecognizer *panGesture = [self.slideOverMenuController panGesture];
    for (UIGestureRecognizer *gr in self.tableView.gestureRecognizers) {
        if ([gr isKindOfClass:[UISwipeGestureRecognizer class]])
            [panGesture requireGestureRecognizerToFail:gr];
    }
}

- (void)setShowsHistory:(BOOL)showsHistory {
    if (showsHistory == _showsHistory)
        return;
    
    _showsHistory = showsHistory;
    
    if (!showsHistory)
        self.fetchedResultsController = nil;
    
    [self.tableView reloadData];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    CGPoint point = [gestureRecognizer locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
    return (nil != indexPath);
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self cancelDeletingIndexPathsAnimated:YES];
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
    [self cancelDeletingIndexPathsAnimated:YES];
}

#pragma mark - UITableViewDelegate

- (NSIndexPath*)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger additionalSections = [self.additionalSectionsDelegate numberOfAdditionalSections];
    if (indexPath.section < additionalSections) {
        if ([self.additionalSectionsDelegate respondsToSelector:@selector(tableView:willSelectRowAtIndexPath:)])
            return [self.additionalSectionsDelegate tableView:tableView willSelectRowAtIndexPath:indexPath];
    }
    
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger additionalSections = [self.additionalSectionsDelegate numberOfAdditionalSections];
    if (indexPath.section < additionalSections) {
        if ([self.additionalSectionsDelegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)])
            [self.additionalSectionsDelegate tableView:tableView didSelectRowAtIndexPath:indexPath];
        return;
    }

    [self cancelDeletingIndexPathsAnimated:YES];    
    NSIndexPath *historyIndexPath = [self historyIndexPathForTableIndexPath:indexPath];
    
    NSArray *sections = [self.fetchedResultsController sections];
    if ([sections count] > historyIndexPath.section
        && [(id <NSFetchedResultsSectionInfo>)[sections objectAtIndex:historyIndexPath.section] numberOfObjects] > historyIndexPath.row) {
        
        DDGHistoryItem *historyItem = [self.fetchedResultsController objectAtIndexPath:historyIndexPath];
        //    [self.historyProvider relogHistoryItem:historyItem];
        DDGStory *story = historyItem.story;
        NSInteger readabilityMode = [[NSUserDefaults standardUserDefaults] integerForKey:DDGSettingStoriesReadabilityMode];
        if (nil != story)
            [self.searchHandler loadStory:story readabilityMode:(readabilityMode == DDGReadabilityModeOnExclusive || readabilityMode == DDGReadabilityModeOnIfAvailable)];
        else
            [self.searchHandler loadQueryOrURL:historyItem.title];        
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger fetchedSections = [[self.fetchedResultsController sections] count];
    NSInteger sections = fetchedSections + [self.additionalSectionsDelegate numberOfAdditionalSections];
    
    if (_showingNoResultsSection)
        sections += 1;
    
    return sections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger additionalSections = [self.additionalSectionsDelegate numberOfAdditionalSections];
    if (section < additionalSections)
        return [self.additionalSectionsDelegate tableView:tableView numberOfRowsInSection:(NSInteger)section];
    
    NSArray *sections = [self.fetchedResultsController sections];
    
    if (_showingNoResultsSection && section == (additionalSections + [sections count]))
        return 1;
    
    NSInteger historySection = [self historySectionForTableSection:section];
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][historySection];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger additionalSections = [self.additionalSectionsDelegate numberOfAdditionalSections];
    if (indexPath.section < additionalSections)
        return [self.additionalSectionsDelegate tableView:tableView cellForRowAtIndexPath:indexPath];
    
    DDGMenuHistoryItemCell *historyItemCell = [tableView dequeueReusableCellWithIdentifier:@"DDGMenuHistoryItemCell"];
    [self configureHistoryItemCell:historyItemCell atIndexPath:indexPath];
    return historyItemCell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSInteger additionalSections = [self.additionalSectionsDelegate numberOfAdditionalSections];
    if (section < additionalSections) {
        if ([self.additionalSectionsDelegate respondsToSelector:@selector(tableView:heightForHeaderInSection:)])
            return [self.additionalSectionsDelegate tableView:tableView heightForHeaderInSection:section];
    }
    
    return 50.0f;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    NSInteger additionalSections = [self.additionalSectionsDelegate numberOfAdditionalSections];
    if (section < additionalSections) {
        if ([self.additionalSectionsDelegate respondsToSelector:@selector(tableView:heightForFooterInSection:)])
            return [self.additionalSectionsDelegate tableView:tableView heightForFooterInSection:section];
    }
    
    return 0.0;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSInteger additionalSections = [self.additionalSectionsDelegate numberOfAdditionalSections];
    if (section < additionalSections) {
        if ([self.additionalSectionsDelegate respondsToSelector:@selector(tableView:viewForHeaderInSection:)])
            return [self.additionalSectionsDelegate tableView:tableView viewForHeaderInSection:section];
        return nil;
    }
    
    NSArray *sections = [self.fetchedResultsController sections];
    NSInteger historySection = [self historySectionForTableSection:section];
    NSString *headerTitle = nil;
    if (_showingNoResultsSection && section == ([sections count] + additionalSections)) {
        headerTitle = NSLocalizedString(@"Recent Searches & Stories", @"Table section header title");
    } else {
        NSString *name = [(id <NSFetchedResultsSectionInfo>)[sections objectAtIndex:historySection] name];
        if ([name isEqualToString:@"searches"]) {
            headerTitle = NSLocalizedString(@"Recent Searches", @"Table section header title");
        } else if ([name isEqualToString:@"stories"]) {
            headerTitle = NSLocalizedString(@"Recent Stories", @"Table section header title");
        } else {
            headerTitle = name;
        }
    }
    
    UINib *nib = [UINib nibWithNibName:@"DDGMenuSectionHeaderView" bundle:nil];
    DDGMenuSectionHeaderView *sectionHeaderView = (DDGMenuSectionHeaderView *)[nib instantiateWithOwner:nil options:nil][0];
    sectionHeaderView.title = headerTitle;
    return sectionHeaderView;
}

-(UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    NSInteger additionalSections = [self.additionalSectionsDelegate numberOfAdditionalSections];
    if (section < additionalSections) {
        if ([self.additionalSectionsDelegate respondsToSelector:@selector(tableView:viewForFooterInSection:)])
            return [self.additionalSectionsDelegate tableView:tableView viewForFooterInSection:section];
        return nil;
    }
        
    return nil;
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    NSInteger tableSectionIndex = [self tableSectionForHistorySection:sectionIndex];
    
//    NSLog(@"didChangeSection: %i change type: %i", tableSectionIndex, type);
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:tableSectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
                        
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:tableSectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
        
        case NSFetchedResultsChangeMove:
        case NSFetchedResultsChangeUpdate:
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    
    NSIndexPath *tableIndexPath = [self tableIndexPathForHistoryIndexPath:indexPath];
    NSIndexPath *newTableIndexPath = [self tableIndexPathForHistoryIndexPath:newIndexPath];
    
//    NSLog(@"didChangeObject atIndexPath: %@ newIndexPath: %@ change type: %i", tableIndexPath, newTableIndexPath, type);    
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newTableIndexPath] withRowAnimation:UITableViewRowAnimationFade];        
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[tableIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureHistoryItemCell:(DDGMenuHistoryItemCell *)[tableView cellForRowAtIndexPath:tableIndexPath]
                               atIndexPath:tableIndexPath];
            break;
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[tableIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newTableIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
    
    if ([self shouldShowNoHistoryView]) {
        [self.noResultsView removeFromSuperview];
        self.noResultsView = nil;
    } else if ([self shouldShowNoHistorySection]) {
        [self showNoResultsSection];
    } else {
        [self hideNoResultsSection];
        [self.noResultsView removeFromSuperview];
        self.noResultsView = nil;        
    }
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *historyIndexPath = [self historyIndexPathForTableIndexPath:indexPath];    
    
    DDGHistoryItemCell *underCell = (DDGHistoryItemCell *)cell;
    
    underCell.active = NO;
    
	underCell.imageView.image = nil;
    underCell.imageView.highlightedImage = nil;
    underCell.overhangWidth = self.overhangWidth;
    
	UILabel *lbl = cell.textLabel;

    NSArray *sections = [self.fetchedResultsController sections];
    
    if (_showingNoResultsSection && historyIndexPath.section == [sections count]) {
        
        underCell.fixedSizeImageView.image = [UIImage imageNamed:@"icon_notification"];
        underCell.fixedSizeImageView.size = CGSizeMake(24.0, 24.0);
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:DDGSettingRecordHistory])
            lbl.text = @"No recent searches or stories.";
        else
            lbl.text = @"Saving recents is disabled.\nYou can re-enable it in settings";
        
        cell.accessoryView = nil;
        
    } else {
        // we have history and it is enabled
        DDGHistoryItem *item = [self.fetchedResultsController objectAtIndexPath:historyIndexPath];
        DDGStory *story = item.story;
        
        if (nil != story) {
            underCell.fixedSizeImageView.image = story.feed.image;
            cell.accessoryView = nil;
        } else {
            underCell.fixedSizeImageView.image = [UIImage imageNamed:@"search_icon"];
            cell.accessoryView = [DDGPlusButton plusButton];
        }
        lbl.text = item.title;        
    }
}

- (void)configureHistoryItemCell:(DDGMenuHistoryItemCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *historyIndexPath = [self historyIndexPathForTableIndexPath:indexPath];
    NSArray *sections = [self.fetchedResultsController sections];
    NSString *content = nil;
    if (_showingNoResultsSection && historyIndexPath.section == [sections count]) {
        cell.notification = YES;
        BOOL recordHistory = [[NSUserDefaults standardUserDefaults] boolForKey:DDGSettingRecordHistory];
        content = recordHistory ? @"No recent searches or stories." : @"Saving recents is disabled.\nYou can re-enable it in settings";
    } else {
        DDGHistoryItem *historyItem = [self.fetchedResultsController objectAtIndexPath:historyIndexPath];
        DDGStory *story = historyItem.story;
        if (story) {
            cell.faviconImage = story.feed.image;
        } else {
            cell.auxiliaryViewHidden = NO;
        }
        content = historyItem.title;
        __weak typeof(self) weakSelf = self;
        [cell setDeleteBlock:^(id sender) {
            [weakSelf delete:sender];
        }];
    }
    cell.content = content;
}

@end
