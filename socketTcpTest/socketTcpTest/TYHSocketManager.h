//
//  TYHSocketManager.h
//  tcpTest
//
//  Created by yesway on 2017/2/17.
//  Copyright © 2017年 yesway. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TYHSocketManager : NSObject

+ (instancetype)share;

- (BOOL)connect;
- (void)disConnect;

- (void)sendMsg:(NSString *)msg;
- (void)pullTheMsg;

@end
