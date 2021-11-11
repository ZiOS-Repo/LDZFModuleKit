//
//  IUAppDelegate.m
//  LDZFModuleKit
//
//  Created by zhuyuhui434@gmail.com on 11/11/2021.
//  Copyright (c) 2021 zhuyuhui434@gmail.com. All rights reserved.
//

#import "IUAppDelegate.h"
#import <LDZFModuleKit/LDZFModuleKit.h>
@implementation IUAppDelegate

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id> *)launchOptions {
    [[LDZFModuleManager sharedInstance] loadModulesWithPlistFileName:@"modulesList"];
    return YES;
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [[LDZFModuleManager sharedInstance] application:application didFinishLaunchingWithOptions:launchOptions];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    [[LDZFModuleManager sharedInstance] applicationWillResignActive:application];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [[LDZFModuleManager sharedInstance] applicationDidEnterBackground:application];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [[LDZFModuleManager sharedInstance] applicationWillEnterForeground:application];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [[LDZFModuleManager sharedInstance] applicationDidBecomeActive:application];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [[LDZFModuleManager sharedInstance] applicationWillTerminate:application];
}

//说明：UNIVERSIAL LINK 唤醒 app
- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler API_AVAILABLE(ios(8.0)){
    BOOL isRespond = [[LDZFModuleManager sharedInstance] application:application continueUserActivity:userActivity restorationHandler:restorationHandler];
    if (isRespond) {
        return YES;
    }
    return NO;
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options API_AVAILABLE(ios(9.0)) {
    if (!url) {
        return NO;
    }
    BOOL isRespond = [[LDZFModuleManager sharedInstance] application:app openURL:url options:options];
    if (isRespond) {
        return YES;
    }
    return NO;
}

@end
