//
//  YSVideoPlayerWeakObject.m
//  YSVideoPlayer
//
//  Created by Yu Sugawara on 2015/11/21.
//  Copyright © 2015年 Yu Sugawara. All rights reserved.
//

#import "YSVideoPlayerWeakObject.h"
#import "YSVideoPlayer.h"

@implementation YSVideoPlayerWeakObject

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:[YSVideoPlayer class]];
}

@end
