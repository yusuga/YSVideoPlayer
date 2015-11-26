//
//  AVPlayerItem+YSVideoPlayer.h
//  YSVideoPlayer
//
//  Created by Yu Sugawara on 2015/11/21.
//  Copyright © 2015年 Yu Sugawara. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface AVPlayerItem (YSVideoPlayer)

- (AVPlayer *)ys_player;
- (void)ys_setPlayer:(AVPlayer *)obj;

@end
