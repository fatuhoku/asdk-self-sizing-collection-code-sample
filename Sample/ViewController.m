/* This file provided by Facebook is for non-commercial testing and evaluation
 * purposes only.  Facebook reserves all rights not expressly granted.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * FACEBOOK BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
 * ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "ViewController.h"

#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import "SupplementaryNode.h"
#import "SelfSizingWaterfallCollectionViewLayout.h"
#import "ItemNode.h"
#import "ASCollectionViewFlowLayoutInspector.h"

@interface ViewController () <ASCollectionViewDataSource, ASCollectionViewDelegateFlowLayout, ASCollectionViewLayoutInspecting> {
    ASCollectionView *_collectionView;
}

@property(nonatomic, strong) SelfSizingWaterfallCollectionViewLayout *layout;
@end


@implementation ViewController {
    BOOL _delegateImplementsReferenceSizeForHeader;
    BOOL _delegateImplementsReferenceSizeForFooter;
}

#pragma mark -
#pragma mark UIViewController.

- (instancetype)init {
    if (!(self = [super init]))
        return nil;

    SelfSizingWaterfallCollectionViewLayout *layout = [[SelfSizingWaterfallCollectionViewLayout alloc] init];
    layout.numberOfColumns = 3;
    layout.estimatedItemHeight = 300;
    layout.headerReferenceSize = CGSizeMake(50.0, 50.0);
    layout.footerReferenceSize = CGSizeMake(50.0, 50.0);
    self.layout = layout;

    _collectionView = [[ASCollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout asyncDataFetching:YES];
    _collectionView.asyncDataSource = self;
    _collectionView.asyncDelegate = self;
    _collectionView.layoutInspector = self;
    _collectionView.backgroundColor = [UIColor whiteColor];

    [_collectionView registerSupplementaryNodeOfKind:UICollectionElementKindSectionHeader];
    [_collectionView registerSupplementaryNodeOfKind:UICollectionElementKindSectionFooter];

    self.navigationItem.leftItemsSupplementBackButton = YES;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reloadTapped)];

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    NSAssert(_collectionView, @"collectionView should be present by now");

    [self didChangeCollectionViewDelegate:_collectionView.asyncDelegate];

    [self.view addSubview:_collectionView];
}

- (void)viewWillLayoutSubviews {
    _collectionView.frame = self.view.bounds;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)reloadTapped {
    [_collectionView reloadData];
}

#pragma mark -
#pragma mark ASCollectionView data source.

- (ASCellNode *)collectionView:(ASCollectionView *)collectionView nodeForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"%s(indexPath: %@)", sel_getName(_cmd), indexPath);
    NSString *text = [NSString stringWithFormat:@"[%zd.%zd] says hi", indexPath.section, indexPath.item];
    return [[ItemNode alloc] initWithString:text];
}

- (ASCellNode *)collectionView:(ASCollectionView *)collectionView nodeForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"%s(indexPath: %@)", sel_getName(_cmd), indexPath);
    NSString *text = [kind isEqualToString:UICollectionElementKindSectionHeader] ? @"Header" : @"Footer";
    SupplementaryNode *node = [[SupplementaryNode alloc] initWithText:text];
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        node.backgroundColor = [UIColor blueColor];
    } else {
        node.backgroundColor = [UIColor redColor];
    }
    return node;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 10;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 100;
}

- (void)collectionViewLockDataSource:(ASCollectionView *)collectionView {
    // lock the data source
    // The data source should not be change until it is unlocked.
}

- (void)collectionViewUnlockDataSource:(ASCollectionView *)collectionView {
    // unlock the data source to enable data source updating.
}

- (void)collectionView:(UICollectionView *)collectionView willBeginBatchFetchWithContext:(ASBatchContext *)context {
    NSLog(@"fetch additional content");
    [context completeBatchFetching:YES];
}

- (UIEdgeInsets)collectionView:(ASCollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(20.0, 20.0, 20.0, 20.0);
}

#pragma mark - Inspecting

- (void)didChangeCollectionViewDelegate:(id <ASCollectionViewDelegate>)delegate; {
    if (delegate == nil) {
        _delegateImplementsReferenceSizeForHeader = NO;
        _delegateImplementsReferenceSizeForFooter = NO;
    } else {
        _delegateImplementsReferenceSizeForHeader = [delegate respondsToSelector:@selector(collectionView:layout:referenceSizeForHeaderInSection:)];
        _delegateImplementsReferenceSizeForFooter = [delegate respondsToSelector:@selector(collectionView:layout:referenceSizeForFooterInSection:)];
    }
}

#pragma mark - ASCollectionViewLayoutInspecting

- (ASSizeRange)collectionView:(ASCollectionView *)collectionView constrainedSizeForNodeAtIndexPath:(NSIndexPath *)indexPath {
    // TODO: Provide constrained size for flow layout item nodes
    return ASSizeRangeMake(CGSizeZero, CGSizeZero);
}

- (ASSizeRange)collectionView:(ASCollectionView *)collectionView constrainedSizeForSupplementaryNodeOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    CGSize constrainedSize;
    CGSize supplementarySize = [self sizeForSupplementaryViewOfKind:kind inSection:(NSUInteger) indexPath.section collectionView:collectionView];
    constrainedSize = CGSizeMake(collectionView.bounds.size.width, supplementarySize.height);
    return ASSizeRangeMake(CGSizeZero, constrainedSize);
}

- (NSUInteger)collectionView:(ASCollectionView *)collectionView numberOfSectionsForSupplementaryNodeOfKind:(NSString *)kind {
    if ([collectionView.asyncDataSource respondsToSelector:@selector(numberOfSectionsInCollectionView:)]) {
        return (NSUInteger) [collectionView.asyncDataSource numberOfSectionsInCollectionView:collectionView];
    } else {
        return 1;
    }
}

- (NSUInteger)collectionView:(ASCollectionView *)collectionView supplementaryNodesOfKind:(NSString *)kind inSection:(NSUInteger)section {
    return [self layoutHasSupplementaryViewOfKind:kind inSection:section collectionView:collectionView] ? 1 : 0;
}

#pragma mark - Private helpers

- (CGSize)sizeForSupplementaryViewOfKind:(NSString *)kind inSection:(NSUInteger)section collectionView:(ASCollectionView *)collectionView {
    if (ASObjectIsEqual(kind, UICollectionElementKindSectionHeader)) {
        if (_delegateImplementsReferenceSizeForHeader) {
            return [[self delegateForCollectionView:collectionView] collectionView:collectionView layout:_layout referenceSizeForHeaderInSection:section];
        } else {
            return [self.layout headerReferenceSize];
        }
    } else if (ASObjectIsEqual(kind, UICollectionElementKindSectionFooter)) {
        if (_delegateImplementsReferenceSizeForFooter) {
            return [[self delegateForCollectionView:collectionView] collectionView:collectionView layout:_layout referenceSizeForFooterInSection:section];
        } else {
            return [self.layout footerReferenceSize];
        }
    } else {
        return CGSizeZero;
    }
}

- (BOOL)layoutHasSupplementaryViewOfKind:(NSString *)kind inSection:(NSUInteger)section collectionView:(ASCollectionView *)collectionView {
    CGSize size = [self sizeForSupplementaryViewOfKind:kind inSection:section collectionView:collectionView];
    return [self usedLayoutValueForSize:size] > 0;
}

- (CGFloat)usedLayoutValueForSize:(CGSize)size {
    return size.height;
}

- (id <ASCollectionViewDelegateFlowLayout>)delegateForCollectionView:(ASCollectionView *)collectionView {
    return (id <ASCollectionViewDelegateFlowLayout>) collectionView.asyncDelegate;
}

@end
