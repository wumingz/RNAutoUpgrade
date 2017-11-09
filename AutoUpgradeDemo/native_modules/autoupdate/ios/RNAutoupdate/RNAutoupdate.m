//
//  RNAutoupgrade.h
//  RNAutoupgrade
//
//  Created by 吴明志 on 2017/9/12.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "RNAutoupdate.h"
#import "RNAutoupgradeManager.h"
#import "RNAutoupgradeDownloader.h"
#import "FileHash.h"

#if __has_include(<React/RCTBridge.h>)
#import <React/RCTBundleURLProvider.h>
#import "React/RCTEventDispatcher.h"
#import <React/RCTConvert.h>
#import <React/RCTLog.h>
#else
#import "RCTBundleURLProvider"
#import "RCTEventDispatcher.h"
#import "RCTConvert.h"
#import "RCTLog.h"
#endif


#ifdef DEBUG
#define DSLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#define DSLog(...)
#endif

static NSString *const keyUpdateInfo = @"REACTNATIVE_AUTOUPGRADE_UPGRADE_INFO";
static NSString *const paramPackageVersion = @"packageVersion"; //标记热更新成功后的app版本号，用于大版本升级的判定
static NSString *const paramCurrentVersion = @"currentVersion"; //当前hash版本【bundleMD5字段】
static NSString *const paramCurrentHashVersion = @"currentHashVersion"; //记录下载比对成功的hash版本【bundleMD5字段】
static NSString *const paramLastVersion = @"lastVersion"; //前一hash版本
static NSString *const paramIsFirstTime = @"isFirstTime";
static NSString *const paramIsFirstLoadOk = @"isFirstLoadOK";
static NSString *const keyFirstLoadMarked = @"REACTNATIVECN_HOTUPDATE_FIRSTLOADMARKED_KEY";
static NSString *const keyRolledBackMarked = @"REACTNATIVECN_HOTUPDATE_ROLLEDBACKMARKED_KEY";
static NSString *const KeyPackageUpdatedMarked = @"REACTNATIVECN_HOTUPDATE_ISPACKAGEUPDATEDMARKED_KEY";
static NSString *const keyRolledBackhashNameArr = @"RolledBackhashNameArr"; //崩溃版本hashName数据记录

// app info
static NSString * const AppVersionUpdated = @"appVersionUpdated"; //标记当前热更新成功后的app版本号，用于大版本升级的判定
static NSString * const LastAppVersionUpdated = @"lastAppVersionUpdated"; //标记上一次热更新成功后的app版本号
static NSString * const CurrentBundleVersion = @"currentBundleVersion"; //前一package版本【bundleV字段】，接口需要
static NSString * const LastBundleVersion = @"lastBundleVersion"; //前一package版本【bundleV字段】，接口需要

// file def
static NSString * const BUNDLE_FILE_NAME = @"index.jsbundle"; //diff比对后的生成的新文件
static NSString * const SOURCE_PATCH_NAME = @"changes.json"; //更新包json数据的文件【changes，deletes】，可以直接覆盖和删除的文件
static NSString * const BUNDLE_PATCH_NAME = @"bspatch"; //需要进行新旧文件diff比对的补丁包

// error def
static NSString * const ERROR_OPTIONS = @"options error";
static NSString * const ERROR_BSDIFF = @"bsdiff error";
static NSString * const ERROR_FILE_OPERATION = @"file operation error";

// event def
static NSString * const EVENT_PROGRESS_DOWNLOAD = @"RCTHotUpdateDownloadProgress";
static NSString * const EVENT_PROGRESS_UNZIP = @"RCTHotUpdateUnzipProgress";
static NSString * const PARAM_PROGRESS_HASHNAME = @"hashname";
static NSString * const PARAM_PROGRESS_RECEIVED = @"received";
static NSString * const PARAM_PROGRESS_TOTAL = @"total";

typedef NS_ENUM(NSInteger, RNAutoupgradeType){
    RNAutoupgradeTypeFullDownload = 1, // 去appstore下载应用
    RNAutoupgradeTypePatchFromPackage = 2, //【patch】暂无热更新的版本，直接和main.jsbundle进行比对
    RNAutoupgradeTypePatchFromPpk = 3, //【patch】已有热更新的版本，和旧版本的bundle进行比对
    RNAutoupgradeTypeFullPackage = 4, //【package】直接替换main.jsbundle文件
};

@implementation RNAutoupdate{
    RNAutoupgradeManager *_fileManager;
}

@synthesize bridge = _bridge;
@synthesize methodQueue = _methodQueue;

RCT_EXPORT_MODULE(RNAutoupgrade);

- (instancetype)init{
    if (self = [super init]) {
        
        _fileManager = [RNAutoupgradeManager sharedInstance];
    }
    return self;
}


/**
 app初始化时，加载资源包
 
 @return 返回加载的资源路径
 */
+ (NSURL *)bundleURL
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *updateInfo = [defaults dictionaryForKey:keyUpdateInfo];
    
    //加载热更新版本
    if (updateInfo) {
        NSString *curPackageVersion = [RNAutoupdate packageVersion];
        NSString *packageVersion = [updateInfo objectForKey:paramPackageVersion];
        
        BOOL needClearUpdateInfo = ![curPackageVersion isEqualToString:packageVersion];
        //2、判定app的版本是否升级：是则加载本地.jsbundle文件，并清除所有热更新package信息
        if (needClearUpdateInfo) {
            [defaults setObject:nil forKey:keyUpdateInfo];
            [defaults setObject:@(YES) forKey:KeyPackageUpdatedMarked];
            [defaults synchronize];
            // ...need clear files later
            
        }else {
            NSString *curVersion = updateInfo[paramCurrentVersion];
            NSString *lastVersion = updateInfo[paramLastVersion];
            
            BOOL isFirstTime = [updateInfo[paramIsFirstTime] boolValue];
            BOOL isFirstLoadOK = [updateInfo[paramIsFirstLoadOk] boolValue];
            
            NSString *loadVersioin = curVersion;
            BOOL needRollback = (isFirstTime == NO && isFirstLoadOK == NO) || loadVersioin.length<=0;
            //3、判定是否需要回滚
            if (needRollback) {
                loadVersioin = lastVersion;
                
                //4、判定回滚的版本
                if (lastVersion.length) {
                    // roll back to last version
                    [defaults setObject:@{paramCurrentVersion:lastVersion,
                                          paramCurrentHashVersion:lastVersion,
                                          paramIsFirstTime:@(NO),
                                          paramIsFirstLoadOk:@(YES),
                                          paramPackageVersion:curPackageVersion,
                                          AppVersionUpdated:updateInfo[LastAppVersionUpdated],
                                          CurrentBundleVersion:updateInfo[LastBundleVersion]}
                                 forKey:keyUpdateInfo];
                }else {
                    // roll back to bundle
                    [defaults setObject:nil forKey:keyUpdateInfo];
                }
                
                //保存crash版本hashName数据
                NSArray *arr = [defaults arrayForKey:keyRolledBackhashNameArr];
                NSMutableArray *hashNameArr = [NSMutableArray arrayWithArray:arr?arr:@[]];
                [hashNameArr addObject:curVersion];
                [defaults setObject:hashNameArr forKey:keyRolledBackhashNameArr];
                
                [defaults setObject:@(YES) forKey:keyRolledBackMarked];
                [defaults synchronize];
                // ...need clear files later
                
            }else if (isFirstTime){
                NSMutableDictionary *newInfo = [[NSMutableDictionary alloc] initWithDictionary:updateInfo];
                newInfo[paramIsFirstTime] = @(NO);
                [defaults setObject:newInfo forKey:keyUpdateInfo];
                [defaults setObject:@(YES) forKey:keyFirstLoadMarked];
                [defaults synchronize];
            }
            
            if (loadVersioin.length) {
                NSString *downloadDir = [RNAutoupdate downloadDir];
                //返回比对后的新文件路径，用于重新reload
                NSString *bundlePath = [[downloadDir stringByAppendingPathComponent:loadVersioin] stringByAppendingPathComponent:BUNDLE_FILE_NAME];
                if ([[NSFileManager defaultManager] fileExistsAtPath:bundlePath isDirectory:NULL]) {
                    NSURL *bundleURL = [NSURL fileURLWithPath:bundlePath];
                    return bundleURL;
                }
            }
        }
    }
    
    //初始或重复回滚时,加载main.jsbundle文件
    return [RNAutoupdate binaryBundleURL];
}


/**
 定义导出常量，给javaScript调用
 
 @return 数据只会初始化返回一次
 */
- (NSDictionary *)constantsToExport
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSMutableDictionary *ret = [NSMutableDictionary new];
    ret[@"downloadRootDir"] = [RNAutoupdate downloadDir];
    ret[@"packageVersion"] = [RNAutoupdate packageVersion];
    ret[@"isRolledBack"] = [defaults objectForKey:keyRolledBackMarked];
    ret[@"isFirstTime"] = [defaults objectForKey:keyFirstLoadMarked];
    NSDictionary *updateInfo = [defaults dictionaryForKey:keyUpdateInfo];
    ret[@"currentVersion"] = [updateInfo objectForKey:paramCurrentVersion];
    
    //导出app热更新成功的版本号 - AppVersionUpdated
    ret[@"appVersionUpdated"] = [updateInfo objectForKey:AppVersionUpdated];
    //判断热更新成功后的app版本和当前app版本是否一致，不一致重置0
    ret[@"currentBundleVersion"] = [ret[@"packageVersion"] isEqualToString:ret[@"appVersionUpdated"]]?[updateInfo objectForKey:CurrentBundleVersion]:@"0";
    
    // clear isFirstTimemarked
    if ([[defaults objectForKey:keyFirstLoadMarked] boolValue]) {
        [defaults setObject:nil forKey:keyFirstLoadMarked];
    }
    
    // clear rolledbackmark
    if ([[defaults objectForKey:keyRolledBackMarked] boolValue]) {
        [defaults setObject:nil forKey:keyRolledBackMarked];
        [self clearInvalidFiles];
    }
    
    // clear packageupdatemarked
    if ([[defaults objectForKey:KeyPackageUpdatedMarked] boolValue]) {
        [defaults setObject:nil forKey:KeyPackageUpdatedMarked];
        [self clearInvalidFiles];
    }
    [defaults synchronize];
    
    return ret;
}

RCT_EXPORT_METHOD(downloadUpdate:(NSDictionary *)options
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    [self hotUpdate:RNAutoupgradeTypeFullDownload options:options callback:^(NSError *error) {
        if (error) {
            reject([NSString stringWithFormat: @"%lu", (long)error.code], error.localizedDescription, error);
        }
        else {
            [self markDownloadHashVersion:options[@"hashName"]];
            resolve(nil);
        }
    }];
}

RCT_EXPORT_METHOD(downloadPatchFromPackage:(NSDictionary *)options
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    [self hotUpdate:RNAutoupgradeTypePatchFromPackage options:options callback:^(NSError *error) {
        if (error) {
            reject([NSString stringWithFormat: @"%lu", (long)error.code], error.localizedDescription, error);
        }
        else {
            NSString *bundlePath = [[[RNAutoupdate downloadDir] stringByAppendingPathComponent:options[@"hashName"]] stringByAppendingPathComponent:BUNDLE_FILE_NAME];
            NSString *hashMD5 = [FileHash md5HashOfFileAtPath: bundlePath];
            DSLog(@"==hashMD5==%@ ==hashName==%@",hashMD5,options[@"hashName"]);
            
            if ([hashMD5 isEqualToString:options[@"hashName"]]) {
                [self markDownloadHashVersion:options[@"hashName"]];
                resolve(nil);
            }else{
                NSError *err = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:4 userInfo:@{@"4":@"MD5不一致"}];
                reject([NSString stringWithFormat: @"%lu", (long)err.code], err.localizedDescription, err);
            }
        }
    }];
}

RCT_EXPORT_METHOD(downloadPatchFromPpk:(NSDictionary *)options
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    [self hotUpdate:RNAutoupgradeTypePatchFromPpk options:options callback:^(NSError *error) {
        if (error) {
            reject([NSString stringWithFormat: @"%lu", (long)error.code], error.localizedDescription, error);
        }
        else {
            NSString *bundlePath = [[[RNAutoupdate downloadDir] stringByAppendingPathComponent:options[@"hashName"]] stringByAppendingPathComponent:BUNDLE_FILE_NAME];
            NSString *hashMD5 = [FileHash md5HashOfFileAtPath: bundlePath];
            DSLog(@"==hashMD5==%@ ==hashName==%@",hashMD5,options[@"hashName"]);
            
            if ([hashMD5 isEqualToString:options[@"hashName"]]) {
                [self markDownloadHashVersion:options[@"hashName"]];
                resolve(nil);
            }else{
                NSError *err = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:4 userInfo:@{@"4":@"MD5不一致"}];
                reject([NSString stringWithFormat: @"%lu", (long)err.code], err.localizedDescription, err);
            }
        }
    }];
}

RCT_EXPORT_METHOD(downloadFullPackage:(NSDictionary *)options
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    [self hotUpdate:RNAutoupgradeTypeFullPackage options:options callback:^(NSError *error) {
        if (error) {
            reject([NSString stringWithFormat: @"%lu", (long)error.code], error.localizedDescription, error);
        }
        else {
            [self markDownloadHashVersion:options[@"hashName"]];
            resolve(nil);
        }
    }];
}

//标记版本下载成功，避免setNeedUpdate之前，版本重复下载
-(void)markDownloadHashVersion:(NSString *)hashVersion{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *packageInfo = [[NSMutableDictionary alloc] initWithDictionary:[defaults objectForKey:keyUpdateInfo]];
    [packageInfo setObject:hashVersion forKey:paramCurrentHashVersion];
    
    [defaults setObject:packageInfo forKey:keyUpdateInfo];
    [defaults synchronize];
}

//更新文件后，不重启
RCT_EXPORT_METHOD(setNeedUpdate:(NSDictionary *)options)
{
    NSString *hashName = options[@"hashName"];
    NSString *currentBundleV = options[@"currentBundleVersion"];
    DSLog(@"==标记最新jsbundle==%@ == currentBundleVersion == %@",hashName,currentBundleV);
    
    if (hashName.length) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *lastVersion = nil;
        if ([defaults objectForKey:keyUpdateInfo]) {
            NSDictionary *updateInfo = [defaults objectForKey:keyUpdateInfo];
            lastVersion = updateInfo[paramCurrentVersion];
        }
        
        NSMutableDictionary *newInfo = [[NSMutableDictionary alloc] init];
        newInfo[paramPackageVersion] = [RNAutoupdate packageVersion];
        newInfo[paramCurrentVersion] = hashName;
        newInfo[paramCurrentHashVersion] = hashName;
        newInfo[paramLastVersion] = lastVersion;
        newInfo[paramIsFirstTime] = @(YES);
        newInfo[paramIsFirstLoadOk] = @(NO);
        
        //保存热更新bundle包版本
        newInfo[LastBundleVersion] = [newInfo objectForKey:CurrentBundleVersion];//上一次的bundle包版本
        newInfo[CurrentBundleVersion] = currentBundleV;//当前的bundle包版本
        //保存在热更新成功的app版本号
        newInfo[LastAppVersionUpdated] = [newInfo objectForKey:AppVersionUpdated];//上一次热更新成功后app版本
        newInfo[AppVersionUpdated] = [RNAutoupdate packageVersion];////当前热更新成功后app版本
        
        [defaults setObject:newInfo forKey:keyUpdateInfo];
        [defaults synchronize];
    }
}

//更新文件后重启
RCT_EXPORT_METHOD(reloadUpdate:(NSDictionary *)options)
{
    NSString *hashName = options[@"hashName"];
    if (hashName.length) {
        [self setNeedUpdate:options];
        
        // reload
        dispatch_async(dispatch_get_main_queue(), ^{
            [_bridge setValue:[[self class] bundleURL] forKey:@"bundleURL"];
            [_bridge reload];
        });
    }
}

//标记更新成功，删除压缩包文件
RCT_EXPORT_METHOD(markSuccess)
{
    // update package info
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *packageInfo = [[NSMutableDictionary alloc] initWithDictionary:[defaults objectForKey:keyUpdateInfo]];
    [packageInfo setObject:@(NO) forKey:paramIsFirstTime];
    [packageInfo setObject:@(YES) forKey:paramIsFirstLoadOk];
    [defaults setObject:packageInfo forKey:keyUpdateInfo];
    [defaults setObject:@[] forKey:keyRolledBackhashNameArr]; //清空crash版本记录数据
    
    [defaults synchronize];
    
    // clear other package dir
    [self clearInvalidFiles];
}

#pragma mark - private
//下载并解压
- (void)hotUpdate:(RNAutoupgradeType)type options:(NSDictionary *)options callback:(void (^)(NSError *error))callback
{
    NSString *updateUrl = [RCTConvert NSString:options[@"updateUrl"]];
    NSString *hashName = [RCTConvert NSString:options[@"hashName"]];
    if (updateUrl.length<=0 || hashName.length<=0) {
        callback([self errorWithMessage:ERROR_OPTIONS]);
        return;
    }
    NSString *originHashName = [RCTConvert NSString:options[@"originHashName"]];
    if (type == RNAutoupgradeTypePatchFromPpk && originHashName<=0) {
        callback([self errorWithMessage:ERROR_OPTIONS]);
        return;
    }
    
    NSString *dir = [RNAutoupdate downloadDir];
    BOOL success = [_fileManager createDir:dir];
    if (!success) {
        callback([self errorWithMessage:ERROR_FILE_OPERATION]);
        return;
    }
    
    NSString *zipFilePath = [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@%@",hashName, [self zipExtension:type]]];
    NSString *unzipDir = [dir stringByAppendingPathComponent:hashName];
    
    //判断本地是否已经存在最新版本包
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *updateInfo = [defaults dictionaryForKey:keyUpdateInfo];
    if (updateInfo && [updateInfo[paramCurrentHashVersion] isEqualToString:hashName]) {
        callback([self errorWithMessage:@"本地已存在最新包,待重启"]);
        return;
    }
    
    //过滤掉RolledBack回滚版本数据
    NSArray *hashNameArr = [defaults arrayForKey:keyRolledBackhashNameArr];
    if (hashNameArr && [hashNameArr containsObject:hashName]) {
        callback([self errorWithMessage:@"RolledBack错误版本数据"]);
        return;
    }
    
    RCTLogInfo(@"RNUpdate -- download file %@", updateUrl);
    [RNAutoupgradeDownloader download:updateUrl savePath:zipFilePath progressHandler:^(long long receivedBytes, long long totalBytes) {
        [self.bridge.eventDispatcher sendAppEventWithName:EVENT_PROGRESS_DOWNLOAD
                                                     body:@{
                                                            PARAM_PROGRESS_HASHNAME:hashName,
                                                            PARAM_PROGRESS_RECEIVED:[NSNumber numberWithLongLong:receivedBytes],
                                                            PARAM_PROGRESS_TOTAL:[NSNumber numberWithLongLong:totalBytes]
                                                            }];
    } completionHandler:^(NSString *path, NSError *error) {
        if (error) {
            callback(error);
        }
        else {
            RCTLogInfo(@"RNUpdate -- unzip file %@", zipFilePath);
            NSString *sourceOrigin;
            NSString *bundleOrigin;
            
            switch (type) {
                case RNAutoupgradeTypePatchFromPackage:
                {//未有热更新的bundle包
                    sourceOrigin = [[NSBundle mainBundle] resourcePath];
                    bundleOrigin = [[RNAutoupdate binaryBundleURL] path];
                }
                    break;
                case RNAutoupgradeTypePatchFromPpk:
                {//已有旧版本热更新下载包
                    NSString *lastVertionDir = [dir stringByAppendingPathComponent:originHashName];
                    sourceOrigin = lastVertionDir;
                    bundleOrigin = [lastVertionDir stringByAppendingPathComponent:BUNDLE_FILE_NAME];
                }
                    break;
                default:
                    break;
            }
            
            //复制本地资源包，解压补丁包
            if (type == RNAutoupgradeTypePatchFromPackage || type == RNAutoupgradeTypePatchFromPpk){
                [_fileManager copyFilesfromDir:sourceOrigin toDir:unzipDir completionHandler:^(NSError *error) {
                    
                    if (error) {
                        DSLog(@"复制资源包错误");
                    }else{
                        //解压
                        [_fileManager unzipFileAtPath:zipFilePath toDestination:unzipDir progressHandler:^(NSString *entry,long entryNumber, long total) {
                            
                            [self.bridge.eventDispatcher sendAppEventWithName:EVENT_PROGRESS_UNZIP body:@{
                                                                                                          PARAM_PROGRESS_HASHNAME:hashName,PARAM_PROGRESS_RECEIVED:[NSNumber numberWithLong:entryNumber],PARAM_PROGRESS_TOTAL:[NSNumber numberWithLong:total]
                                                                                                          }];
                        } completionHandler:^(NSString *path, BOOL succeeded, NSError *error) {
                            dispatch_async(_methodQueue, ^{
                                
                                if (error) {
                                    callback(error);
                                }else {
                                    [self patch:hashName fromBundle:bundleOrigin source:sourceOrigin typ:RNAutoupgradeTypePatchFromPpk callback:callback];
                                }
                            });
                        }];
                    }
                }];
                
            }//解压全量包
            else if(type == RNAutoupgradeTypeFullPackage){
                //解压
                [_fileManager unzipFileAtPath:zipFilePath toDestination:unzipDir progressHandler:^(NSString *entry,long entryNumber, long total) {
                    
                    [self.bridge.eventDispatcher sendAppEventWithName:EVENT_PROGRESS_UNZIP body:@{
                                                                                                  PARAM_PROGRESS_HASHNAME:hashName,PARAM_PROGRESS_RECEIVED:[NSNumber numberWithLong:entryNumber],PARAM_PROGRESS_TOTAL:[NSNumber numberWithLong:total]
                                                                                                  }];
                } completionHandler:^(NSString *path, BOOL succeeded, NSError *error) {
                    dispatch_async(_methodQueue, ^{
                        
                        if (error) {
                            callback(error);
                        }else {
                            //移动文件位置
                            NSString *jsbundlePath = [unzipDir stringByAppendingPathComponent:@"assets"];
                            
                            BOOL result = [_fileManager moveFileAtPath:jsbundlePath toPath:unzipDir newFileName:BUNDLE_FILE_NAME];
                            if (result) {
                                DSLog(@"jsbundle文件位置移动成功！");
                                callback(nil);
                            }else{
                                NSError *err = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:4 userInfo:@{@"4":@"jsbundle文件位置移动失败"}];
                                callback(err);
                            }
                        }
                    });
                }];
                
            }
        }
    }];
}

//差量运算
- (void)patch:(NSString *)hashName fromBundle:(NSString *)bundleOrigin source:(NSString *)sourceOrigin typ:(RNAutoupgradeType)type callback:(void (^)(NSError *error))callback
{
    NSString *unzipDir = [[RNAutoupdate downloadDir] stringByAppendingPathComponent:hashName];
    NSString *sourcePatch = [unzipDir stringByAppendingPathComponent:SOURCE_PATCH_NAME];
    NSString *bundlePatch = [unzipDir stringByAppendingPathComponent:BUNDLE_PATCH_NAME];
    
    NSString *destination = [unzipDir stringByAppendingPathComponent:BUNDLE_FILE_NAME];
    [_fileManager bsdiffFileAtPath:bundlePatch fromOrigin:bundleOrigin toDestination:destination completionHandler:^(BOOL success) {
        if (success) {
            NSData *data = [NSData dataWithContentsOfFile:sourcePatch];
            NSError *error = nil;
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
            if (error) {
                callback(error);
                return;
            }
            
            //NSDictionary *copies = json[@"changes"]; //需要从旧文件复制到新文件使用的
            NSDictionary *deletes = json[@"deletes"]; //复制的旧文件中，需要过滤掉的部分
            
            //将资源包中不需要的文件移出
            [_fileManager deleteFiles:deletes fromDir:unzipDir completionHandler:^(NSError *error) {
                if (error) {
                    callback(error);
                }
                else {
                    callback(nil);
                }
            }];
            
        }
        else {
            callback([self errorWithMessage:ERROR_BSDIFF]);
        }
    }];
}

//清除无效文件
- (void)clearInvalidFiles
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *updateInfo = [defaults objectForKey:keyUpdateInfo];
    NSString *curVersion = [updateInfo objectForKey:paramCurrentVersion];
    
    NSString *downloadDir = [RNAutoupdate downloadDir];
    NSError *error = nil;
    NSArray *list = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:downloadDir error:&error];
    if (error) {
        return;
    }
    
    for(NSString *fileName in list) {
        //删除download路径下所有非当前版本
        if (![fileName isEqualToString:curVersion]) {
            [_fileManager removeFile:[downloadDir stringByAppendingPathComponent:fileName] completionHandler:nil];
        }
    }
}


- (NSString *)zipExtension:(RNAutoupgradeType)type
{
    switch (type) {
        case RNAutoupgradeTypeFullDownload:
            return @".ppk";
        case RNAutoupgradeTypePatchFromPackage:
            return @".apk.patch";
        case RNAutoupgradeTypePatchFromPpk:
            return @".ppk.patch";
        case RNAutoupgradeTypeFullPackage:
            return @".full.package";
        default:
            break;
    }
}

- (NSError *)errorWithMessage:(NSString *)errorMessage
{
    return [NSError errorWithDomain:@"cn.ds.autoupgrade"
                               code:-1
                           userInfo:@{ NSLocalizedDescriptionKey: errorMessage}];
}

+ (NSString *)downloadDir
{
    NSString *directory = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject];
    NSString *downloadDir = [directory stringByAppendingPathComponent:@"dsautoupgrade"];
    
    return downloadDir;
}

//本地jsbundle路径
+ (NSURL *)binaryBundleURL
{
    NSURL *url = [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index.ios" fallbackResource:nil];
    return url;
}

//原生app的版本号
+ (NSString *)packageVersion
{
    static NSString *version = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
        version = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    });
    return version;
}


@end

