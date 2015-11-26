//
//  InlineViewController.m
//  YSVideoPlayer
//
//  Created by Yu Sugawara on 2015/11/26.
//  Copyright © 2015年 Yu Sugawara. All rights reserved.
//

#import "InlineViewController.h"
#import "YSEmbeddedVideoPlayer.h"

@interface InlineViewController ()

@property (weak, nonatomic) IBOutlet UIView *inlineView;
@property (nonatomic) YSEmbeddedVideoPlayer *player;
@property (weak, nonatomic) IBOutlet UISwitch *bipBopSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *repeatSwitch;

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
    if (self.bipBopSwitch.on) {
        URLStr = @"http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8";
    } else {
        URLStr = @"https://video.twimg.com/ext_tw_video/560070131976392705/pu/pl/r1kgzh5PmLgium3-.m3u8";
    }
    
    YSEmbeddedVideoPlayer *player = [YSEmbeddedVideoPlayer playerWithURLString:URLStr
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
