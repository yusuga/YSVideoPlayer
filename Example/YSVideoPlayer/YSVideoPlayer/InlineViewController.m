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

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self removePlayer];
}

- (IBAction)addButtonClicked:(id)sender
{
    if (self.player) return;
    
    NSString *URLStr;
    switch (self.videoControl.selectedSegmentIndex) {
        case 0:
            URLStr = @"http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8";
            break;
        case 1:
            URLStr = @"https://video.twimg.com/ext_tw_video/560070131976392705/pu/pl/r1kgzh5PmLgium3-.m3u8";
            break;
        case 2:
            URLStr = @"https://video.twimg.com/ext_tw_video/560070131976392705/pu/vid/1280x720/c4E56sl91ZB7cpYi.mp4";
            break;
        case 3:
            URLStr = @"https://16-lvl3-pdl.vimeocdn.com/01/2540/3/87701971/230891258.mp4";
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

@end
