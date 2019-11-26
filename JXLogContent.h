//
//  JXLogContent.h
//  logger
//
//  Created by laoluoro on 2019/8/8.
//  Copyright © 2019 laoluoro. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "JXLog.h"
NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger , JXLogLevel) {
    JXLOGLEVEL_CONSOLEANDFILE = 1,   ///输出在控制台和日志文件里
    JXLOGLEVEL_CONSOLE,              ///输出在控制台
    JXLOGLEVEL_FILE                  ///输出在日志文件里
};

@interface JXLogContent : NSObject <JXLogContent>

@property (nonatomic, copy, readonly) NSString *fileLog;
@property (nonatomic, copy, readonly) NSString *consoleLog;

@end

@interface JXLog (Custom)

+ (void)logInfo:(NSString*)module
      withLevel:(JXLogLevel)level
         logStr:(nonnull NSString *)logStr, ...;

@end

NS_ASSUME_NONNULL_END
