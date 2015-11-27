//
//  YSEmbedVideoPlayerView.m
//  YSVideoPlayer
//
//  Created by Yu Sugawara on 2015/11/26.
//  Copyright © 2015年 Yu Sugawara. All rights reserved.
//

#import "YSEmbedVideoPlayerView.h"

@implementation YSEmbedVideoPlayerView

+ (Class)layerClass
{
    return [AVPlayerLayer class];
}

- (void)setPlayer:(AVPlayer *)player
{
    [[self playerLayer] setPlayer:player];
}

- (void)setVideoGravity:(NSString *)videoGravity
{
    [self playerLayer].videoGravity = videoGravity;
}

- (AVPlayerLayer *)playerLayer
{
    return (AVPlayerLayer *)self.layer;
}

@end
