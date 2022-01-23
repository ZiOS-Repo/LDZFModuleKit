//
//  LdzfModuleManager.h
//  Pods
//
//  Created by zhuyuhui on 2021/11/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
///模块定义的4个参数，使用字符串常量从字典中读取
static NSString * _Nonnull const LDZFModuleLevelKey = @"moduleLevel";
static NSString * _Nonnull const LDZFModuleClassKey = @"moduleClass";
static NSString * _Nonnull const LDZFModuleIDKey = @"moduleID";
static NSString * _Nonnull const LDZFModuleParametersKey = @"moduleParameters";

///模块遵循的协议定义
@protocol LDZFModule <UIApplicationDelegate>
///注册模块的完成回调
typedef void(^LDZFModuleRegisterCompletionHandler)(id<LDZFModule> _Nonnull mode, id _Nullable parameters);
///注销模块的完成回调
typedef void(^LDZFModuleUnregisterCompletionHandler)(id<LDZFModule> _Nonnull mode, id _Nullable parameters);

///模块执行优先级
@property(nonatomic, strong) NSNumber *moduleLevel;
///模块名称
@property(nonatomic, copy) NSString * _Nonnull moduleName;
///模块ID
@property(nonatomic, copy) NSString * _Nonnull moduleID;
///模块注册时所需自定义参数
@property(nonatomic, strong) NSDictionary * _Nullable moduleParameters;
@required
///实现模块注册方法
- (void)moduleRegisterWithCompletionHandler:(LDZFModuleRegisterCompletionHandler _Nullable)completionHandler;
///实现模块注销方法
- (void)moduleUnregisterWithCompletionHandler:(LDZFModuleUnregisterCompletionHandler _Nullable)completionHandler;

@end

@interface LdzfModuleManager : NSObject<UIApplicationDelegate>

+ (nonnull instancetype)sharedInstance;

/**
 按照plist文件配置加载模块

 @param plistFileName 文件名称
 */
- (void)loadModulesWithPlistFileName:(NSString *_Nonnull)plistFileName;

/**
 当前已经加载的模块

 @return 已加载模块数组返回
 */
- (NSArray<id<LDZFModule>> * _Nonnull)allModules;

/**
 当前已经加载的模块的所有ID

 @return 已经加载的模块的所有ID数组返回
 */
- (NSArray * _Nonnull)allModuleIDs;

/**
 添加模块

 @param module 待加载的模块
 */
- (void)addModule:(id<LDZFModule> _Nonnull)module;

/**
 移除模块

 @param module 待移除的模块
 */
- (void)removeModule:(id<LDZFModule> _Nonnull)module;

/**
 按照模块ID移除模块
 
 @param moduleID 待移除的模块ID
 */
- (void)removeModuleWithID:(NSString * _Nonnull)moduleID;

@end

NS_ASSUME_NONNULL_END
