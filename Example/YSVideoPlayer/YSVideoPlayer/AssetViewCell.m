//
//  AssetViewCell.m
//  YSVideoPlayer
//
//  Created by Yu Sugawara on 2015/12/16.
//  Copyright © 2015年 Yu Sugawara. All rights reserved.
//

#import "AssetViewCell.h"

@interface AssetViewCell ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (weak, nonatomic, readwrite) PHAsset *asset;
@property (nonatomic) PHImageRequestID imageRequestID;

@end

@implementation AssetViewCell

- (void)prepareForReuse
{
    [[PHImageManager defaultManager] cancelImageRequest:self.imageRequestID];
    self.asset = nil;
}

- (void)bindAsset:(PHAsset *)asset
{
    CGFloat scale = [UIScreen mainScreen].scale;
    CGSize targetSize = CGSizeMake(self.imageView.bounds.size.width * scale, self.imageView.bounds.size.height * scale);
    
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.resizeMode = PHImageRequestOptionsResizeModeNone;
    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    
    __weak typeof(self) wself = self;
    self.imageRequestID = [[PHImageManager defaultManager] requestImageForAsset:asset
                                                                     targetSize:targetSize
                                                                    contentMode:PHImageContentModeAspectFill
                                                                        options:options
                                                                  resultHandler:^(UIImage *image, NSDictionary *info)
                           {
                               dispatch_async(dispatch_get_main_queue(), ^{
                                   if ([info[PHImageCancelledKey] boolValue]) return ;
                                   
                                   wself.imageRequestID = 0;
                                   NSError *error = [info objectForKey:PHImageErrorKey];
                                   if (error) {
                                       NSLog(@"error: %@", error);
                                   } else {
                                       //                                       NSLog(@"image.size: %@, options: %@, info: %@", NSStringFromCGSize(image.size), options, info);
                                       wself.imageView.image = image;
                                   }
                               });
                           }];
    self.asset = asset;
}

- (UIImage *)image
{
    return self.imageView.image;
}

@end
