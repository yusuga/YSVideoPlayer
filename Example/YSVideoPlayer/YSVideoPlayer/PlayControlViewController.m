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
    [self.view addSubview:control];
    
    [self.view addConstraints:@[[NSLayoutConstraint constraintWithItem:control
                                                             attribute:NSLayoutAttributeCenterX
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self.view
                                                             attribute:NSLayoutAttributeCenterX
                                                            multiplier:1.
                                                              constant:0.],
                                [NSLayoutConstraint constraintWithItem:control
                                                             attribute:NSLayoutAttributeCenterY
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self.view
                                                             attribute:NSLayoutAttributeCenterY
                                                            multiplier:1.
                                                              constant:0.]]];
}

- (void)playControlClicked:(UIButton *)sender
{
    NSLog(@"%s", __func__);
}

@end
