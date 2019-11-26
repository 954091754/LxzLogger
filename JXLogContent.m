//
//  JXLogContent.m
//  logger
//
//  Created by laoluoro on 2019/8/8.
//  Copyright © 2019 laoluoro. All rights reserved.
//

#import "JXLogContent.h"

#import "JXLogConfig.h"
@interface JXLogContent ()

@property (nonatomic, copy, readwrite) NSString *fileLog;
@property (nonatomic, copy, readwrite) NSString *consoleLog;

@end

@implementation JXLogContent
@end

@implementation JXLog (Custom)

#pragma mark 接口兼容
+ (void)logInfo:(NSString*)module
      withLevel:(JXLogLevel)level
         logStr:(nonnull NSString *)logStr, ... {
    JXLogContent *content = [[JXLogContent alloc] init];
    
    NSMutableString* paramStr = [NSMutableString string];
    // 声明一个参数指针
    va_list paramList;
    // 获取参数地址，将paramList指向logStr
    va_start(paramList, logStr);
    
    id arg = logStr;
    
    @try {
        // 遍历参数列表
        while (arg) {
            [paramStr appendString:[@"-" stringByAppendingString:arg]];
            // 指向下一个参数，后面是参数类似
            arg = va_arg(paramList, NSString*);
        }
        
    } @catch (NSException *exception) {
        [paramStr appendString:@"【记录日志异常】"];
    } @finally {
        // 将参数列表指针置空
        va_end(paramList);
    }
    
    JXLogOptions opts = 0;
    if (level == JXLOGLEVEL_CONSOLE) {
        opts = JXLogOpt_Console;
    }   else if (level == JXLOGLEVEL_FILE) {
        opts = JXLogOpt_File;
    } else if (level == JXLOGLEVEL_CONSOLEANDFILE) {
        opts |= (JXLogOpt_File | JXLogOpt_Console);
    }

    NSString *versionAndBuildData = [NSString stringWithFormat:@"VERSION:%@, BUILD:%@",[JXLogConfig config].versionData,[JXLogConfig config].buildData];
    //日志控制台的格式：//格式：[版本信息]-[模块]-[uid]-日志内容
    NSString *consoleStr = [NSString stringWithFormat:@"[[%@]-[%@]-[%@]-[%@]\n", versionAndBuildData, module, [JXLogConfig config].uid, paramStr];
    
    //日志文件的格式：[时间]-[版本信息]-[模块]-[uid]-日志内容
    NSString* timeStr = [[JXLogConfig config].timeFormatter stringFromDate:[[JXLogConfig config] currentDate]];
    NSString* writeStr = [NSString stringWithFormat:@"[%@]-[%@]-[%@]-[%@]-[%@]\n",timeStr, versionAndBuildData, module, [JXLogConfig config].uid, paramStr];

    
    content.fileLog = writeStr;
    content.consoleLog = consoleStr;
    [JXLog log:opts content:content];
}

@end
