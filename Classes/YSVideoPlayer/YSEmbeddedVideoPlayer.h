//
//  YSEmbeddedVideoPlayer.h
//  YSVideoPlayer
//
//  Created by Yu Sugawara on 2015/11/25.
//  Copyright © 2015年 Yu Sugawara. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YSEmbeddedVideoPlayerView.h"

@interface YSEmbeddedVideoPlayer : UIViewController

+ (YSEmbeddedVideoPlayer *)playerWithURLString:(NSString *)URLString;
+ (YSEmbeddedVideoPlayer *)playerWithURLString:(NSString *)URLString
                                      repeat:(BOOL)repeat;

@property (weak, nonatomic, readonly) IBOutlet YSEmbeddedVideoPlayerView *playerView;

@end
