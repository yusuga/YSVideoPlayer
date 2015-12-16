//
//  AssetViewCell.h
//  YSVideoPlayer
//
//  Created by Yu Sugawara on 2015/12/16.
//  Copyright © 2015年 Yu Sugawara. All rights reserved.
//

#import <UIKit/UIKit.h>
@import Photos;

@interface AssetViewCell : UICollectionViewCell

- (void)bindAsset:(PHAsset *)asset;
@property (weak, nonatomic, readonly) PHAsset *asset;

@end
