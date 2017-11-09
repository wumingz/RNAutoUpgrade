//
//  RNAutoupgradeManager.h
//  RNAutoupgrade
//
//  Created by 吴明志 on 2017/9/12.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface RNAutoupgradeManager : NSObject


/**
 单例类
 
 @return 返回单例对象
 */
+ (RNAutoupgradeManager *)sharedInstance;


/**
 创建本地文件
 
 @param dir 文件路径
 @return 是否创建成功
 */
- (BOOL)createDir:(NSString *)dir;


/**
 解压文件
 
 @param path 文件路径
 @param destination 解压到文件路径
 @param progressHandler 解压进度回调
 @param completionHandler 解压完成回调
 */
- (void)unzipFileAtPath:(NSString *)path
          toDestination:(NSString *)destination
        progressHandler:(void (^)(NSString *entry, long entryNumber, long total))progressHandler
      completionHandler:(void (^)(NSString *path, BOOL succeeded, NSError *error))completionHandler;


/**
 差量运算合成新包
 
 @param path 补丁包路径
 @param origin 本地源文件包路径
 @param destination 合成新包存放路径
 @param completionHandler 差量运算完成的回调
 */
- (void)bsdiffFileAtPath:(NSString *)path
              fromOrigin:(NSString *)origin
           toDestination:(NSString *)destination
       completionHandler:(void (^)(BOOL success))completionHandler;



/**
 移除废弃文件

 @param filesDic 文件目录
 @param toDir 文件夹路径
 @param completionHandler 完成回调
 */
- (void)deleteFiles:(NSDictionary *)filesDic
            fromDir:(NSString *)toDir
  completionHandler:(void (^)(NSError *error))completionHandler;

/**
 删除文件
 
 @param filePath 文件路径
 @param completionHandler 删除完成的回调
 */
- (void)removeFile:(NSString *)filePath
 completionHandler:(void (^)(NSError *error))completionHandler;



/**
 copy本地资源包

 @param fromDir 源资源包路径
 @param toDir 目标资源包路径
 @param completionHandler 错误回调
 */
- (void)copyFilesfromDir:(NSString *)fromDir toDir:(NSString *)toDir completionHandler:(void (^)(NSError *error))completionHandler;


//移动文件位置
-(BOOL)moveFileAtPath:(NSString *)srcPath toPath:(NSString *)decPath newFileName:(NSString *)fileName;

@end
