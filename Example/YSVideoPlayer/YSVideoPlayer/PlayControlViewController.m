//
//  PlayControlViewController.m
//  YSVideoPlayer
//
//  Created by Yu Sugawara on 2015/12/16.
//  Copyright © 2015年 Yu Sugawara. All rights reserved.
//

#import "PlayControlViewController.h"
#import "YSVideoPlayControl.h"

@interface PlayControlViewController ()

@end

@implementation PlayControlViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    YSVideoPlayControl *control = [[YSVideoPlayControl alloc] initWithTarget:self
                                                                      action:@selector(playControlClicked:)
                                                            forControlEvents:UIControlEventTouchUpInside];
    control.autoresizingMask = UIViewAutoresizingNone;
    [self.view addSubview:control];
    control.center = CGPointMake(self.view.bounds.size.width/2., self.view.bounds.size.height/2.);
}

- (void)playControlClicked:(UIButton *)sender
{
    NSLog(@"%s", __func__);
}

@end
