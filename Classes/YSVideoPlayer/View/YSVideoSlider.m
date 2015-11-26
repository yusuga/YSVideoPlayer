//
//  YSVideoSlider.m
//  YSVideoPlayer
//
//  Created by Yu Sugawara on 2015/11/26.
//  Copyright © 2015年 Yu Sugawara. All rights reserved.
//

#import "YSVideoSlider.h"
#import "YSVideoPlayerStyleKit.h"

@implementation YSVideoSlider

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self setThumbImage:[YSVideoPlayerStyleKit imageOfSliderThumb]
                   forState:UIControlStateNormal];
        
    }
    return self;
}

- (BOOL) beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    return YES;
}

@end
