//
//  YSEmbedVideoPlayer.m
//  YSVideoPlayer
//
//  Created by Yu Sugawara on 2015/11/25.
//  Copyright © 2015年 Yu Sugawara. All rights reserved.
//

#import "YSEmbedVideoPlayer.h"
@import AVFoundation;
@import CoreText;
#import <AFNetworking/AFNetworking.h>
#import <RMUniversalAlert/RMUniversalAlert.h>
#import <M13ProgressSuite/M13ProgressViewRing.h>
#import <KVOController/FBKVOController.h>
#import "YSVideoPlayerStyleKit.h"

typedef NS_ENUM(NSInteger, PlayerStatus) {
    PlayerStatusNone,
    PlayerStatusWait,
    PlayerStatusDowloading,
    PlayerStatusPlay,
    PlayerStatusBufferLoading,
    PlayerStatusPause,
    PlayerStatusEnd,
    PlayerStatusError,
};

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-function"
static NSString *NSStringFromPlayerStatus(PlayerStatus status)
{
    switch (status) {
        case PlayerStatusNone:
            return @"PlayerStatusNone";
        case PlayerStatusWait:
            return @"PlayerStatusWait";
        case PlayerStatusDowloading:
            return @"PlayerStatusDowloading";
        case PlayerStatusPlay:
            return @"PlayerStatusPlay";
        case PlayerStatusBufferLoading:
            return @"PlayerStatusBufferLoading";
        case PlayerStatusPause:
            return @"PlayerStatusPause";
        case PlayerStatusEnd:
            return @"PlayerStatusEnd";
        case PlayerStatusError:
            return @"PlayerStatusError";
            break;
        default:
            return [NSString stringWithFormat:@"Unknown playerStatus(%zd)", status];
            break;
    }
}
#pragma GCC diagnostic pop

static NSString * const kDownloadSchemeSuffix = @"-download";
static NSString * const kExtensionMP4 = @"mp4";
static NSString * const kCacheDirctory = @"com.yusuga.YSVideoPlayer";

@interface YSEmbedVideoPlayer () <AVAssetResourceLoaderDelegate>

@property (weak, nonatomic) IBOutlet UIView *activityIndicatorContainer;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorView;
@property (weak, nonatomic) IBOutlet UIButton *errorButton;

@property (weak, nonatomic) IBOutlet UIView *controlView;
@property (weak, nonatomic) IBOutlet UIButton *controlButton;

@property (weak, nonatomic) IBOutlet UIView *scrubbarView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UISlider *scrubbar;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

@property (copy, nonatomic) NSString *URLString;
@property (nonatomic) PHAsset *asset;
@property (nonatomic) PHImageRequestID assetRequestID;

@property (weak, nonatomic, readwrite) IBOutlet YSEmbedVideoPlayerView *playerView;
@property (nonatomic) AVPlayer *player;
@property (nonatomic) BOOL repeat;
@property (nonatomic) float restoreAfterScrubbingRate;
@property (nonatomic) Float64 totalTime;
@property (copy, nonatomic) NSString *totalTimeString;

@property (nonatomic) PlayerStatus playerStatus;
@property (nonatomic) id timeObserver;

@property (nonatomic) NSURLSessionDownloadTask *downloadTask;
@property (weak, nonatomic) IBOutlet UIView *downloadProgressContainer;
@property (weak, nonatomic) IBOutlet M13ProgressViewRing *downloadProgressView;
@property (nonatomic) NSError *downloadError;

@end

@implementation YSEmbedVideoPlayer

+ (YSEmbedVideoPlayer *)playerWithURLString:(NSString *)URLString
{
    return [self playerWithURLString:URLString
                              repeat:NO];
}

+ (YSEmbedVideoPlayer *)playerWithURLString:(NSString *)URLString
                                     repeat:(BOOL)repeat
{
    YSEmbedVideoPlayer *player = [self player];
    player.URLString = URLString;
    player.repeat = repeat;
    return player;
}

+ (YSEmbedVideoPlayer *)playerWithAsset:(PHAsset *)asset
{
    YSEmbedVideoPlayer *player = [self player];
    player.asset = asset;
    return player;
}

+ (YSEmbedVideoPlayer *)player
{
    UIStoryboard *sb = [UIStoryboard storyboardWithName:NSStringFromClass([self class]) bundle:nil];
    return [sb instantiateInitialViewController];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationWillResignActiveNotification:)
                                                     name:UIApplicationWillResignActiveNotification
                                                   object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    /* Error Button */
    
    {
        CGFloat horizontalSpace = 14.;
        
        UIButton *button = self.errorButton;
        [button setImage:[YSVideoPlayerStyleKit imageOfReload] forState:UIControlStateNormal];
        button.contentEdgeInsets = UIEdgeInsetsMake(5., horizontalSpace, 5., horizontalSpace);
        [button sizeToFit];
        
        CGFloat contentMargin = 2.;
        button.imageEdgeInsets = UIEdgeInsetsMake(1., -contentMargin, 0., contentMargin);
        button.titleEdgeInsets = UIEdgeInsetsMake(0., contentMargin, 0., -contentMargin);
        button.layer.cornerRadius = self.errorButton.bounds.size.height/2.;
        button.layer.borderWidth = 1.;
        button.layer.borderColor = [self.errorButton titleColorForState:UIControlStateNormal].CGColor;
        
        button.transform = CGAffineTransformMakeScale(-1., 1.);
        button.titleLabel.transform = CGAffineTransformMakeScale(-1., 1.);
        button.imageView.transform = CGAffineTransformMakeScale(-1., 1.);
    }
    
    /* Scrubber */
    __weak typeof(self) wself = self;
    [self.KVOController observe:self.scrubbar
                        keyPath:NSStringFromSelector(@selector(value))
                        options:NSKeyValueObservingOptionNew
                          block:^(id observer, id object, NSDictionary *change)
     {
         [wself syncTimeLabel];
     }];
    
    /*
     *  iOS 9 Proportional Numbers
     *  http://useyourloaf.com/blog/ios-9-proportional-numbers.html
     */
    NSDictionary * fontAttributes = @{UIFontDescriptorFeatureSettingsAttribute: @[@{UIFontFeatureTypeIdentifierKey: @(kNumberSpacingType),
                                                                                    UIFontFeatureSelectorIdentifierKey: @(kMonospacedNumbersSelector)}]};
    self.timeLabel.font = [UIFont fontWithDescriptor:[[self.timeLabel.font fontDescriptor] fontDescriptorByAddingAttributes:fontAttributes]
                                                size:self.timeLabel.font.pointSize];
    
    self.downloadProgressView.showPercentage = NO;
    self.downloadProgressView.primaryColor = [UIColor whiteColor];
    self.downloadProgressView.secondaryColor = [UIColor darkGrayColor];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self createPlayerItem];
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

#pragma mark - Application

- (void)applicationWillResignActiveNotification:(NSNotification *)note
{
    if (self.playerStatus == PlayerStatusPlay) {
        self.playerStatus = PlayerStatusPause;
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

- (BOOL)isActivityIndicatorViewShown
{
    return self.activityIndicatorContainer.alpha == 1.;
}

#pragma mark - Control view

- (NSArray *)controlViews
{
    return @[self.controlView, self.scrubbarView];
}

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
        for (UIView *view in [self controlViews]) {
            view.alpha = shown ? 1. : 0.;
        }
    }];
}

- (BOOL)isCotrolsViewShown
{
    return self.controlView.alpha != 0.;
}

#pragma mark Control Button

- (IBAction)controlButtonCliced:(UIButton *)sender
{
    switch (self.playerStatus) {
        case PlayerStatusPlay:
            self.playerStatus = PlayerStatusPause;
            break;
        case PlayerStatusBufferLoading:
        case PlayerStatusPause:
            [self hideContolsView];
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
        case PlayerStatusBufferLoading:
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
        self.scrubbar.minimumValue = 0.;
        return;
    }
    
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration)) {
        float minValue = [self.scrubbar minimumValue];
        float maxValue = [self.scrubbar maximumValue];
        double time = CMTimeGetSeconds([self.player currentTime]);
        [self.scrubbar setValue:(maxValue - minValue) * time / duration + minValue];
    }
}

- (IBAction)beginScrubbing:(UISlider *)sender
{
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
            if (self.playerStatus == PlayerStatusBufferLoading ||
                self.playerStatus == PlayerStatusEnd)
            {
                self.playerStatus = PlayerStatusPlay;
            }
        } else {
            time = self.totalTime;
        }
        
        [self updateTimeLabelWithTime:time];
        
        if (time != self.totalTime) {
            self.playerStatus = PlayerStatusBufferLoading;
        }
        
        __weak typeof(self) wself = self;
        [self.player seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC) completionHandler:^(BOOL finished) {
            if (([wself isCachedVideo] && finished)
                ||
                time == wself.totalTime)
            {
                [wself activityIndicatorViewShown:NO];
            }
            
            if (time == wself.totalTime && wself.playerStatus != PlayerStatusEnd) {
                wself.playerStatus = PlayerStatusEnd;
            }
        }];
    }
}

- (IBAction)endScrubbing:(UISlider *)sender
{
    [self addPlayerTimeObserver];
    
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

- (YSEmbedVideoPlayerView *)playerView
{
    if (!self.isViewLoaded) [self view];
    return _playerView;
}

#pragma mark - URL

- (NSURL *)videoURL
{
    if (!self.URLString) return nil;
    NSURL *URL = [NSURL URLWithString:self.URLString];
    
    if ([self.URLString.pathExtension isEqualToString:kExtensionMP4]) {
        NSURLComponents *components = [[NSURLComponents alloc] initWithURL:URL resolvingAgainstBaseURL:NO];
        components.scheme = [components.scheme stringByAppendingString:kDownloadSchemeSuffix];
        return components.URL;
    }
    return URL;
}

#pragma mark - Asset

- (void)requestAssetVideo
{
    __weak typeof(self) wself = self;
    self.assetRequestID = [[PHImageManager defaultManager] requestAVAssetForVideo:self.asset
                                                                          options:[self videoRequestOptions]
                                                                    resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info)
                           {
                               dispatch_async(dispatch_get_main_queue(), ^{
                                   if ([info[PHImageCancelledKey] boolValue]) return ;
                                   if (!wself || wself.playerStatus == PlayerStatusNone) return ;
                                   
                                   NSError *error   = [info objectForKey:PHImageErrorKey];
                                   //                                   NSString * title = CTAssetsPickerLocalizedString(@"Cannot Play Stream Video", nil);
                                   if (error) {
                                       [wself assetFailedToPrepareForPlayback:error];
                                   } else {
                                       [wself prepareToPlayAsset:asset withKeys:nil];
                                   }
                               });
                           }];
}

- (PHVideoRequestOptions *)videoRequestOptions
{
    PHVideoRequestOptions *options  = [PHVideoRequestOptions new];
    options.networkAccessAllowed    = YES;
    return options;
}

#pragma mark - Player Item

- (void)createPlayerItem
{
    [self activityIndicatorViewShown:YES];
    [self hideContolsView];
    
    self.playerStatus = PlayerStatusWait;
    
    if (self.URLString) {
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[self videoURL] options:nil];
        [asset.resourceLoader setDelegate:self queue:dispatch_get_main_queue()];
        
        NSArray *requestedKeys = @[@"playable"];
        
        /* Tells the asset to load the values of any of the specified keys that are not already loaded. */
        __weak typeof(self) wself = self;
        [asset loadValuesAsynchronouslyForKeys:requestedKeys completionHandler:^{
            dispatch_async( dispatch_get_main_queue(), ^{
                if (!wself || wself.playerStatus == PlayerStatusNone) return ;
                
                /* IMPORTANT: Must dispatch to main queue in order to operate on the AVPlayer and AVPlayerItem. */
                [wself prepareToPlayAsset:asset withKeys:requestedKeys];
            });
        }];
    } else if (self.asset) {
        [self requestAssetVideo];
    } else {
        NSAssert(false, @"Unsupported flow");
        self.playerStatus = PlayerStatusError;
    }
}

- (void)prepareToPlayAsset:(AVAsset *)asset withKeys:(NSArray *)requestedKeys
{
    for (NSString *thisKey in requestedKeys) {
        NSError *error = nil;
        AVKeyValueStatus keyStatus = [asset statusOfValueForKey:thisKey error:&error];
        if (keyStatus == AVKeyValueStatusFailed) {
            [self assetFailedToPrepareForPlayback:error];
            return;
        }
        /* If you are also implementing -[AVAsset cancelLoading], add your code here to bail out properly in the case of cancellation. */
    }
    
    /* Use the AVAsset playable property to detect whether the asset can be played. */
    if (!asset.playable) {
        /* Generate an error describing the failure. */
        NSString *localizedDescription = NSLocalizedString(@"Item cannot be played", @"Item cannot be played description");
        NSString *localizedFailureReason = NSLocalizedString(@"The assets tracks were loaded, but could not be made playable.", @"Item cannot be played failure reason");
        
        NSError *assetCannotBePlayedError = [NSError errorWithDomain:@"com.yusuga.YSVideoPlayer"
                                                                code:0
                                                            userInfo:@{NSLocalizedDescriptionKey : localizedDescription,
                                                                       NSLocalizedFailureReasonErrorKey : localizedFailureReason}];
        
        /* Display the error to the user. */
        [self assetFailedToPrepareForPlayback:assetCannotBePlayedError];
        return;
    }
    
    __weak typeof(self) wself = self;
    
    /* PlayerItem */
    
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
    
    self.totalTime = CMTimeGetSeconds(asset.duration);
    self.totalTimeString = [self timeStringFromTimeInterval:self.totalTime];
    
    [self.KVOController observe:playerItem
                        keyPath:NSStringFromSelector(@selector(status))
                        options:NSKeyValueObservingOptionNew
                          block:^(id observer, id object, NSDictionary *change)
     {
         AVPlayerItemStatus status = [change[NSKeyValueChangeNewKey] integerValue];
         
         switch (status) {
             default:
             case AVPlayerItemStatusUnknown:
                 wself.playerStatus = PlayerStatusNone;
                 break;
             case AVPlayerItemStatusReadyToPlay:
                 if (!wself.scrubbar.tracking && wself.playerStatus != PlayerStatusPause) {
                     [wself hideContolsViewAfterDelay];
                     [wself addPlayerTimeObserver];
                     wself.playerStatus = PlayerStatusPlay;
                 }
                 break;
             case AVPlayerItemStatusFailed:
             {
                 AVPlayerItem *item = (AVPlayerItem *)object;
                 NSError *error = nil;
                 if ([item isKindOfClass:[AVPlayerItem class]]) {
                     error = item.error;
                 }
                 [wself assetFailedToPrepareForPlayback:error];
                 break;
             }
         }
     }];
    
    [self.KVOController observe:playerItem
                        keyPath:@"playbackBufferEmpty"
                        options:NSKeyValueObservingOptionNew
                          block:^(id observer, id object, NSDictionary *change)
     {
         if (wself.playerStatus == PlayerStatusPlay) {
             wself.playerStatus = PlayerStatusBufferLoading;
         }
     }];
    [self.KVOController observe:playerItem
                        keyPath:@"playbackLikelyToKeepUp"
                        options:NSKeyValueObservingOptionNew
                          block:^(id observer, id object, NSDictionary *change)
     {
         if (wself.playerStatus == PlayerStatusBufferLoading) {
             wself.playerStatus = PlayerStatusPlay;
         }
     }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerDidPlayToEndTime:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:playerItem];
    
    /* Player */
    
    if (!self.player) {
        self.player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
        
        [self.KVOController observe:self.player
                            keyPath:NSStringFromSelector(@selector(rate))
                            options:NSKeyValueObservingOptionNew
                              block:^(id observer, id object, NSDictionary *change)
         {
             [wself syncControlButton];
         }];
    }
    
    [self.playerView setPlayer:self.player];
}

-(void)assetFailedToPrepareForPlayback:(NSError *)error
{
    NSError *displayedError = self.downloadError ?: error;
    if (displayedError) {
        [RMUniversalAlert showAlertInViewController:self
                                          withTitle:displayedError.localizedDescription
                                            message:displayedError.localizedFailureReason
                                  cancelButtonTitle:@"OK"
                             destructiveButtonTitle:nil
                                  otherButtonTitles:nil
                                           tapBlock:nil];
    }
    
    self.playerStatus = PlayerStatusError;
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

#pragma mark - Player

- (void)setPlayerStatus:(PlayerStatus)playerStatus
{
    _playerStatus = playerStatus;
    [self cancelHideContolsViewAfterDelay];
    
    switch (playerStatus) {
        case PlayerStatusNone:
            [self activityIndicatorViewShown:NO];
            [self.downloadProgressView setProgress:0. animated:NO];
            self.downloadProgressContainer.hidden = YES;
            self.errorButton.hidden = YES;
            self.playerView.hidden = YES;
            [self contolsViewShown:NO animated:NO];
            
            [self cleanPlayer];
            return;
        case PlayerStatusWait:
            [self activityIndicatorViewShown:YES];
            [self.downloadProgressView setProgress:0. animated:NO];
            self.downloadProgressContainer.hidden = YES;
            self.errorButton.hidden = YES;
            self.playerView.hidden = YES;
            [self contolsViewShown:NO animated:NO];
            break;
        case PlayerStatusDowloading:
            [self activityIndicatorViewShown:NO];
            self.downloadProgressContainer.hidden = NO;
            self.errorButton.hidden = YES;
            self.playerView.hidden = YES;
            [self contolsViewShown:NO animated:NO];
            break;
        case PlayerStatusPlay:
        {
            [self.downloadProgressView setProgress:0. animated:NO];
            self.downloadProgressContainer.hidden = YES;
            self.errorButton.hidden = YES;
            self.playerView.hidden = NO;
            [self hideContolsViewAfterDelay];
            
            [self.player play];
            break;
        }
        case PlayerStatusBufferLoading:
            [self activityIndicatorViewShown:YES];
            [self.downloadProgressView setProgress:0. animated:NO];
            self.downloadProgressContainer.hidden = YES;
            self.errorButton.hidden = YES;
            self.playerView.hidden = NO;
            break;
        case PlayerStatusPause:
            self.errorButton.hidden = YES;
            
            [self.player pause];
            break;
        case PlayerStatusEnd:
        {
            [self activityIndicatorViewShown:NO];
            [self.downloadProgressView setProgress:0. animated:NO];
            self.downloadProgressContainer.hidden = YES;
            self.errorButton.hidden = YES;
            [self contolsViewShown:YES animated:YES];
            break;
        }
        case PlayerStatusError:
            [self activityIndicatorViewShown:NO];
            [self.downloadProgressView setProgress:0. animated:NO];
            self.downloadProgressContainer.hidden = YES;
            self.errorButton.hidden = NO;
            self.playerView.hidden = YES;
            [self contolsViewShown:NO animated:NO];
            
            [self cleanPlayer];
            break;
        default:
            NSAssert(false, @"Unsupported playerStatus = %zd", playerStatus);
            return;
    }
    
    [self syncControlButton];
}

- (void)cleanPlayer
{
    [self.KVOController unobserveAll];
    [self removePlayerTimeObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVPlayerItemDidPlayToEndTimeNotification
                                                  object:self.player.currentItem];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    [self.downloadTask cancel];
    self.downloadTask = nil;
    self.downloadError = nil;
    
    if (self.assetRequestID) {
        [[PHImageManager defaultManager] cancelImageRequest:self.assetRequestID];
    }
    
    [self.playerView setPlayer:nil];
    
    [self.player pause];
    self.player = nil;
}

- (BOOL)isPlaying
{
    return self.restoreAfterScrubbingRate != 0.f || [self.player rate] != 0.f;
}

-(void)addPlayerTimeObserver
{
    [self removePlayerTimeObserver];
    
    __weak typeof(self) wself = self;
    self.timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1)
                                                                  queue:dispatch_get_main_queue()
                                                             usingBlock:^(CMTime time)
                         {
                             if (wself.playerStatus == PlayerStatusPlay && [wself isActivityIndicatorViewShown]) {
                                 [wself activityIndicatorViewShown:NO];
                             }
                             
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

#pragma mark - Error

- (IBAction)errorButtonClicked:(id)sender
{
    [self createPlayerItem];
}

#pragma mark - AVPlayerItem Notification

- (void)playerDidPlayToEndTime:(NSNotification *)note
{
    if (self.repeat) {
        [self.player seekToTime:kCMTimeZero];
        [self.player play];
        return;
    }
    
    self.playerStatus = PlayerStatusEnd;
}

#pragma mark - AVAssetResourceLoaderDelegate

- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest
{
    NSURL *URL = loadingRequest.request.URL;
    if (![URL.scheme hasSuffix:kDownloadSchemeSuffix]) return NO;
    
    if ([self isCachedVideo]) {
        [self downloadCompletionWithLoadingRequest:loadingRequest];
        return YES;
    }
    
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:loadingRequest.request.URL resolvingAgainstBaseURL:NO];
    components.scheme = [components.scheme stringByReplacingOccurrencesOfString:kDownloadSchemeSuffix withString:@""];
    [self downloadWithLoadingRequest:loadingRequest URL:components.URL];
    return YES;
}

#pragma mark - Download

- (void)downloadWithLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest URL:(NSURL *)URL
{
    AFHTTPSessionManager *session = [AFHTTPSessionManager manager];
    NSProgress *progress;
    
    __weak typeof(self) wself = self;
    NSURLSessionDownloadTask *downloadTask;
    downloadTask = [session downloadTaskWithRequest:[NSURLRequest requestWithURL:URL]
                                           progress:&progress
                                        destination:^NSURL *(NSURL *targetPath, NSURLResponse *response)
                    {
                        return [wself cachedVideoFileURL];
                    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
                        
                        dispatch_async(dispatch_get_main_queue(), ^(void){
                            
                            [wself.KVOController unobserve:progress
                                                   keyPath:NSStringFromSelector(@selector(fractionCompleted))];
                            
                            if (error) {
                                if (![error.domain isEqualToString:NSURLErrorDomain] ||
                                    error.code != NSURLErrorCancelled)
                                {
                                    wself.downloadError = error;
                                }
                                [loadingRequest finishLoadingWithError:error];
                                return ;
                            }
                            
                            [wself downloadCompletionWithLoadingRequest:loadingRequest];
                        });
                    }];
    
    self.playerStatus = PlayerStatusDowloading;
    
    [self.KVOController observe:progress
                        keyPath:NSStringFromSelector(@selector(fractionCompleted))
                        options:NSKeyValueObservingOptionNew
                          block:^(id observer, id object, NSDictionary *change)
     {
         CGFloat progress = ((CGFloat)downloadTask.countOfBytesReceived)/((CGFloat)downloadTask.countOfBytesExpectedToReceive);
         dispatch_async(dispatch_get_main_queue(), ^{
             [wself.downloadProgressView setProgress:progress
                                            animated:NO];
         });
     }];
    
    [self.downloadTask cancel];
    [downloadTask resume];
    self.downloadTask = downloadTask;
}

- (void)downloadCompletionWithLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    NSURL *videoURL = [self cachedVideoFileURL];
    NSData *data = [[NSFileManager defaultManager] contentsAtPath:videoURL.path];
    NSData *requestedData = [data subdataWithRange:NSMakeRange((NSUInteger)loadingRequest.dataRequest.requestedOffset,
                                                               (NSUInteger)loadingRequest.dataRequest.requestedLength)];
    
    AVAssetResourceLoadingContentInformationRequest *info = loadingRequest.contentInformationRequest;
    info.contentType = CFBridgingRelease((UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)videoURL.pathExtension, NULL)));
    info.contentLength = data.length;
    info.byteRangeAccessSupported = YES;
    
    [loadingRequest.dataRequest respondWithData:requestedData];
    [loadingRequest finishLoading];
}

#pragma mark - Cache

+ (NSURL *)cacheDirecotryFileURL
{
    NSURL *dir = [NSURL fileURLWithPath:[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject]];
    dir = [dir URLByAppendingPathComponent:kCacheDirctory];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:dir.path]) {
        NSError *error = nil;
        [fileManager createDirectoryAtPath:dir.path
               withIntermediateDirectories:NO
                                attributes:nil
                                     error:&error];
        NSLog(@"%s, error = %@", __func__, error);
    }
    
    return dir;
}

- (NSURL *)cachedVideoFileURL
{
    if (!self.URLString) return nil;
    return [[[self class] cacheDirecotryFileURL] URLByAppendingPathComponent:self.URLString.lastPathComponent];
}

- (BOOL)isCachedVideo
{
    NSURL *URL = [self cachedVideoFileURL];
    return URL ? [[NSFileManager defaultManager] fileExistsAtPath:URL.path] : NO;
}

+ (void)deleteDiskCache
{
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtURL:[self cacheDirecotryFileURL] error:&error];
    if (error) NSLog(@"%s, error = %@", __func__, error);
}

+ (void)cleanDiskCache
{
    [self cleanDiskCacheWithMaxCacheAge:60*60*24];
}

+ (void)cleanDiskCacheWithMaxCacheAge:(NSInteger)maxCacheAge
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSURL *cacheDirURL = [self cacheDirecotryFileURL];
    NSArray *resourceKeys = @[NSURLIsDirectoryKey, NSURLContentModificationDateKey];
    
    NSError *error = nil;
    NSArray<NSURL *> *contents = [fileManager contentsOfDirectoryAtURL:cacheDirURL
                                            includingPropertiesForKeys:resourceKeys
                                                               options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                 error:&error];
    if (error) {
        NSLog(@"%s(%d), error = %@", __func__, __LINE__, error);
        return;
    }
    
    contents = [contents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"!(%K IN %@)", NSStringFromSelector(@selector(pathExtension)), [self ignoreDiskCacheExtensions]]];
    
    NSDate *expirationDate = [NSDate dateWithTimeIntervalSinceNow:-maxCacheAge];
    
    NSMutableArray *urlsToDelete = [[NSMutableArray alloc] init];
    for (NSURL *fileURL in contents) {
        NSDictionary *resourceValues = [fileURL resourceValuesForKeys:resourceKeys error:NULL];
        
        if ([resourceValues[NSURLIsDirectoryKey] boolValue]) return;
        
        NSDate *modificationDate = resourceValues[NSURLContentModificationDateKey];
        if ([[modificationDate laterDate:expirationDate] isEqualToDate:expirationDate]) {
            [urlsToDelete addObject:fileURL];
            continue;
        }
    }
    
    for (NSURL *fileURL in urlsToDelete) {
        NSError *error = nil;
        [fileManager removeItemAtURL:fileURL error:&error];
        if (error) NSLog(@"%s(%d), error = %@", __func__, __LINE__, error);
    }
}

+ (NSArray *)ignoreDiskCacheExtensions
{
    return @[@"db", @"db-shm", @"db-wal"];
}

@end
