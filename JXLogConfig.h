//
//  JXLogConfig.h
//  logger
//
//  Created by laoluoro on 2019/8/6.
//  Copyright © 2019 laoluoro. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "JXLog.h"

NS_ASSUME_NONNULL_BEGIN

/**
 ** 日志文件的格式：[时间]-[版本信息]-[模块]-[uid]-日志内容
 ** 日志控制台的格式：[版本信息]-[模块]-[uid]-日志内容
 **/
@interface JXLogConfig: NSObject

@property (nonatomic, copy, readwrite) NSString *basePath; // 日志的目录路径
@property (nonatomic, copy, readwrite) NSString *fileName; // 获取当前日期做为文件名
@property (nonatomic, copy, readwrite) NSString *uid;
@property (nonatomic, assign, readwrite) NSInteger logMaxSaveDay; // 日志保留最大天数

@property (nonatomic, copy, readonly) NSString *versionData; // 程序版本号
@property (nonatomic, copy, readonly) NSString *buildData; // 获取APP build版本
@property (nonatomic, copy, readonly) NSString *fileCompletePath; // 日志文件保存目录
@property (nonatomic, strong, readonly) NSDateFormatter *dateFormatter; // 日期格式化
@property (nonatomic, strong, readonly) NSDateFormatter *timeFormatter; // 日期时间格式化

+ (instancetype)config;
- (void)defineNode;
- (NSDate *)currentDate;

@end


NS_ASSUME_NONNULL_END
