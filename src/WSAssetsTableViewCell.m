//
// WSAssetsTableViewCell.m
// WSAssetPickerController
//
// Created by Wesley Smith on 5/12/12.
// Copyright (c) 2012 Wesley D. Smith. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "WSAssetsTableViewCell.h"
#import "WSAssetWrapper.h"
#import "WSAssetViewColumn.h"

@interface WSAssetsTableViewCell ()
@property (nonatomic, strong) UIView *assetsContainerView;
@property (nonatomic) CGRect assetFrame;
@property (nonatomic) int assetsPerRow;
@end

@implementation WSAssetsTableViewCell

@synthesize delegate = _delegate;
@synthesize cellAssetViews = _cellAssetViews;

#define ASSET_VIEW_PADDING 4
#define ASSET_PER_ROW 4

+ (WSAssetsTableViewCell *)assetsCellWithAssets:(NSArray *)assets reuseIdentifier:(NSString *)identifier
{
    WSAssetsTableViewCell *cell = [[WSAssetsTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    cell.cellAssetViews = assets;
    
    return cell;
}

- (id)initWithAssets:(NSArray *)assets reuseIdentifier:(NSString *)identifier
{
    if ((self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier])) {
        self.cellAssetViews = assets;
    }
    
    return self;
}

- (void)stopObserving
{
    // Remove the old WSAssetViews.
    for (WSAssetViewColumn *assetViewColumn in self.cellAssetViews) {
        [assetViewColumn removeObserver:self forKeyPath:@"isSelected"];
        
        [assetViewColumn removeFromSuperview];
    }
}

- (UIView *)assetsContainerView
{
    if (_assetsContainerView == nil) {
        // Create a containing view with flexible margins.
        _assetsContainerView = [[UIView alloc] initWithFrame:CGRectZero];
        _assetsContainerView.autoresizingMask =
        UIViewAutoresizingFlexibleLeftMargin |
        UIViewAutoresizingFlexibleRightMargin |
        UIViewAutoresizingFlexibleTopMargin |
        UIViewAutoresizingFlexibleBottomMargin;
        [self addSubview:_assetsContainerView];
    }
    return _assetsContainerView;
}

- (void)setCellAssetViews:(NSArray *)assets
{
    [self stopObserving];
    
    // Create new WSAssetViews
    NSMutableArray *columns = [NSMutableArray arrayWithCapacity:[assets count]];
    
    for (WSAssetWrapper *assetWrapper in assets) {
        WSAssetViewColumn *assetViewColumn = [[WSAssetViewColumn alloc] initWithImage:[UIImage imageWithCGImage:assetWrapper.asset.thumbnail] withFrame:self.assetFrame];
        assetViewColumn.column = [assets indexOfObject:assetWrapper];
        assetViewColumn.selected = assetWrapper.isSelected;
        
        __weak __typeof__(self) weakSelf = self;
        
        [assetViewColumn setShouldSelectItemBlock: ^BOOL (NSInteger column) {
            return [weakSelf.delegate assetsTableViewCell:weakSelf shouldSelectAssetAtColumn:column];
        }];
        
        // Observe the column's isSelected property.
        [assetViewColumn addObserver:self forKeyPath:@"isSelected" options:NSKeyValueObservingOptionNew context:NULL];
        
        [columns addObject:assetViewColumn];
    }
    
    _cellAssetViews = columns;
    self.assetsPerRow = ASSET_PER_ROW;
    CGRect screenRect = [[UIScreen mainScreen]bounds];
    float assetWidth = (screenRect.size.width - ((self.assetsPerRow - 1) * ASSET_VIEW_PADDING)) / self.assetsPerRow;
    self.assetFrame = CGRectMake(0, 0, assetWidth, assetWidth);
}

- (void)layoutSubviews
{
    // Calculate the container's width.
    float containerWidth = self.assetsPerRow * self.assetFrame.size.width + (self.assetsPerRow - 1) * ASSET_VIEW_PADDING;
    
    // Create the container frame dynamically.
    CGRect containerFrame;
    containerFrame.origin.x = (self.frame.size.width - containerWidth) / 2;
    containerFrame.origin.y = (self.frame.size.height - self.assetFrame.size.height) / 2;
    containerFrame.size.width = containerWidth;
    containerFrame.size.height = self.assetFrame.size.height;
    self.assetsContainerView.frame = containerFrame;
    
    CGRect frame = self.assetFrame;
    
    for (WSAssetViewColumn *assetView in self.cellAssetViews) {
        assetView.frame = frame;
        
        [self.assetsContainerView addSubview:assetView];
        
        // Adjust the frame x-origin of the next assetView.
        frame.origin.x = frame.origin.x + frame.size.width + ASSET_VIEW_PADDING;
    }
}

- (CGFloat)cellHeight
{
    return (self.assetFrame.size.height + ASSET_VIEW_PADDING);
}

- (CGFloat)assetWidthWithPadding
{
    return (self.assetFrame.size.width + ASSET_VIEW_PADDING);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([object isMemberOfClass:[WSAssetViewColumn class]]) {
        WSAssetViewColumn *column = (WSAssetViewColumn *)object;
        if ([self.delegate respondsToSelector:@selector(assetsTableViewCell:didSelectAsset:atColumn:)]) {
            [self.delegate assetsTableViewCell:self didSelectAsset:column.isSelected atColumn:column.column];
        }
    }
}

- (void)dealloc
{
    [self stopObserving];
}

@end
