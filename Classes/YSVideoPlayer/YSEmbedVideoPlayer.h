//
//  YSEmbedVideoPlayer.h
//  YSVideoPlayer
//
//  Created by Yu Sugawara on 2015/11/25.
//  Copyright © 2015年 Yu Sugawara. All rights reserved.
//

#import <UIKit/UIKit.h>
@import Photos;
#import "YSEmbedVideoPlayerView.h"

@interface YSEmbedVideoPlayer : UIViewController

+ (YSEmbedVideoPlayer *)playerWithURLString:(NSString *)URLString;
+ (YSEmbedVideoPlayer *)playerWithURLString:(NSString *)URLString
                                      repeat:(BOOL)repeat;

+ (YSEmbedVideoPlayer *)playerWithAsset:(PHAsset *)asset;

@property (weak, nonatomic, readonly) IBOutlet YSEmbedVideoPlayerView *playerView;

+ (void)deleteDiskCache;

+ (void)cleanDiskCache;
+ (void)cleanDiskCacheWithMaxCacheAge:(NSInteger)maxCacheAge;

@end
