//
//  TableViewController.m
//  YSVideoPlayer
//
//  Created by Yu Sugawara on 2015/11/20.
//  Copyright © 2015年 Yu Sugawara. All rights reserved.
//

#import "TableViewController.h"
#import "YSVideoPlayer.h"

@interface TableViewController ()

@end

@implementation TableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *URLStr = @"https://v.cdn.vine.co/r/videos/A26C12B1571095786971898712064_2fa1684e138.0.3.18007175599737831424.mp4";
    
    switch (indexPath.row) {
        case 0:
            [YSVideoPlayer presentFromViewController:self
                                       withURLString:URLStr
                                              repeat:NO];
            break;
        case 1:
            [YSVideoPlayer presentFromViewController:self
                                       withURLString:URLStr
                                              repeat:YES];
            break;
        default:
            break;
    }
}

@end
