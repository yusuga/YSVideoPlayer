//
//  MPMoviePlayerController+YSVideoPlayer.m
//  YSVideoPlayer
//
//  Created by Yu Sugawara on 2015/11/20.
//  Copyright © 2015年 Yu Sugawara. All rights reserved.
//

#import "MPMoviePlayerController+YSVideoPlayer.h"
#import <objc/message.h>
#import "YSVideoPlayerWeakObject.h"

@implementation MPMoviePlayerController (YSVideoPlayer)

- (UIViewController *)ys_parentViewController
{
    YSVideoPlayerWeakObject *weakObj = objc_getAssociatedObject(self, @selector(ys_parentViewController));
    return weakObj.obj;
}

- (void)ys_setParentViewController:(UIViewController *)obj
{
    YSVideoPlayerWeakObject *weakObj = [[YSVideoPlayerWeakObject alloc] init];
    weakObj.obj = obj;
    
    objc_setAssociatedObject(self, @selector(ys_parentViewController), weakObj, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
