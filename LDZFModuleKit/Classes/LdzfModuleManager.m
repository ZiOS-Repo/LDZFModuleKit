//
//  LdzfModuleManager.m
//  Pods
//
//  Created by zhuyuhui on 2021/11/11.
//

#import "LdzfModuleManager.h"

@interface LdzfModuleManager()
@property(nonatomic, strong) NSMutableArray *appEventModules;
@end

@implementation LdzfModuleManager
+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static LdzfModuleManager *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[super allocWithZone:NULL] init];
    });
    return instance;
}

+ (id)allocWithZone:(struct _NSZone *)zone {
    return [self sharedInstance];
}

/**
 按照plist文件配置加载模块

 @param plistFileName 文件名称
 */
- (void)loadModulesWithPlistFileName:(NSString *_Nonnull)plistFileName {
    //获取plist文件
    NSURL *URL = [[NSBundle mainBundle] URLForResource:plistFileName withExtension:@"plist"];
    //plist 文件为字典类型
    NSDictionary *modulesInfo = [NSDictionary dictionaryWithContentsOfURL:URL];
    
    for (NSString *moduleName in modulesInfo.allKeys) {
        if (moduleName) {
            NSDictionary *modInfo = [modulesInfo objectForKey:moduleName];
            NSString *moduleClass = [modInfo objectForKey:LDZFModuleClassKey];
            NSString *moduleID = [modInfo objectForKey:LDZFModuleIDKey];
            NSNumber *moduleLevel = [modInfo objectForKey:LDZFModuleLevelKey];
            NSDictionary *moduleParameters = [modInfo objectForKey:LDZFModuleParametersKey];
            Class moduleCls = NSClassFromString(moduleClass);
            if (moduleCls && [moduleCls conformsToProtocol:@protocol(LDZFModule)]) {
                id<LDZFModule> moduleInstance = [[moduleCls alloc] init];
                moduleInstance.moduleID = moduleID;
                moduleInstance.moduleName = moduleName;
                moduleInstance.moduleLevel = moduleLevel;
                moduleInstance.moduleParameters = moduleParameters;
                [self.appEventModules addObject:moduleInstance];
            }
        }
    }
    /// 排序
    [self sortModules];
    /// 注册
    [self registerModules];
}

- (void)sortModules {
    [self.appEventModules sortUsingComparator:^NSComparisonResult(id<LDZFModule> module1, id<LDZFModule> module2) {
        NSNumber *module1Level = (NSNumber *)module1.moduleLevel;
        NSNumber *module2Level =  (NSNumber *)module2.moduleLevel;
        //此处的规则含义为：若前一元素比后一元素小，则返回降序（即后一元素在前，为从大到小排列）
        if ([module1Level integerValue] < [module2Level integerValue]) {
            return NSOrderedDescending;
        } else {
            return NSOrderedAscending;
        }
    }];
}

- (void)registerModules {
    for (id<LDZFModule> module in self.appEventModules) {
        [module moduleRegisterWithCompletionHandler:nil];
        NSLog(@"模块注册:[%@]",module.moduleName);
    }
}


- (NSArray<id<LDZFModule>> * _Nonnull)allModules {
    return self.appEventModules.copy;
}

- (NSArray * _Nonnull)allModuleIDs {
    NSMutableArray *tmpMarr = [NSMutableArray array];
    for (id<LDZFModule> module in self.appEventModules) {
        [tmpMarr addObject:module.moduleID];
    }
    return tmpMarr.copy;
}

- (void)addModule:(id<LDZFModule> _Nonnull)module {
    [self removeModule:module];
    [self.appEventModules addObject:module];
    [self sortModules];
    ///模块注册
    [module moduleRegisterWithCompletionHandler:nil];
    NSLog(@"模块注册:[%@]",module.moduleName);
}

- (void)removeModule:(id<LDZFModule> _Nonnull)module {
    [self removeModuleWithID:module.moduleID];
}

- (void)removeModuleWithID:(NSString * _Nonnull)moduleID {
    for (id<LDZFModule> module in self.appEventModules) {
        if ([moduleID isEqualToString:module.moduleID]) {
            [module moduleUnregisterWithCompletionHandler:nil];
            [self.appEventModules removeObject:module];
        }
    }
}


- (NSMutableArray *)appEventModules {
    if (!_appEventModules) {
        _appEventModules = [NSMutableArray array];
    }
    return _appEventModules;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

#pragma mark - UIApplicationDelegate
#pragma mark - 初始化app
- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id> *)launchOptions {
    BOOL flag = YES;
    for (id<LDZFModule> module in self.appEventModules) {
        if (![module respondsToSelector:@selector(application:willFinishLaunchingWithOptions:)]) continue;
        flag = flag && [module application:application willFinishLaunchingWithOptions:launchOptions];
    }
    return flag;
}
// 当应用程序启动完毕的时候就会调用(系统自动调用)
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id> *)launchOptions {
    BOOL flag = YES;
    for (id<LDZFModule> module in self.appEventModules) {
        if (![module respondsToSelector:@selector(application:didFinishLaunchingWithOptions:)]) continue;
        flag = flag && [module application:application didFinishLaunchingWithOptions:launchOptions];
    }
    return flag;
}

- (void)applicationDidFinishLaunching:(UIApplication *)application {
    for (id<LDZFModule> module in self.appEventModules) {
        if (![module respondsToSelector:@selector(applicationDidFinishLaunching:)]) continue;
        [module applicationDidFinishLaunching:application];
    }
}

#pragma mark - 响应app的生命事件
//说明：当程序从后台将要重新回到前台时候调用
- (void)applicationWillEnterForeground:(UIApplication *)application API_AVAILABLE(ios(4.0)){
    for (id<LDZFModule> module in self.appEventModules) {
        if (![module respondsToSelector:@selector(applicationWillEnterForeground:)]) continue;
        [module applicationWillEnterForeground:application];
    }
}

// 重新获取焦点(能够和用户交互)
- (void)applicationDidBecomeActive:(UIApplication *)application {
    for (id<LDZFModule> module in self.appEventModules) {
        if (![module respondsToSelector:@selector(applicationDidBecomeActive:)]) continue;
        [module applicationDidBecomeActive:application];
    }
}

// 即将失去活动状态的时候调用(失去焦点, 不可交互)
- (void)applicationWillResignActive:(UIApplication *)application {
    for (id<LDZFModule> module in self.appEventModules) {
        if (![module respondsToSelector:@selector(applicationWillResignActive:)]) continue;
        [module applicationWillResignActive:application];
    }
}

// 应用程序进入后台的时候调用
- (void)applicationDidEnterBackground:(UIApplication *)application API_AVAILABLE(ios(4.0)){
    for (id<LDZFModule> module in self.appEventModules) {
        if (![module respondsToSelector:@selector(applicationDidEnterBackground:)]) continue;
        [module applicationDidEnterBackground:application];
    }
}



// 应用程序即将被销毁的时候会调用该方法
- (void)applicationWillTerminate:(UIApplication *)application {
    for (id<LDZFModule> module in self.appEventModules) {
        if (![module respondsToSelector:@selector(applicationWillTerminate:)]) continue;
        [module applicationWillTerminate:application];
    }
}

#pragma mark - 响应环境的改变
- (void)applicationProtectedDataWillBecomeUnavailable:(UIApplication *)application {
    for (id<LDZFModule> module in self.appEventModules) {
        if (![module respondsToSelector:@selector(applicationProtectedDataWillBecomeUnavailable:)]) continue;
        [module applicationProtectedDataWillBecomeUnavailable:application];
    }
}

- (void)applicationProtectedDataDidBecomeAvailable:(UIApplication *)application {
    for (id<LDZFModule> module in self.appEventModules) {
        if (![module respondsToSelector:@selector(applicationProtectedDataDidBecomeAvailable:)]) continue;
        [module applicationProtectedDataDidBecomeAvailable:application];
    }
}

// 应用程序接收到内存警告的时候就会调用
- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    for (id<LDZFModule> module in self.appEventModules) {
        if (![module respondsToSelector:@selector(applicationDidReceiveMemoryWarning:)]) continue;
        [module applicationDidReceiveMemoryWarning:application];
    }
}

- (void)applicationSignificantTimeChange:(UIApplication *)application {
    for (id<LDZFModule> module in self.appEventModules) {
        if (![module respondsToSelector:@selector(applicationSignificantTimeChange:)]) continue;
        [module applicationSignificantTimeChange:application];
    }
}

#pragma mark - 管理app的状态恢复
- (BOOL)application:(UIApplication *)application shouldSaveApplicationState:(NSCoder *)coder API_DEPRECATED("Use application:shouldSaveSecureApplicationState: instead", ios(6.0, 13.2)){
    BOOL flag = YES;
    for (id<LDZFModule> module in self.appEventModules) {
        if (![module respondsToSelector:@selector(application:shouldSaveApplicationState:)]) continue;
        flag = flag && [module application:application shouldSaveApplicationState:coder];
    }
    return flag;
}

- (BOOL)application:(UIApplication *)application shouldSaveSecureApplicationState:(NSCoder *)coder API_AVAILABLE(ios(13.2)) {
    BOOL flag = YES;
    for (id<LDZFModule> module in self.appEventModules) {
        if (![module respondsToSelector:@selector(application:shouldSaveSecureApplicationState:)]) continue;
        flag = flag && [module application:application shouldSaveSecureApplicationState:coder];
    }
    return flag;
}


- (BOOL)application:(UIApplication *)application shouldRestoreApplicationState:(NSCoder *)coder API_DEPRECATED("Use application:shouldRestoreSecureApplicationState: instead", ios(6.0, 13.2)) {
    BOOL flag = YES;
    for (id<LDZFModule> module in self.appEventModules) {
        if (![module respondsToSelector:@selector(application:shouldRestoreApplicationState:)]) continue;
        flag = flag && [module application:application shouldRestoreApplicationState:coder];
    }
    return flag;
}

- (BOOL)application:(UIApplication *)application shouldRestoreSecureApplicationState:(nonnull NSCoder *)coder API_AVAILABLE(ios(13.2)){
    BOOL flag = YES;
    for (id<LDZFModule> module in self.appEventModules) {
        if (![module respondsToSelector:@selector(application:shouldRestoreSecureApplicationState:)]) continue;
        flag = flag && [module application:application shouldRestoreSecureApplicationState:coder];
    }
    return flag;
}

- (nullable UIViewController *)application:(UIApplication *)application viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder API_AVAILABLE(ios(6.0)){
    UIViewController *viewController = nil;
    for (id<LDZFModule> module in self.appEventModules) {
        if (![module respondsToSelector:@selector(application:viewControllerWithRestorationIdentifierPath:coder:)]) continue;
        viewController = [module application:application viewControllerWithRestorationIdentifierPath:identifierComponents coder:coder]?:viewController;
    }
    return viewController;
}

- (void)application:(UIApplication *)application willEncodeRestorableStateWithCoder:(NSCoder *)coder API_AVAILABLE(ios(6.0)){
    for (id<LDZFModule> module in self.appEventModules) {
        if (![module respondsToSelector:@selector(application:willEncodeRestorableStateWithCoder:)]) continue;
        [module application:application willEncodeRestorableStateWithCoder:coder];
    }
}

- (void)application:(UIApplication *)application didDecodeRestorableStateWithCoder:(NSCoder *)coder API_AVAILABLE(ios(6.0)) {
    for (id<LDZFModule> module in self.appEventModules) {
        if (![module respondsToSelector:@selector(application:didDecodeRestorableStateWithCoder:)]) continue;
        [module application:application didDecodeRestorableStateWithCoder:coder];
    }
}

#pragma mark - 在后台状态时下载数据
- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler NS_SWIFT_DISABLE_ASYNC API_DEPRECATED("Use a BGAppRefreshTask in the BackgroundTasks framework instead", ios(7.0, 13.0), tvos(11.0, 13.0)){
    for (id<LDZFModule> module in self.appEventModules) {
        if (![module respondsToSelector:@selector(application:performFetchWithCompletionHandler:)]) continue;
        [module application:application performFetchWithCompletionHandler:completionHandler];
    }
}

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler API_AVAILABLE(ios(7.0)){
    for (id<LDZFModule> module in self.appEventModules) {
        if (![module respondsToSelector:@selector(application:handleEventsForBackgroundURLSession:completionHandler:)]) continue;
        [module application:application handleEventsForBackgroundURLSession:identifier completionHandler:completionHandler];
    }
}

#pragma mark - 本地通知
- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification API_DEPRECATED("Use UserNotifications Framework's -[UNUserNotificationCenterDelegate willPresentNotification:withCompletionHandler:] or -[UNUserNotificationCenterDelegate didReceiveNotificationResponse:withCompletionHandler:]", ios(4.0, 10.0)) API_UNAVAILABLE(tvos){
    for (id<LDZFModule> module in self.appEventModules) {
        if (![module respondsToSelector:@selector(application:didReceiveLocalNotification:)]) continue;
        [module application:application didReceiveLocalNotification:notification];
    }
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(nullable NSString *)identifier forLocalNotification:(UILocalNotification *)notification completionHandler:(void (^)(void))completionHandler API_DEPRECATED("Use UserNotifications Framework's -[UNUserNotificationCenterDelegate didReceiveNotificationResponse:withCompletionHandler:]", ios(8.0, 10.0)) API_UNAVAILABLE(tvos){
    for (id<LDZFModule> module in self.appEventModules) {
        if (![module respondsToSelector:@selector(application:handleActionWithIdentifier:forLocalNotification:completionHandler:)]) continue;
        [module application:application handleActionWithIdentifier:identifier forLocalNotification:notification completionHandler:completionHandler];
    }
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(nullable NSString *)identifier forLocalNotification:(UILocalNotification *)notification withResponseInfo:(NSDictionary *)responseInfo completionHandler:(void (^)(void))completionHandler API_DEPRECATED("Use UserNotifications Framework's -[UNUserNotificationCenterDelegate didReceiveNotificationResponse:withCompletionHandler:]", ios(9.0, 10.0)) API_UNAVAILABLE(tvos){
    for (id<LDZFModule> module in self.appEventModules) {
        if (![module respondsToSelector:@selector(application:handleActionWithIdentifier:forLocalNotification:withResponseInfo:completionHandler:)]) continue;
        [module application:application handleActionWithIdentifier:identifier forLocalNotification:notification withResponseInfo:responseInfo completionHandler:completionHandler];
    }
}

#pragma mark - 处理远程通知的注册
- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings API_DEPRECATED("Use UserNotifications Framework's -[UNUserNotificationCenter requestAuthorizationWithOptions:completionHandler:]", ios(8.0, 10.0)) API_UNAVAILABLE(tvos) {
    for (id<LDZFModule> module in self.appEventModules) {
        if (![module respondsToSelector:@selector(application:didRegisterUserNotificationSettings:)]) continue;
        [module application:application didRegisterUserNotificationSettings:notificationSettings];
    }
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken API_AVAILABLE(ios(3.0)) {
    for (id<LDZFModule> module in self.appEventModules) {
        if (![module respondsToSelector:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:)]) continue;
        [module application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
    }
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error API_AVAILABLE(ios(3.0)){
    for (id<LDZFModule> module in self.appEventModules) {
        if (![module respondsToSelector:@selector(application:didFailToRegisterForRemoteNotificationsWithError:)]) continue;
        [module application:application didFailToRegisterForRemoteNotificationsWithError:error];
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo API_DEPRECATED("Use UserNotifications Framework's -[UNUserNotificationCenterDelegate willPresentNotification:withCompletionHandler:] or -[UNUserNotificationCenterDelegate didReceiveNotificationResponse:withCompletionHandler:] for user visible notifications and -[UIApplicationDelegate application:didReceiveRemoteNotification:fetchCompletionHandler:] for silent remote notifications", ios(3.0, 10.0)){
    for (id<LDZFModule> module in self.appEventModules) {
        if (![module respondsToSelector:@selector(application:didReceiveRemoteNotification:)]) continue;
        [module application:application didReceiveRemoteNotification:userInfo];
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler API_AVAILABLE(ios(7.0)){
    for (id<LDZFModule> module in self.appEventModules) {
        if (![module respondsToSelector:@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:)]) continue;
        [module application:application didReceiveRemoteNotification:userInfo fetchCompletionHandler:completionHandler];
    }
}


- (void)application:(UIApplication *)application handleActionWithIdentifier:(nullable NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void (^)(void))completionHandler API_DEPRECATED("Use UserNotifications Framework's -[UNUserNotificationCenterDelegate didReceiveNotificationResponse:withCompletionHandler:]", ios(8.0, 10.0)) API_UNAVAILABLE(tvos){
    for (id<LDZFModule> module in self.appEventModules) {
        if (![module respondsToSelector:@selector(application:handleActionWithIdentifier:forRemoteNotification:completionHandler:)]) continue;
        [module application:application handleActionWithIdentifier:identifier forRemoteNotification:userInfo completionHandler:completionHandler];
    }
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(nullable NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo withResponseInfo:(NSDictionary *)responseInfo completionHandler:(void (^)(void))completionHandler API_DEPRECATED("Use UserNotifications Framework's -[UNUserNotificationCenterDelegate didReceiveNotificationResponse:withCompletionHandler:]", ios(9.0, 10.0)) API_UNAVAILABLE(tvos){
    for (id<LDZFModule> module in self.appEventModules) {
        if (![module respondsToSelector:@selector(application:handleActionWithIdentifier:forRemoteNotification:withResponseInfo:completionHandler:)]) continue;
        [module application:application handleActionWithIdentifier:identifier forRemoteNotification:userInfo withResponseInfo:responseInfo completionHandler:completionHandler];
    }
}

#pragma mark - 继续的用户活动和处理快速操作
- (BOOL)application:(UIApplication *)application willContinueUserActivityWithType:(NSString *)userActivityType API_AVAILABLE(ios(8.0)) {
    BOOL flag = NO;
    for (id<LDZFModule> module in self.appEventModules) {
        if (![module respondsToSelector:@selector(application:willContinueUserActivityWithType:)]) continue;
        flag = [module application:application willContinueUserActivityWithType:userActivityType] || flag;
    }
    return flag;
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void(^)(NSArray<id<UIUserActivityRestoring>> * __nullable restorableObjects))restorationHandler API_AVAILABLE(ios(8.0)) {
    BOOL flag = NO;
    for (id<LDZFModule> module in self.appEventModules) {
        if (![module respondsToSelector:@selector(application:continueUserActivity:restorationHandler:)]) continue;
        flag = [module application:application continueUserActivity:userActivity restorationHandler:restorationHandler] || flag;
    }
    return flag;
}

- (void)application:(UIApplication *)application didUpdateUserActivity:(NSUserActivity *)userActivity API_AVAILABLE(ios(8.0)){
    for (id<LDZFModule> module in self.appEventModules) {
        if (![module respondsToSelector:@selector(application:didUpdateUserActivity:)]) continue;
        [module application:application didUpdateUserActivity:userActivity];
    }
}

- (void)application:(UIApplication *)application didFailToContinueUserActivityWithType:(NSString *)userActivityType error:(NSError *)error API_AVAILABLE(ios(8.0)){
    for (id<LDZFModule> module in self.appEventModules) {
        if (![module respondsToSelector:@selector(application:didFailToContinueUserActivityWithType:error:)]) continue;
        [module application:application didFailToContinueUserActivityWithType:userActivityType error:error];
    }
}

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void(^)(BOOL succeeded))completionHandler API_AVAILABLE(ios(9.0)) API_UNAVAILABLE(tvos){
    if (@available(iOS 9.0, *)) {
        for (id<LDZFModule> module in self.appEventModules) {
            if (![module respondsToSelector:@selector(application:performActionForShortcutItem:completionHandler:)]) continue;
            [module application:application performActionForShortcutItem:shortcutItem completionHandler:completionHandler];
        }
    } else {
        // Fallback on earlier versions
    }
}

#pragma mark - 与WatchKit交互
- (void)application:(UIApplication *)application handleWatchKitExtensionRequest:(nullable NSDictionary *)userInfo reply:(void(^)(NSDictionary * __nullable replyInfo))reply API_AVAILABLE(ios(8.2)) {
    if (@available(iOS 8.2, *)) {
        for (id<LDZFModule> module in self.appEventModules) {
            if (![module respondsToSelector:@selector(application:handleWatchKitExtensionRequest:reply:)]) continue;
            [module application:application handleWatchKitExtensionRequest:userInfo reply:reply];
        }
    } else {
        // Fallback on earlier versions
    }
}

#pragma mark - 与HealthKit互动
- (void)applicationShouldRequestHealthAuthorization:(UIApplication *)application API_AVAILABLE(ios(9.0)){
    if (@available(iOS 9.0, *)) {
        for (id<LDZFModule> module in self.appEventModules) {
            if (![module respondsToSelector:@selector(applicationShouldRequestHealthAuthorization:)]) continue;
            [module applicationShouldRequestHealthAuthorization:application];
        }
    } else {
        // Fallback on earlier versions
    }
}
#pragma mark - 打开URL指定的资源
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url API_DEPRECATED_WITH_REPLACEMENT("application:openURL:options:", ios(2.0, 9.0)) API_UNAVAILABLE(tvos){
    BOOL flag = NO;
    for (id<LDZFModule> module in self.appEventModules) {
        if (![module respondsToSelector:@selector(application:handleOpenURL:)]) continue;
        flag = [module application:application handleOpenURL:url] || flag;
    }
    return flag;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(nullable NSString *)sourceApplication annotation:(id)annotation API_DEPRECATED_WITH_REPLACEMENT("application:openURL:options:", ios(4.2, 9.0)) API_UNAVAILABLE(tvos){
    BOOL flag = NO;
    for (id<LDZFModule> module in self.appEventModules) {
        if (![module respondsToSelector:@selector(application:openURL:sourceApplication:annotation:)]) continue;
        flag = [module application:application openURL:url sourceApplication:sourceApplication annotation:annotation] || flag;
    }
    return flag;
}
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options API_AVAILABLE(ios(9.0)){
    if (@available(iOS 9.0, *)) {
        BOOL flag = NO;
        for (id<LDZFModule> module in self.appEventModules) {
            if (![module respondsToSelector:@selector(application:openURL:options:)]) continue;
            flag = [module application:app openURL:url options:options] || flag;
        }
        return flag;
    } else {
        return NO;
    }
}

#pragma mark - 禁用指定的app扩展类
- (BOOL)application:(UIApplication *)application shouldAllowExtensionPointIdentifier:(UIApplicationExtensionPointIdentifier)extensionPointIdentifier API_AVAILABLE(ios(8.0)){
    BOOL flag = [extensionPointIdentifier isEqualToString:@"com.apple.keyboard-service"] ? YES : NO;
    for (id<LDZFModule> module in self.appEventModules) {
        if (![module respondsToSelector:@selector(application:shouldAllowExtensionPointIdentifier:)]) continue;
        flag = [module application:application shouldAllowExtensionPointIdentifier:extensionPointIdentifier] || flag;
    }
    return flag;
}

#pragma mark - 处理SiriKit意图
- (void)application:(UIApplication *)application handleIntent:(INIntent *)intent completionHandler:(void(^)(INIntentResponse *intentResponse))completionHandler API_DEPRECATED("Use application:handlerForIntent: instead", ios(11.0, 14.0)){
    if (@available(iOS 11.0, *)) {
        for (id<LDZFModule> module in self.appEventModules) {
            if (![module respondsToSelector:@selector(application:handleIntent:completionHandler:)]) continue;
            [module application:application handleIntent:intent completionHandler:completionHandler];
        }
    } else {
        // Fallback on earlier versions
    }
}

- (nullable id)application:(UIApplication *)application handlerForIntent:(INIntent *)intent API_AVAILABLE(ios(14.0)){
    id obj = nil;
    for (id<LDZFModule> module in self.appEventModules) {
        if (![module respondsToSelector:@selector(application:handlerForIntent:)]) continue;
        obj = [module application:application handlerForIntent:intent]?:obj;
    }
    return obj;
}
#pragma mark - 处理CloudKit邀请
- (void)application:(UIApplication *)application userDidAcceptCloudKitShareWithMetadata:(CKShareMetadata *)cloudKitShareMetadata API_AVAILABLE(ios(10.0)){
    if (@available(iOS 10.0, *)) {
        for (id<LDZFModule> module in self.appEventModules) {
            if (![module respondsToSelector:@selector(application:userDidAcceptCloudKitShareWithMetadata:)]) continue;
            [module application:application userDidAcceptCloudKitShareWithMetadata:cloudKitShareMetadata];
        }
    } else {
        // Fallback on earlier versions
    }
}
#pragma mark - 管理界面几何图形
- (void)application:(UIApplication *)application willChangeStatusBarOrientation:(UIInterfaceOrientation)newStatusBarOrientation duration:(NSTimeInterval)duration API_UNAVAILABLE(tvos) API_DEPRECATED("Use viewWillTransitionToSize:withTransitionCoordinator: instead.", ios(2.0, 13.0)){
    for (id<LDZFModule> module in self.appEventModules) {
        if (![module respondsToSelector:@selector(application:willChangeStatusBarOrientation:duration:)]) continue;
        [module application:application willChangeStatusBarOrientation:newStatusBarOrientation duration:duration];
    }
}

- (void)application:(UIApplication *)application didChangeStatusBarOrientation:(UIInterfaceOrientation)oldStatusBarOrientation API_UNAVAILABLE(tvos) API_DEPRECATED("Use viewWillTransitionToSize:withTransitionCoordinator: instead.", ios(2.0, 13.0)){
    for (id<LDZFModule> module in self.appEventModules) {
        if (![module respondsToSelector:@selector(application:didChangeStatusBarOrientation:)]) continue;
        [module application:application didChangeStatusBarOrientation:oldStatusBarOrientation];
    }
}

- (void)application:(UIApplication *)application willChangeStatusBarFrame:(CGRect)newStatusBarFrame API_UNAVAILABLE(tvos) API_DEPRECATED("Use viewWillTransitionToSize:withTransitionCoordinator: instead.", ios(2.0, 13.0)){
    for (id<LDZFModule> module in self.appEventModules) {
        if (![module respondsToSelector:@selector(application:willChangeStatusBarFrame:)]) continue;
        [module application:application willChangeStatusBarFrame:newStatusBarFrame];
    }
}

- (void)application:(UIApplication *)application didChangeStatusBarFrame:(CGRect)oldStatusBarFrame API_UNAVAILABLE(tvos) API_DEPRECATED("Use viewWillTransitionToSize:withTransitionCoordinator: instead.", ios(2.0, 13.0)){
    for (id<LDZFModule> module in self.appEventModules) {
        if (![module respondsToSelector:@selector(application:didChangeStatusBarFrame:)]) continue;
        [module application:application didChangeStatusBarFrame:oldStatusBarFrame];
    }
}

#pragma clang diagnostic pop

@end
