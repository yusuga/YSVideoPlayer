//
//  YSVideoPlayControl.m
//  YSVideoPlayer
//
//  Created by Yu Sugawara on 2015/12/16.
//  Copyright © 2015年 Yu Sugawara. All rights reserved.
//

#import "YSVideoPlayControl.h"
#import "YSVideoPlayerStyleKit.h"

@interface YSVideoPlayControl ()

@property (weak, nonatomic) IBOutlet UIButton *button;

@end

@implementation YSVideoPlayControl

- (instancetype)initWithTarget:(id)target
                        action:(SEL)action
              forControlEvents:(UIControlEvents)controlEvents
{
    UINib *nib = [UINib nibWithNibName:NSStringFromClass([self class]) bundle:nil];
    self = [[nib instantiateWithOwner:self options:nil] objectAtIndex:0];
    
    if (self) {
        [self.button setImage:[YSVideoPlayerStyleKit imageOfPlay] forState:UIControlStateNormal];
        [self.button addTarget:target action:action forControlEvents:controlEvents];        
    }
    
    return self;
}

@end
