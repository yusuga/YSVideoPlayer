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
        self.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self.button setImage:[YSVideoPlayerStyleKit imageOfPlay] forState:UIControlStateNormal];
        [self.button addTarget:target action:action forControlEvents:controlEvents];
        
        [self addConstraints:@[[NSLayoutConstraint constraintWithItem:self
                                                            attribute:NSLayoutAttributeWidth
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:nil
                                                              attribute:NSLayoutAttributeWidth
                                                             multiplier:1.
                                                               constant:self.bounds.size.width],
                                 [NSLayoutConstraint constraintWithItem:self
                                                              attribute:NSLayoutAttributeHeight
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:nil
                                                              attribute:NSLayoutAttributeHeight
                                                             multiplier:1.
                                                               constant:self.bounds.size.height]]];
        [self setNeedsUpdateConstraints];
    }
    
    return self;
}

@end
