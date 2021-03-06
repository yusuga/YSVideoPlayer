//
//  InlineViewController.m
//  YSVideoPlayer
//
//  Created by Yu Sugawara on 2015/11/26.
//  Copyright © 2015年 Yu Sugawara. All rights reserved.
//

#import "InlineViewController.h"
#import "YSEmbedVideoPlayer.h"

@interface InlineViewController ()

@property (weak, nonatomic) IBOutlet UIView *inlineView;
@property (nonatomic) YSEmbedVideoPlayer *player;

@property (weak, nonatomic) IBOutlet UISwitch *repeatSwitch;
@property (weak, nonatomic) IBOutlet UISegmentedControl *videoControl;

@end

@implementation InlineViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self registerNotifications];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self unregisterNotifications];
    [self removePlayer];
}

- (IBAction)addButtonClicked:(id)sender
{
    if (self.player) return;
    
    NSString *URLStr;
    switch (self.videoControl.selectedSegmentIndex) {
        case 0:
            URLStr = @"http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8";
            // URLStr = @"http://devstreaming.apple.com/videos/wwdc/2015/1026npwuy2crj2xyuq11/102/hls_vod_mvp.m3u8"; // Long video
            break;
        case 1:
            URLStr = @"https://video.twimg.com/ext_tw_video/560070131976392705/pu/pl/r1kgzh5PmLgium3-.m3u8";
            break;
        case 2:
            URLStr = @"https://video.twimg.com/ext_tw_video/560070131976392705/pu/vid/1280x720/c4E56sl91ZB7cpYi.mp4";
            break;
        case 3:
            /* http://www.sample-videos.com */
            URLStr = @"http://www.sample-videos.com/video/mp4/720/big_buck_bunny_720p_50mb.mp4";
            break;
        default:
            abort();
            break;
    }
    
    YSEmbedVideoPlayer *player = [YSEmbedVideoPlayer playerWithURLString:URLStr
                                                                  repeat:self.repeatSwitch.on];
    
    player.view.frame = self.inlineView.bounds;
    [self.inlineView addSubview:player.view];
    [self addChildViewController:player];
    [player didMoveToParentViewController:self];
    
    self.player = player;
}

- (IBAction)removePlayer
{
    if (!self.player) return;
    
    [self.player willMoveToParentViewController:nil];
    [self.player.view removeFromSuperview];
    [self.player removeFromParentViewController];
    
    self.player = nil;
}

- (IBAction)deleteDiskCache
{
    NSLog(@"%s", __func__);
    [YSEmbedVideoPlayer deleteDiskCache];
}

#pragma mark - Notification

- (void)registerNotifications
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    [center addObserver:self
               selector:@selector(embedVideoPlayerDidChangeContolsViewShownNotification:)
                   name:YSEmbedVideoPlayerDidChangeContolsViewShownNotification
                 object:nil];
}

- (void)unregisterNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Handler

- (void)embedVideoPlayerDidChangeContolsViewShownNotification:(NSNotification *)noti
{
    NSLog(@"%s, noti: %@", __func__, noti);
}

@end
