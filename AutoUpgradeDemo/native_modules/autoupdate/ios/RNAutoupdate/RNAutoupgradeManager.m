//
//  RNAutoupgradeManager.m
//  RNAutoupgrade
//
//  Created by 吴明志 on 2017/9/12.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "RNAutoupgradeManager.h"
#import "ZipArchive.h"
#import "BSDiff.h"
#import "bspatch.h"

static RNAutoupgradeManager *_manager = nil;

@implementation RNAutoupgradeManager{
    dispatch_queue_t _opQueue;
}

//单例类
+ (RNAutoupgradeManager *)sharedInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manager = [[RNAutoupgradeManager alloc] init];
    });
    return _manager;
}

- (instancetype)init{
    if (self = [super init]) {
        //创建串形线程队列
        _opQueue = dispatch_queue_create("cn.reactnative.autoUpdate", DISPATCH_QUEUE_SERIAL);
    }
    
    return self;
}


//创建文件路径
- (BOOL)createDir:(NSString *)dir{
    
    __block BOOL success = NO;
    
    dispatch_sync(_opQueue, ^{
        BOOL isDir;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:dir isDirectory:&isDir]) {
            if (isDir) {
                success = YES;
                return;
            }
        }
        
        NSError *error = 0;
        [fileManager createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:&error];
        if (!error) {
            success = YES;
            return;
        }
        
    });
    
    return success;
}

//创建文件路径
- (BOOL)createDirNew:(NSString *)dir{
    BOOL isDir;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:dir isDirectory:&isDir]) {
        if (isDir) {
            return true;
        }
    }

    NSError *error = 0;
    [fileManager createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:&error];
    if (!error) {
        return true;
    }
    
    return false;
}


//解压文件
- (void)unzipFileAtPath:(NSString *)path
          toDestination:(NSString *)destination
        progressHandler:(void (^)(NSString *entry, long entryNumber, long total))progressHandler
      completionHandler:(void (^)(NSString *path, BOOL succeeded, NSError *error))completionHandler
{
    dispatch_async(_opQueue, ^{
        
//        if ([[NSFileManager defaultManager] fileExistsAtPath:destination]) {
//            [[NSFileManager defaultManager] removeItemAtPath:destination error:nil];
//        }
        
        
        
        [SSZipArchive unzipFileAtPath:path toDestination:destination progressHandler:^(NSString *entry, unz_file_info zipInfo, long entryNumber, long total) {
            
            progressHandler(entry, entryNumber, total);
        } completionHandler:^(NSString *path, BOOL succeeded, NSError *error) {
            // 解压完，移除zip文件
            [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
            if (completionHandler) {
                completionHandler(path, succeeded, error);
            }
        }];
    });
}


//差量运算合成新包
- (void)bsdiffFileAtPath:(NSString *)path
              fromOrigin:(NSString *)origin
           toDestination:(NSString *)destination
       completionHandler:(void (^)(BOOL success))completionHandler
{
    dispatch_async(_opQueue, ^{
        BOOL success = [BSDiff bsdiffPatch:path origin:origin toDestination:destination];
        if (completionHandler) {
            completionHandler(success);
        }
    });
}


//复制本地资源到新版本
- (void)copyFilesfromDir:(NSString *)fromDir toDir:(NSString *)toDir completionHandler:(void (^)(NSError *error))completionHandler{
    dispatch_sync(_opQueue, ^{
        NSFileManager *fm = [NSFileManager defaultManager];
       
        NSString *srcDir = [fromDir stringByAppendingPathComponent:@"assets"];
        NSString *desDir = [toDir stringByAppendingPathComponent:@"assets"];
        
        //app中判断是否有资源包
        if(![fm fileExistsAtPath:srcDir]) {
            if (completionHandler) {
                completionHandler(nil);
            }
            return;
        }
        
        //版本已经存在资源包就返回
        if([fm fileExistsAtPath:desDir]) {
            if (completionHandler) {
                completionHandler(nil);
            }
            return;
        }
        
        BOOL result = [self createDirNew:toDir];
        if (!result) {
            NSLog(@"创建路径失败==%@",toDir);
            NSError *error = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:4 userInfo:@{@"4":@"创建路径失败"}];
            if (completionHandler) {
                completionHandler(error);
            }
            return;
        }
        
        NSError *error = nil;
        [fm copyItemAtPath:srcDir toPath:desDir error:&error];
        if (error) {
            if (completionHandler) {
                completionHandler(error);
            }
        }else{
            if (completionHandler) {
                completionHandler(nil);
            }
        }
    });
}


//移除资源包中废弃文件
- (void)deleteFiles:(NSDictionary *)filesDic
          fromDir:(NSString *)toDir
completionHandler:(void (^)(NSError *error))completionHandler
{
    dispatch_async(_opQueue, ^{
        NSFileManager *fm = [NSFileManager defaultManager];
        
        // delete old files
        if (filesDic!= nil) {
            for (NSString *to in filesDic.allKeys) {
                NSString *toPath = [toDir stringByAppendingPathComponent:to];
    
                if ([fm fileExistsAtPath:toPath]) {
                    [fm removeItemAtPath:toPath error:nil];
                }
            }
        }
        
        if (completionHandler) {
            completionHandler(nil);
        }
        
    });
}


//移除文件
- (void)removeFile:(NSString *)filePath
 completionHandler:(void (^)(NSError *error))completionHandler
{
    dispatch_async(_opQueue, ^{
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
        if (completionHandler) {
            completionHandler(error);
        }
    });
}


//移动文件位置
-(BOOL)moveFileAtPath:(NSString *)srcPath toPath:(NSString *)decPath newFileName:(NSString *)fileName{
    
    NSFileManager *fm = [NSFileManager defaultManager];
        
    BOOL result = NO;
    NSError * error = nil;
    result = [fm moveItemAtPath:[srcPath stringByAppendingPathComponent:fileName] toPath:[decPath stringByAppendingPathComponent:fileName] error:&error];
        
    return result;
}


@end
