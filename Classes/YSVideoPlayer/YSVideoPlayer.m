//
//  YSVideoPlayer.m
//  YSVideoPlayer
//
//  Created by Yu Sugawara on 2015/11/20.
//  Copyright © 2015年 Yu Sugawara. All rights reserved.
//

#import "YSVideoPlayer.h"
@import MediaPlayer;
@import AVFoundation;
@import AVKit;
#import "MPMoviePlayerController+YSVideoPlayer.h"
#import "AVPlayerItem+YSVideoPlayer.h"

@interface YSVideoPlayer ()

@property (nonatomic) id playerViewController;

@end

@implementation YSVideoPlayer

+ (void)presentFromViewController:(UIViewController *)parentVC
                    withURLString:(NSString *)URLString
                           repeat:(BOOL)repeat
{
    [self presentFromViewController:parentVC
                      withURLString:URLString
                             repeat:repeat
               modalTransitionStyle:UIModalTransitionStyleCoverVertical];
}

+ (void)presentFromViewController:(UIViewController *)parentVC
                    withURLString:(NSString *)URLString
                           repeat:(BOOL)repeat
             modalTransitionStyle:(UIModalTransitionStyle)modalTransitionStyle
{
    if ([AVPlayerViewController class]) {
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:URLString]];
        AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
        
        AVPlayerViewController *playerVC = [[AVPlayerViewController alloc] init];
        playerVC.player = player;
        playerVC.modalTransitionStyle = modalTransitionStyle;
        
        if (repeat) {
            [playerItem ys_setPlayer:player];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(playerDidPlayToEndTime:)
                                                         name:AVPlayerItemDidPlayToEndTimeNotification
                                                       object:player.currentItem];
        }
        
        __weak AVPlayer *weakPlayer = player;
        [parentVC presentViewController:playerVC
                               animated:YES
                             completion:^{
                                 [weakPlayer play];
                             }];
    } else {
        MPMoviePlayerViewController *playerVC = [[MPMoviePlayerViewController alloc] init];
        playerVC.modalTransitionStyle = modalTransitionStyle;
        MPMoviePlayerController *player = playerVC.moviePlayer;
        
        player.movieSourceType = MPMovieSourceTypeStreaming;
        player.contentURL = [NSURL URLWithString:URLString]; // Bug?: movieSourceTypeの後でないとクラッシュする
        
        if (repeat) playerVC.moviePlayer.repeatMode = MPMovieRepeatModeOne;
        
        /*
         *  How to stop MPMoviePlayerViewController's automatic dismiss on moviePlaybackDidFinish?
         *  http://stackoverflow.com/questions/13420564/how-to-stop-mpmovieplayerviewcontrollers-automatic-dismiss-on-movieplaybackdidf/19596598#19596598
         */
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center removeObserver:playerVC
                          name:MPMoviePlayerPlaybackDidFinishNotification
                        object:playerVC.moviePlayer];
        [player ys_setParentViewController:parentVC];
        [center addObserver:self
                   selector:@selector(MPMoviePlayerFinished:)
                       name:MPMoviePlayerPlaybackDidFinishNotification
                     object:playerVC.moviePlayer];
        
        
        UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:playerVC];
        nc.navigationBarHidden = YES;
        
        [parentVC presentViewController:nc animated:YES completion:nil];
    }
}

#pragma mark - MPMoviePlayer

+ (void)MPMoviePlayerFinished:(NSNotification *)note
{
    int value = [[note.userInfo valueForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue];
    if (value == MPMovieFinishReasonUserExited) {
        MPMoviePlayerController *player = note.object;
        [[player ys_parentViewController] dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - AVPlayerItem

+ (void)playerDidPlayToEndTime:(NSNotification *)note
{
    AVPlayerItem *item = note.object;
    AVPlayer *player = [item ys_player];
    [player seekToTime:kCMTimeZero];
    [player play];
}

@end
