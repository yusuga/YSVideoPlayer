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

FOUNDATION_EXTERN NSString * const YSEmbedVideoPlayerDidChangeContolsViewShownNotification;
FOUNDATION_EXTERN NSString * const YSEmbedVideoPlayerDidChangeContolsViewShownAnimationDurationKey;

@interface YSEmbedVideoPlayer : UIViewController

+ (YSEmbedVideoPlayer *)playerWithURLString:(NSString *)URLString;
+ (YSEmbedVideoPlayer *)playerWithURLString:(NSString *)URLString
                                      repeat:(BOOL)repeat;

+ (YSEmbedVideoPlayer *)playerWithAsset:(PHAsset *)asset;

@property (weak, nonatomic, readonly) IBOutlet YSEmbedVideoPlayerView *playerView;
@property (weak, nonatomic, readonly) IBOutlet UIView *scrubberView;
@property (weak, nonatomic, readonly) IBOutlet NSLayoutConstraint *scrubberViewBottomConstraint;
- (void)contolsViewShown:(BOOL)shown animated:(BOOL)animated animationDuration:(NSTimeInterval)animationDuration;

@property (nonatomic) BOOL autoHideControlViewsDisabled;

+ (void)deleteDiskCache;

+ (void)cleanDiskCache;
+ (void)cleanDiskCacheWithMaxCacheAge:(NSInteger)maxCacheAge;

+ (UIColor *)scrubberViewTopGradientColor;
+ (UIColor *)scrubberViewBottomGradientColor;

@end
