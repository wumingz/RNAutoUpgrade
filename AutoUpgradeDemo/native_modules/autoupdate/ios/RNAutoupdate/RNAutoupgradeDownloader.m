//
//  RNAutoupgradeDownloader.m
//  RNAutoupgrade
//
//  Created by 吴明志 on 2017/9/12.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "RNAutoupgradeDownloader.h"


@interface RNAutoupgradeDownloader()<NSURLSessionDownloadDelegate>

@property (nonatomic, strong) AutoUpgradeProgressHandler progressHandler;
@property (nonatomic, strong) AutoUpgradeCompletionHandler completionHandler;
@property (nonatomic, retain) NSString *savePath;

@end

@implementation RNAutoupgradeDownloader

+ (void)download:(NSString *)downloadPath savePath:(NSString *)savePath
 progressHandler:(AutoUpgradeProgressHandler )progressHandler
completionHandler:(AutoUpgradeCompletionHandler)completionHandler{
    
    NSAssert(downloadPath, @"no download path");
    NSAssert(savePath, @"no save path");
    
    RNAutoupgradeDownloader *downloader = [RNAutoupgradeDownloader new];
    downloader.progressHandler = progressHandler;
    downloader.completionHandler = completionHandler;
    downloader.savePath = savePath;
    
    [downloader download:downloadPath];
}

-(void)download:(NSString *)path{
    
    NSURL *url = [NSURL URLWithString:path];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    
    NSURLSessionDownloadTask *task = [session downloadTaskWithURL:url];
    [session downloadTaskWithURL:url];
    [task resume];
}

#pragma mark -- NSUrlSession Delegate
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    
#ifdef DEBUG
    NSLog(@"download progress, %lld, %lld, %lld", bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
#endif
    
    self.progressHandler? self.progressHandler(totalBytesWritten, totalBytesExpectedToWrite): nil;
    
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location{
    
    NSData *data = [NSData dataWithContentsOfURL:location];
    NSError *error;
    [data writeToFile:self.savePath options:NSDataWritingAtomic error:&error];
    if (error) {
        if (self.completionHandler) {
            self.completionHandler(nil, error);
            self.completionHandler = nil;
        }
    }
    
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    
    if (self.completionHandler) {
        self.completionHandler(self.savePath, error);
    }
}



@end
