
#import <Foundation/Foundation.h>
#if __has_include("RCTBridgeModule.h")
#import "RCTBridgeModule.h"
#else
#import <React/RCTBridgeModule.h>
#endif

@interface RNAutoupdate : NSObject <RCTBridgeModule>

+ (NSURL *)bundleURL;

@end
  
