//
//  YSEmbeddedVideoPlayer.m
//  YSVideoPlayer
//
//  Created by Yu Sugawara on 2015/11/25.
//  Copyright © 2015年 Yu Sugawara. All rights reserved.
//

#import "YSEmbeddedVideoPlayer.h"
@import AVFoundation;
@import CoreText;
#import <KVOController/FBKVOController.h>
#import "YSVideoPlayerStyleKit.h"

typedef NS_ENUM(NSInteger, PlayerStatus) {
    PlayerStatusNone,
    PlayerStatusWait,
    PlayerStatusPlay,
    PlayerStatusPause,
    PlayerStatusEnd,
    PlayerStatusError,
};

@interface YSEmbeddedVideoPlayer ()

@property (weak, nonatomic) IBOutlet UIView *activityIndicatorContainer;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorView;

@property (weak, nonatomic) IBOutlet UIView *controlsView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIButton *controlButton;
@property (weak, nonatomic) IBOutlet UISlider *scrubber;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

@property (copy, nonatomic) NSString *URLString;
@property (weak, nonatomic, readwrite) IBOutlet YSEmbeddedVideoPlayerView *playerView;
@property (nonatomic) AVPlayer *player;
@property (nonatomic) BOOL repeat;
@property (nonatomic) float restoreAfterScrubbingRate;
@property (nonatomic) Float64 totalTime;
@property (copy, nonatomic) NSString *totalTimeString;

@property (nonatomic) PlayerStatus playerStatus;
@property (nonatomic) id timeObserver;

@end

@implementation YSEmbeddedVideoPlayer

+ (YSEmbeddedVideoPlayer *)playerWithURLString:(NSString *)URLString
{
    return [self playerWithURLString:URLString
                              repeat:NO];
}

+ (YSEmbeddedVideoPlayer *)playerWithURLString:(NSString *)URLString
                                      repeat:(BOOL)repeat
{
    UIStoryboard *sb = [UIStoryboard storyboardWithName:NSStringFromClass([self class]) bundle:nil];
    YSEmbeddedVideoPlayer *player = [sb instantiateInitialViewController];
    player.URLString = URLString;
    player.repeat = repeat;
    return player;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    /*
     *  iOS 9 Proportional Numbers
     *  http://useyourloaf.com/blog/ios-9-proportional-numbers.html
     */
    NSDictionary * fontAttributes = @{UIFontDescriptorFeatureSettingsAttribute: @[@{UIFontFeatureTypeIdentifierKey: @(kNumberSpacingType),
                                                                                    UIFontFeatureSelectorIdentifierKey: @(kMonospacedNumbersSelector)}]};
    self.timeLabel.font = [UIFont fontWithDescriptor:[[self.timeLabel.font fontDescriptor] fontDescriptorByAddingAttributes:fontAttributes]
                                                size:self.timeLabel.font.pointSize];    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self createPlayer];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    self.playerStatus = PlayerStatusNone;
}

- (void)willMoveToParentViewController:(UIViewController *)parent
{
    if (!parent) {
        self.playerStatus = PlayerStatusNone;
    }
}

#pragma mark - ActivityIndicator

- (void)activityIndicatorViewShown:(BOOL)shown
{
    if (shown) {
        [self.activityIndicatorView startAnimating];
    }
    
    [UIView animateWithDuration:0.15 animations:^{
        self.activityIndicatorContainer.alpha = shown ? 1. : 0.;
    } completion:^(BOOL finished) {
        if (!shown) {
            [self.activityIndicatorView stopAnimating];
        }
    }];
}

#pragma mark - Controls View

- (void)hideContolsViewAfterDelay
{
    [self cancelHideContolsViewAfterDelay];
    [self performSelector:@selector(hideContolsView)
               withObject:nil
               afterDelay:3.];
}

- (void)cancelHideContolsViewAfterDelay
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(hideContolsView)
                                               object:nil];
}

- (void)hideContolsView
{
    [self contolsViewShown:NO animated:YES];
}

- (void)contolsViewShown:(BOOL)shown animated:(BOOL)animated
{
    [UIView animateWithDuration:animated ? 0.3 : 0. animations:^{
        self.controlsView.alpha = shown ? 1. : 0.;
    }];
}

- (BOOL)isCotrolsViewShown
{
    return self.controlsView.alpha != 0.;
}

#pragma mark Control Button

- (IBAction)controlButtonCliced:(UIButton *)sender
{
    switch (self.playerStatus) {
        case PlayerStatusPlay:
            self.playerStatus = PlayerStatusPause;
            break;
        case PlayerStatusPause:
            self.playerStatus = PlayerStatusPlay;
            break;
        case PlayerStatusEnd:
            [self.player seekToTime:kCMTimeZero];
            [self contolsViewShown:NO animated:NO];
            self.playerStatus = PlayerStatusPlay;
            break;
        default:
            NSAssert(false, @"Unsupported playerStatus = %zd", self.playerStatus);
            break;
    }
}

- (void)syncControlButton
{
    switch (self.playerStatus) {
        case PlayerStatusPlay:
            [self.controlButton setImage:[YSVideoPlayerStyleKit imageOfPause] forState:UIControlStateNormal];
            break;
        case PlayerStatusEnd:
            [self.controlButton setImage:[YSVideoPlayerStyleKit imageOfReplay] forState:UIControlStateNormal];
            break;
        default:
            [self.controlButton setImage:[YSVideoPlayerStyleKit imageOfPlay] forState:UIControlStateNormal];
            break;
    }
}

#pragma mark Scrubber

- (void)syncScrubber
{
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration)) {
        self.scrubber.minimumValue = 0.;
        return;
    }
    
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration)) {
        float minValue = [self.scrubber minimumValue];
        float maxValue = [self.scrubber maximumValue];
        double time = CMTimeGetSeconds([self.player currentTime]);
        [self.scrubber setValue:(maxValue - minValue) * time / duration + minValue];
    }
}

- (IBAction)beginScrubbing:(UISlider *)sender
{
    [self activityIndicatorViewShown:YES];
    [self cancelHideContolsViewAfterDelay];
    [self removePlayerTimeObserver];
    
    self.restoreAfterScrubbingRate = self.player.rate;
    self.player.rate = 0.f;
}

- (IBAction)scrub:(UISlider *)sender
{
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration)) {
        return;
    }
    
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration)) {
        float minValue = [sender minimumValue];
        float maxValue = [sender maximumValue];
        float value = [sender value];
        
        Float64 time = duration * (value - minValue) / (maxValue - minValue);
        if (time < self.totalTime) {
            if (self.playerStatus == PlayerStatusEnd) {
                self.playerStatus = PlayerStatusPlay;
            }
        } else {
            time = self.totalTime;
        }
        
        [self updateTimeLabelWithTime:time];
        
            __weak typeof(self) wself = self;
        
        [self.player seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC) completionHandler:^(BOOL finished) {
            if (time == self.totalTime && wself.playerStatus != PlayerStatusEnd) {
                wself.playerStatus = PlayerStatusEnd;
            }
        }];
        
        if (time < self.totalTime) {
            [self activityIndicatorViewShown:YES];
        }
    }
}

- (IBAction)endScrubbing:(UISlider *)sender
{
    [self AddPlayerTimeObserver];
    
    if (self.restoreAfterScrubbingRate) {
        self.player.rate = self.restoreAfterScrubbingRate;
        self.restoreAfterScrubbingRate = 0.f;
    }
}

#pragma mark Gesture

- (IBAction)playerViewTapped:(UITapGestureRecognizer *)sender
{
    BOOL toggle = ![self isCotrolsViewShown];
    [self contolsViewShown:toggle animated:YES];
    
    if (toggle) {
        [self hideContolsViewAfterDelay];
    }
}

#pragma mark Time Label

- (void)syncTimeLabel
{
    [self updateTimeLabelWithTime:[self currentTime]];
}

- (void)updateTimeLabelWithTime:(Float64)time
{
    NSString *currentStr = [self timeStringFromTimeInterval:time];
    
    if (currentStr.length < self.totalTimeString.length) {
        while (currentStr.length < self.totalTimeString.length) {
            currentStr = [NSString stringWithFormat:@"0%@", currentStr];
        }
    }
    
    self.timeLabel.text = [NSString stringWithFormat:@"%@ / %@", currentStr, self.totalTimeString];
}

- (NSString *)timeStringFromTimeInterval:(NSTimeInterval)time
{
    return [NSString stringWithFormat:@"%li:%02li", lround(floor(time / 60.)), lround(floor(time)) % 60];
}

#pragma mark - Player View

- (YSEmbeddedVideoPlayerView *)playerView
{
    if (!self.isViewLoaded) [self view];
    return _playerView;
}

#pragma mark - Player

- (void)createPlayer
{
    [self activityIndicatorViewShown:YES];
    [self hideContolsView];
    
    self.player = nil;
    self.playerStatus = PlayerStatusWait;
    
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        AVPlayer *player = [[AVPlayer alloc] initWithURL:[NSURL URLWithString:wself.URLString]]; // High cost
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!wself || wself.playerStatus == PlayerStatusNone) return ;
            
            wself.player = player;
            [wself.playerView setPlayer:wself.player];
            
            [wself.KVOController observe:wself.player.currentItem
                                 keyPath:NSStringFromSelector(@selector(status))
                                 options:NSKeyValueObservingOptionNew
                                   block:^(id observer, id object, NSDictionary *change)
             {
                 NSInteger status = [change[NSKeyValueChangeNewKey] integerValue];
                 
                 switch (status) {
                     case AVPlayerStatusReadyToPlay:
                         [wself activityIndicatorViewShown:NO];
                         
                         if (!wself.scrubber.tracking && wself.playerStatus != PlayerStatusPause) {
                             [wself hideContolsViewAfterDelay];
                             [wself AddPlayerTimeObserver];
                             wself.playerStatus = PlayerStatusPlay;
                         }
                         break;
                     default:
                         wself.playerStatus = PlayerStatusError;
                         break;
                 }
             }];
            [wself.KVOController observe:wself.player
                                 keyPath:NSStringFromSelector(@selector(rate))
                                 options:NSKeyValueObservingOptionNew
                                   block:^(id observer, id object, NSDictionary *change)
             {
                 [wself syncControlButton];
             }];
            [[NSNotificationCenter defaultCenter] addObserver:wself
                                                     selector:@selector(playerDidPlayToEndTime:)
                                                         name:AVPlayerItemDidPlayToEndTimeNotification
                                                       object:wself.player.currentItem];
            
            wself.totalTime = CMTimeGetSeconds([wself.player currentItem].asset.duration);
            wself.totalTimeString = [wself timeStringFromTimeInterval:wself.totalTime];
            
            [wself.KVOController observe:wself.scrubber
                                 keyPath:NSStringFromSelector(@selector(value))
                                 options:NSKeyValueObservingOptionNew
                                   block:^(id observer, id object, NSDictionary *change)
             {
                 [wself syncTimeLabel];
             }];
        });
    });
}

- (void)setPlayerStatus:(PlayerStatus)playerStatus
{
    _playerStatus = playerStatus;
    [self cancelHideContolsViewAfterDelay];
    
    switch (playerStatus) {
        case PlayerStatusNone:
            [self removePlayerTimeObserver];
            [[NSNotificationCenter defaultCenter] removeObserver:self];
            [NSObject cancelPreviousPerformRequestsWithTarget:self];
            
            [self activityIndicatorViewShown:NO];
            self.playerView.hidden = YES;
            [self contolsViewShown:NO animated:NO];
            self.scrubber.enabled = NO;
            [self.player pause];
            self.player = nil;
            
            return;
        case PlayerStatusWait:
            self.scrubber.enabled = NO;
            self.playerView.hidden = YES;
            [self activityIndicatorViewShown:YES];
            break;
        case PlayerStatusPlay:
        {
            self.scrubber.enabled = YES;
            self.playerView.hidden = NO;
            [self activityIndicatorViewShown:NO];
            [self.player play];
            
            [self hideContolsViewAfterDelay];
            break;
        }
        case PlayerStatusPause:
            self.scrubber.enabled = YES;
            [self.player pause];
            break;
        case PlayerStatusEnd:
        {
            [self activityIndicatorViewShown:NO];
            [self contolsViewShown:YES animated:YES];
            break;
        }
        case PlayerStatusError:
            self.scrubber.enabled = NO;
            break;
        default:
            NSAssert(false, @"Unsupported playerStatus = %zd", playerStatus);
            return;
    }
    
    [self syncControlButton];
}

- (BOOL)isPlaying
{
    return self.restoreAfterScrubbingRate != 0.f || [self.player rate] != 0.f;
}

- (Float64)currentTime
{
    return CMTimeGetSeconds([self.player currentItem].currentTime);
}

- (CMTime)playerItemDuration
{
    AVPlayerItem *playerItem = [self.player currentItem];
    if (playerItem.status == AVPlayerItemStatusReadyToPlay) {
        return([playerItem duration]);
    }
    return(kCMTimeInvalid);
}

-(void)AddPlayerTimeObserver
{
    [self removePlayerTimeObserver];
    
    __weak typeof(self) wself = self;
    self.timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1)
                                                                  queue:dispatch_get_main_queue()
                                                             usingBlock:^(CMTime time)
                         {
                             [wself syncScrubber];
                         }];
}

- (void)removePlayerTimeObserver
{
    if (self.timeObserver) {
        [self.player removeTimeObserver:self.timeObserver];
        self.timeObserver = nil;
    }
}

#pragma mark - Notification

- (void)playerDidPlayToEndTime:(NSNotification *)note
{
    if (self.repeat) {
        [self.player seekToTime:kCMTimeZero];
        [self.player play];
        return;
    }
    
    self.playerStatus = PlayerStatusEnd;
}

@end
