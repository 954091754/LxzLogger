//
//  JXLogConfig.m
//  logger
//
//  Edited by laoluoro on 2019/8/6.
//  Copyright © 2019 laoluoro. All rights reserved.
//

#import "JXLogConfig.h"

#import "JXLogFile.h"
#import "JXLogContent.h"

@interface JXLogConfig()

@property (nonatomic, strong, readwrite) NSDateFormatter *dateFormatter;
@property (nonatomic, strong, readwrite) NSDateFormatter *timeFormatter;

@property (nonatomic, copy, readwrite) NSString *versionData;
@property (nonatomic, copy, readwrite) NSString *buildData;
@property (nonatomic, copy, readwrite) NSString *fileCompletePath;

@end

@implementation JXLogConfig

+ (nonnull instancetype)config {
    static dispatch_once_t onceToken;
    static JXLogConfig *shareInstance;
    dispatch_once(&onceToken, ^{
        shareInstance = [[JXLogConfig alloc] init];
    });
    return shareInstance;
}

- (NSDate *)currentDate {
    NSDate *date = [NSDate date];
    NSTimeZone *zone = [NSTimeZone systemTimeZone];
    NSInteger interval = [zone secondsFromGMTForDate: date];
    NSDate *localeDate = [date dateByAddingTimeInterval: interval];
    
    return localeDate;
}

- (void)defineNode {
    /** file node **/
    __weak typeof(self) weakSelf = self;
    [JXLog defineBehavior_f:^(id<JXLogContent> content) {
        JXLogContent *hdContent = (JXLogContent *)content;
        JXLogDebug(@"%@", hdContent.fileLog);
        [JXLogFile writeFile:weakSelf.fileCompletePath stringData:hdContent.fileLog];
    } for:JXLOG_FILE_NAME];
    /** console node **/
    [JXLog defineBehavior_f:^(id<JXLogContent> content) {
        JXLogContent *hdContent = (JXLogContent *)content;
        JXLogDebug(@"%@", hdContent.consoleLog);
    } for:JXLOG_CONSOLE_NAME];
    /** log format **/
}


#pragma mark getter - static
- (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        // 创建日期格式化，文件夹时间
        NSDateFormatter* dateFormatter = [[NSDateFormatter alloc]init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd"];
        // 设置时区，解决8小时
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
        _dateFormatter = dateFormatter;
    }
    return _dateFormatter;
}

- (NSDateFormatter *)timeFormatter {
    if (!_timeFormatter) {
        NSDateFormatter* timeFormatter = [[NSDateFormatter alloc]init];
        [timeFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss:SSS"];
        [timeFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
        _timeFormatter = timeFormatter;
    }
    return _timeFormatter;
}

- (NSString *)basePath {
    if (!_basePath) {
        _basePath = [NSString stringWithFormat:@"%@%@",NSHomeDirectory(), @"/Documents/JXLog/"];
    }
    return _basePath;
}

- (NSString *)versionData {
    if (!_versionData) {
        _versionData = [NSString stringWithFormat:@"%@",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
    }
    return _versionData;
}

- (NSInteger)logMaxSaveDay {
    if (!_logMaxSaveDay) {
        _logMaxSaveDay = 15;
    }
    return _logMaxSaveDay;
}

- (NSString *)buildData {
    if (!_buildData) {
        _buildData = [NSString stringWithFormat:@"%@",[[[NSBundle mainBundle] infoDictionary]
                                                       objectForKey:@"CFBundleVersion"]];
    }
    return _buildData;
}

#pragma mark getter - dynamic
- (NSString *)fileName {
    _fileName = [NSString stringWithFormat:@"%@.log",[self.dateFormatter stringFromDate:[NSDate date]]];
    return _fileName;
}

- (NSString *)fileCompletePath {
    _fileCompletePath = [self.basePath stringByAppendingString:self.fileName];
    return _fileCompletePath;
}


@end
