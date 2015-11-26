//
//  MPMoviePlayerController+YSVideoPlayer.h
//  YSVideoPlayer
//
//  Created by Yu Sugawara on 2015/11/20.
//  Copyright © 2015年 Yu Sugawara. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
@import UIKit;

@interface MPMoviePlayerController (YSVideoPlayer)

- (UIViewController *)ys_parentViewController;
- (void)ys_setParentViewController:(UIViewController *)obj;

@end
