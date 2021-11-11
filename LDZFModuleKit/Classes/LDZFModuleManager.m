//
//  LDZFModuleManager.m
//  Pods
//
//  Created by zhuyuhui on 2021/11/11.
//

#import "LDZFModuleManager.h"

@interface LDZFModuleManager()
@property(nonatomic, strong) NSMutableArray *appEventModules;
@end

@implementation LDZFModuleManager
+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static LDZFModuleManager *instance = nil;
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

#pragma mark - UIApplicationDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id> *)launchOptions {
    for (id<LDZFModule> module in self.appEventModules) {
        if ([module respondsToSelector:@selector(application:didFinishLaunchingWithOptions:)]) {
            [module application:application didFinishLaunchingWithOptions:launchOptions];
        }
    }
    return YES;
}

//说明：当应用程序将要入非活动状态执行，在此期间，应用程序不接收消息或事件，比如来电话了
- (void)applicationWillResignActive:(UIApplication *)application {
    for (id<LDZFModule> module in self.appEventModules) {
        if ([module respondsToSelector:@selector(applicationWillResignActive:)]) {
            [module applicationWillResignActive:application];
        }
    }
}

//说明：当应用程序入活动状态执行
- (void)applicationDidBecomeActive:(UIApplication *)application {
    for (id<LDZFModule> module in self.appEventModules) {
        if ([module respondsToSelector:@selector(applicationDidBecomeActive:)]) {
            [module applicationDidBecomeActive:application];
        }
    }
}

//说明：当程序从后台将要重新回到前台时候调用
- (void)applicationWillEnterForeground:(UIApplication *)application API_AVAILABLE(ios(4.0)){
    for (id<LDZFModule> module in self.appEventModules) {
        if ([module respondsToSelector:@selector(applicationWillEnterForeground:)]) {
            [module applicationWillEnterForeground:application];
        }
    }
}

//说明：当程序被推送到后台的时候调用。所以要设置后台继续运行，则在这个函数里面设置即可
- (void)applicationDidEnterBackground:(UIApplication *)application API_AVAILABLE(ios(4.0)){
    for (id<LDZFModule> module in self.appEventModules) {
        if ([module respondsToSelector:@selector(applicationDidEnterBackground:)]) {
            [module applicationDidEnterBackground:application];
        }
    }
}

//说明：当程序将要退出是被调用，通常是用来保存数据和一些退出前的清理工作
- (void)applicationWillTerminate:(UIApplication *)application {
    for (id<LDZFModule> module in self.appEventModules) {
        if ([module respondsToSelector:@selector(applicationWillTerminate:)]) {
            [module applicationWillTerminate:application];
        }
    }
}

//说明：UNIVERSIAL LINK 唤醒 app
- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler API_AVAILABLE(ios(8.0)){
    for (id<LDZFModule> module in self.appEventModules) {
        if ([module respondsToSelector:@selector(application:continueUserActivity:restorationHandler:)]) {
            BOOL isRespond = [module application:application continueUserActivity:userActivity restorationHandler:restorationHandler];
            if (isRespond) {
                return YES;
            }
        }
    }
    return NO;
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options API_AVAILABLE(ios(9.0)) {
    for (id<LDZFModule> module in self.appEventModules) {
        if ([module respondsToSelector:@selector(application:openURL:options:)]) {
            BOOL isRespond = [module application:app openURL:url options:options];
            if (isRespond) {
                return YES;
            }
        }
    }
    return NO;
}
@end
