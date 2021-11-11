//
//  ShareModule.m
//  LDZFModuleKit_Example
//
//  Created by zhuyuhui on 2021/11/11.
//  Copyright © 2021 zhuyuhui434@gmail.com. All rights reserved.
//

#import "ShareModule.h"

@implementation ShareModule
@synthesize moduleParameters;
@synthesize moduleName;
@synthesize moduleID;
@synthesize moduleLevel;


///实现模块注册方法
- (void)moduleRegisterWithCompletionHandler:(LDZFModuleRegisterCompletionHandler _Nullable)completionHandler {
    NSLog(@"self.moduleParameters:\n%@",self.moduleParameters);
//    NSString *qqKey = [NSString stringWithFormat:@"%@",self.moduleParameters[@"QQKey"]];
//    NSString *weixinKey = [NSString stringWithFormat:@"%@",self.moduleParameters[@"WeixinKey"]];
//    NSString *weiboKey = [NSString stringWithFormat:@"%@",self.moduleParameters[@"WeiboKey"]];
//    NSString *qqUniversalLink = [NSString stringWithFormat:@"%@",self.moduleParameters[@"QQUniversalLink"]];
//    NSString *weixinUniversalLink = [NSString stringWithFormat:@"%@",self.moduleParameters[@"WeixinUniversalLink"]];
//    NSString *weiboUniversalLink = [NSString stringWithFormat:@"%@",self.moduleParameters[@"WeiboUniversalLink"]];
    
}

///实现模块注销方法
- (void)moduleUnregisterWithCompletionHandler:(LDZFModuleUnregisterCompletionHandler _Nullable)completionHandler {
    
}

@end
