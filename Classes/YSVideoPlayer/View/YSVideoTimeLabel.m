//
//  YSVideoTimeLabel.m
//  YSVideoPlayer
//
//  Created by Yu Sugawara on 2015/12/17.
//  Copyright © 2015年 Yu Sugawara. All rights reserved.
//

#import "YSVideoTimeLabel.h"

@implementation YSVideoTimeLabel

- (CGSize)intrinsicContentSize
{
    CGSize size = [super intrinsicContentSize];
    return CGSizeMake(self.intrinsicContentWidth ?: size.width, size.height);
}

@end
