//
//  JXLogFile.m
//  logger
//
//  Created by laoluoro on 2019/8/8.
//  Copyright © 2019 laoluoro. All rights reserved.
//

#import "JXLogFile.h"

#import "JXLogConfig.h"
#import <SSZipArchive/SSZipArchive.h>

@implementation JXLogFile

#pragma mark public
/**
 *  写入字符串到指定文件，默认追加内容
 *
 *  @param filePath   文件路径
 *  @param stringData 待写入的字符串
 */
+ (void)writeFile:(NSString*)filePath stringData:(NSString*)stringData{
    // 待写入的数据
    NSData* writeData = [stringData dataUsingEncoding:NSUTF8StringEncoding];
    
    // NSFileManager 用于处理文件
    BOOL createPathOk = YES;
    if (![[NSFileManager defaultManager] fileExistsAtPath:[filePath stringByDeletingLastPathComponent] isDirectory:&createPathOk]) {
        // 目录不存先创建
        [[NSFileManager defaultManager] createDirectoryAtPath:[filePath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
    }
    if(![[NSFileManager defaultManager] fileExistsAtPath:filePath]){
        // 文件不存在，直接创建文件并写入
        [writeData writeToFile:filePath atomically:NO];
    }else{
        
        // NSFileHandle 用于处理文件内容
        // 读取文件到上下文，并且是更新模式
        NSFileHandle* fileHandler = [NSFileHandle fileHandleForUpdatingAtPath:filePath];
        
        // 跳到文件末尾
        [fileHandler seekToEndOfFile];
        
        // 追加数据
        [fileHandler writeData:writeData];
        
        // 关闭文件
        [fileHandler closeFile];
    }
}

/**
 *  删除日志压缩文件
 */
+ (void)deleteZipFileWithZipFileName:(NSString *)zipFileName {
    
    NSString* zipFilePath = [[JXLogConfig config].basePath stringByAppendingString:zipFileName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:zipFilePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:zipFilePath error:nil];
    }
}

/**
 *  清空过期的日志
 */
+ (void)clearExpiredLog{
    
    // 获取日志目录下的所有文件
    NSArray* files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[JXLogConfig config].basePath error:nil];
    for (NSString* file in files) {
        
        NSDate* date = [[JXLogConfig config].dateFormatter dateFromString:[file stringByReplacingOccurrencesOfString:@".log" withString:@""]];
        if (date) {
            NSTimeInterval oldTime = [date timeIntervalSince1970];
            NSTimeInterval currTime = [[[JXLogConfig config] currentDate] timeIntervalSince1970];
            
            NSTimeInterval second = currTime - oldTime;
            int day = (int)second / (24 * 3600);
            if (day >= [JXLogConfig config].logMaxSaveDay) {
                // 删除该文件
                [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@",[JXLogConfig config].basePath,file] error:nil];
                NSLog(@"[%@]日志文件已被删除！",file);
            }
        }
    }
}

/**
 *  压缩日志
 *
 *  @param dates 日期时间段，空代表全部
 *
 *  @return 执行结果
 */
+ (NSString *)compressLog:(NSArray*)dates{
    
    // 先清理几天前的日志
    [self clearExpiredLog];
    
    // 获取日志目录下的所有文件
    NSArray* files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[JXLogConfig config].basePath error:nil];
    NSString *zipFileName = @"";
    
    // 压缩包文件路径，压缩包的后缀名为最前一天，加上时间戳防止重复上传七牛报错，比如要上传20190514，20190515的日志，压缩包后缀名为：时间戳-20190514-20190515.zip
    if (files.count > 0) {
        NSDate *datenow = [NSDate date];
        NSString *timeSp = [NSString stringWithFormat:@"%ld", (long)([datenow timeIntervalSince1970]*1000)];
        zipFileName = [NSString stringWithFormat:@"%@-%@",timeSp,[self getAppendDateZipName:files]];;
    }
    
    NSString * zipFile = [[JXLogConfig config].basePath stringByAppendingString:zipFileName] ;
    
    // 创建一个zip包
    SSZipArchive *zip = [[SSZipArchive alloc] initWithPath:zipFile];
    BOOL created = [zip open];
    if (!created) {
        // 关闭文件
        [zip close];
        return nil;
    }
    
    if (dates) {
        // 拉取指定日期的
        for (NSString* fileName in files) {
            if ([dates containsObject:fileName]) {
                // 将要被压缩的文件
                NSString *file = [[JXLogConfig config].basePath stringByAppendingString:fileName];
                // 判断文件是否存在
                if ([[NSFileManager defaultManager] fileExistsAtPath:file]) {
                    // 将日志添加到zip包中
                    [zip writeFileAtPath:file withFileName:fileName withPassword:nil];
                }
            }
        }
    }else{
        // 全部
        for (NSString* fileName in files) {
            // 将要被压缩的文件
            NSString *file = [[JXLogConfig config].basePath stringByAppendingString:fileName];
            // 判断文件是否存在
            if ([[NSFileManager defaultManager] fileExistsAtPath:file]) {
                // 将日志添加到zip包中
                [zip writeFileAtPath:file withFileName:fileName withPassword:nil];
            }
        }
    }
    
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    
    // 添加云信日志
    NSString *nimFileName = @"NIMSDK";
    NSString *nimFilePath = [documentPath stringByAppendingPathComponent:nimFileName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:nimFilePath]) {
        NSDirectoryEnumerator *myDirectoryEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:nimFilePath];
        
        BOOL isDir = NO;
        BOOL isExist = NO;
        
        //列举目录内容，可以遍历子目录
        for (NSString *path in myDirectoryEnumerator.allObjects) {
            isExist = [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@/%@", nimFilePath, path] isDirectory:&isDir];
            if (isDir) {
                NSLog(@"%@", path);    // 目录路径
            } else {
                NSLog(@"%@", path);    // 文件路径
                if (isExist) {
                    [zip writeFileAtPath:[NSString stringWithFormat:@"%@/%@",nimFilePath,path] withFileName:[NSString stringWithFormat:@"%@/%@",nimFileName,path] withPassword:nil];
                }
            }
        }
    }
    
    // 添加声网日志
    NSString *agoraFileName = @"Agorasdk.log";
    NSString *agoraFilePath = [documentPath stringByAppendingPathComponent:agoraFileName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:agoraFilePath]) {
        [zip writeFileAtPath:agoraFilePath withFileName:agoraFileName withPassword:nil];
    }
    
    //添加即构日志
    NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    NSString *zegoFileName = @"ZegoLogs";
    NSString *zegoFilePath = [cachesPath stringByAppendingPathComponent:zegoFileName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:zegoFilePath]) {
        NSDirectoryEnumerator *zegoEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:zegoFilePath];
        
        BOOL isDir = NO;
        BOOL isExist = NO;
        
        //列举目录内容，可以遍历子目录
        for (NSString *path in zegoEnumerator.allObjects) {
            //只需要上传text文件就好
            if ([path containsString:@"txt"]) {
                isExist = [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@/%@", nimFilePath, path] isDirectory:&isDir];
            }
            if (isDir) {
                NSLog(@"%@", path);    // 目录路径
            } else {
                NSLog(@"%@", path);    // 文件路径
                if (isExist) {
                    [zip writeFileAtPath:[NSString stringWithFormat:@"%@/%@",zegoFilePath,path] withFileName:[NSString stringWithFormat:@"%@/%@",zegoFilePath,path] withPassword:nil];
                }
            }
        }
    }
    // 关闭文件
    [zip close];
    return zipFileName;
}

+ (NSString *)getAppendDateZipName:(NSArray *)fileArr{
    NSString *returnStr;
    NSString *firstDate = [fileArr firstObject];
    NSString *lastDate = [fileArr lastObject];
    
    NSString *appendDateStr = [NSString string];
    if ([firstDate isEqualToString:lastDate]) {
        //只有一天的日志
        //去掉.log
        NSString *firstDateStr = [firstDate  substringToIndex:firstDate.length-4];
        NSArray *firstDateStrArr = [firstDateStr componentsSeparatedByString:@"-"];
        for (NSString *dateStr in firstDateStrArr) {
            appendDateStr = [appendDateStr stringByAppendingString:dateStr];
        }
        returnStr = [NSString stringWithFormat:@"%@.zip",appendDateStr];
    }else{
        //大于一天的日志
        NSString *tempLastDate = [NSString string];
        //去掉.log
        NSString *firstDateStr = [firstDate  substringToIndex:firstDate.length-4];
        NSString *lastDateStr = [lastDate  substringToIndex:lastDate.length-4];
        NSArray *firstDateStrArr = [firstDateStr componentsSeparatedByString:@"-"];
        NSArray *lastDateStrArr = [lastDateStr componentsSeparatedByString:@"-"];
        for (NSString *dateStr in firstDateStrArr) {
            appendDateStr = [appendDateStr stringByAppendingString:dateStr];
        }
        for (NSString *dateStr in lastDateStrArr) {
            tempLastDate = [tempLastDate stringByAppendingString:dateStr];
        }
        //拼接前后两个时间格式
        returnStr = [NSString stringWithFormat:@"%@-%@.zip",appendDateStr,tempLastDate];
    }
    return returnStr;
}

@end
