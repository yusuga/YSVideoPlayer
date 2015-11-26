//
//  AVPlayerItem+YSVideoPlayer.m
//  YSVideoPlayer
//
//  Created by Yu Sugawara on 2015/11/21.
//  Copyright © 2015年 Yu Sugawara. All rights reserved.
//

#import "AVPlayerItem+YSVideoPlayer.h"
#import <objc/message.h>
#import "YSVideoPlayerWeakObject.h"

@implementation AVPlayerItem (YSVideoPlayer)

- (AVPlayer *)ys_player
{
    YSVideoPlayerWeakObject *weakObj = objc_getAssociatedObject(self, @selector(ys_player));
    return weakObj.obj;
}

- (void)ys_setPlayer:(AVPlayer *)obj
{
    YSVideoPlayerWeakObject *weakObj = [[YSVideoPlayerWeakObject alloc] init];
    weakObj.obj = obj;
    
    objc_setAssociatedObject(self, @selector(ys_player), weakObj, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
