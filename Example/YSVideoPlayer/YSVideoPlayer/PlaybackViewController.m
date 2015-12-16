//
//  PlaybackViewController.m
//  YSVideoPlayer
//
//  Created by Yu Sugawara on 2015/12/16.
//  Copyright © 2015年 Yu Sugawara. All rights reserved.
//

#import "PlaybackViewController.h"
#import "YSEmbedVideoPlayer.h"

@interface PlaybackViewController ()

@property (weak, nonatomic) IBOutlet UIView *playbakcArea;

@end

@implementation PlaybackViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    YSEmbedVideoPlayer *player = [YSEmbedVideoPlayer playerWithAsset:self.asset];
    
    [self.playbakcArea addSubview:player.view];
    [player.view setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [self.playbakcArea addConstraints:@[[NSLayoutConstraint constraintWithItem:player.view
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.playbakcArea
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1.
                                                                      constant:0.],
                                        [NSLayoutConstraint constraintWithItem:self.playbakcArea
                                                                     attribute:NSLayoutAttributeBottom
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:player.view
                                                                     attribute:NSLayoutAttributeBottom
                                                                    multiplier:1.
                                                                      constant:0.],
                                        [NSLayoutConstraint constraintWithItem:player.view
                                                                     attribute:NSLayoutAttributeLeading
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.playbakcArea
                                                                     attribute:NSLayoutAttributeLeading
                                                                    multiplier:1.
                                                                      constant:0.],
                                        [NSLayoutConstraint constraintWithItem:self.playbakcArea
                                                                     attribute:NSLayoutAttributeTrailing
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:player.view
                                                                     attribute:NSLayoutAttributeTrailing
                                                                    multiplier:1.
                                                                      constant:0.]]];
    [self addChildViewController:player];
    [player didMoveToParentViewController:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
