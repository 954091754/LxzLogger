//
//  JXLogFile.h
//  logger
//
//  Created by laoluoro on 2019/8/8.
//  Copyright © 2019 laoluoro. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "JXLog.h"

NS_ASSUME_NONNULL_BEGIN

@interface JXLogFile : NSObject

/**
 *  写入字符串到指定文件，默认追加内容
 *
 *  @param filePath   文件路径
 *  @param stringData 待写入的字符串
 */
+ (void)writeFile:(NSString*)filePath stringData:(NSString*)stringData;

/**
 *  删除日志压缩文件
 */
+ (void)deleteZipFileWithZipFileName:(NSString *)zipFileName;

/**
 *  清空过期的日志
 */
+ (void)clearExpiredLog;

/**
 *  压缩日志
 *
 *  @param dates 日期时间段，空代表全部
 *
 *  @return 执行结果
 */
+ (NSString *)compressLog:(NSArray*)dates;

@end

NS_ASSUME_NONNULL_END
