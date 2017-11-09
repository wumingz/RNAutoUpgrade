//
//  RNAutoupgradeDownloader.h
//  RNAutoupgrade
//
//  Created by 吴明志 on 2017/9/12.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^AutoUpgradeProgressHandler)(long long, long long);
typedef void(^AutoUpgradeCompletionHandler)(NSString *path, NSError *error);

@interface RNAutoupgradeDownloader : NSObject


/**
 下载更新包文件
 
 @param downloadPath 下载地址
 @param savePath 本地保存路径
 @param progressHandler 下载进度的回调
 @param completionHandler 下载完成的回调
 */
+ (void)download:(NSString *)downloadPath savePath:(NSString *)savePath
 progressHandler:(AutoUpgradeProgressHandler )progressHandler
completionHandler:(AutoUpgradeCompletionHandler)completionHandler;



@end
