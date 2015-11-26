//
//  YSVideoPlayer.h
//  YSVideoPlayer
//
//  Created by Yu Sugawara on 2015/11/20.
//  Copyright © 2015年 Yu Sugawara. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YSVideoPlayer : NSObject

+ (void)presentFromViewController:(UIViewController *)parentVC
                    withURLString:(NSString *)URLString
                           repeat:(BOOL)repeat;

+ (void)presentFromViewController:(UIViewController *)parentVC
                    withURLString:(NSString *)URLString
                           repeat:(BOOL)repeat
             modalTransitionStyle:(UIModalTransitionStyle)modalTransitionStyle;

@end
