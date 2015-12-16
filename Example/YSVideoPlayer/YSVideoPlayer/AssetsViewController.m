//
//  AssetsViewController.m
//  YSVideoPlayer
//
//  Created by Yu Sugawara on 2015/12/16.
//  Copyright © 2015年 Yu Sugawara. All rights reserved.
//

#import "AssetsViewController.h"
#import <CTAssetsPickerController/CTAssetsPickerController.h>
#import "AssetViewCell.h"
#import "PlaybackViewController.h"

@interface AssetsViewController () <CTAssetsPickerControllerDelegate>

@property (copy, nonatomic) NSArray<PHAsset *> *selectedAssets;

@end

@implementation AssetsViewController

static NSString * const reuseIdentifier = @"Cell";

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    PlaybackViewController *vc = (id)segue.destinationViewController;
    NSAssert([vc isKindOfClass:[PlaybackViewController class]], @"vc: %@", vc);
    
    NSIndexPath *indexPath = [[self.collectionView indexPathsForSelectedItems] firstObject];
    vc.asset = self.selectedAssets[indexPath.row];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.selectedAssets count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    AssetViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    PHAsset *asset = self.selectedAssets[indexPath.row];
    [cell bindAsset:asset];
    
    return cell;
}

#pragma mark - Assets

- (IBAction)chooseButtonClicked:(id)sender
{
    __weak typeof(self) wself = self;
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status){
        dispatch_async(dispatch_get_main_queue(), ^{
            CTAssetsPickerController *picker = [[CTAssetsPickerController alloc] init];
            picker.delegate = wself;
            
            picker.assetCollectionSubtypes = @[@(PHAssetCollectionSubtypeSmartAlbumVideos),
                                               @(PHAssetCollectionSubtypeSmartAlbumSlomoVideos)];
            
            picker.defaultAssetCollection = PHAssetCollectionSubtypeSmartAlbumVideos;
            picker.alwaysEnableDoneButton = YES;
            picker.showsSelectionIndex = YES;
            picker.showsCancelButton = NO;
            
            PHFetchOptions *fetchOptions = [PHFetchOptions new];
            fetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
            picker.assetsFetchOptions = fetchOptions;
            
            [wself presentViewController:picker animated:YES completion:nil];
        });
    }];
}

#pragma mark - <CTAssetsPickerControllerDelegate>

- (void)assetsPickerController:(CTAssetsPickerController *)picker didFinishPickingAssets:(NSArray *)assets
{
    self.selectedAssets = assets;
    [self.collectionView reloadData];
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end
