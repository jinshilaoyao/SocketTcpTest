//
//  ViewController.m
//  socketTcpTest
//
//  Created by yesway on 2017/2/17.
//  Copyright © 2017年 yesway. All rights reserved.
//

#import "ViewController.h"
#import "TYHSocketManager.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    TYHSocketManager * manager = [TYHSocketManager share];
    [manager connect];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    [[TYHSocketManager share] sendMsg:@"aaa"];
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
