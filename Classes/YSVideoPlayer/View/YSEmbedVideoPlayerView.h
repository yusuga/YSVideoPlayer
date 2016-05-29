//
//  YSEmbedVideoPlayerView.h
//  YSVideoPlayer
//
//  Created by Yu Sugawara on 2015/11/26.
//  Copyright © 2015年 Yu Sugawara. All rights reserved.
//

#import <UIKit/UIKit.h>
@import AVFoundation;

@interface YSEmbedVideoPlayerView : UIView

- (void)setPlayer:(AVPlayer *)player;
- (AVPlayerLayer *)playerLayer;

- (void)setVideoGravity:(NSString *)videoGravity;

@end
