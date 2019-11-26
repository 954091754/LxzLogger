//
//  JXLogger.h
//  logger
//
//  Created by laoluoro on 2019/8/6.
//  Copyright © 2019 laoluoro. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, JXLogOptions) {
#ifdef ZegoLog
    JXLogOpt_Zego       = 1 << 2,
#endif
#ifdef AgoraLog
    JXLogOpt_Agora      = 1 << 3,
#endif
#ifdef NIMLog
    JXLogOpt_NIM        = 1 << 4,
#endif
    JXLogOpt_Console    = 1 << 0,
    JXLogOpt_File       = 1 << 1,
};

@protocol JXLogContent <NSObject>
@end

typedef void(^jxlog_block_t)(id<JXLogContent>);
typedef dispatch_queue_t jxlog_queue_t;

@protocol JXLogBehavior <NSObject, NSCopying>

@property (nonatomic, copy) NSString *behaviorName;
@property (nonatomic, assign) BOOL behaviorCancle;

@optional
@property (nonatomic, strong) _Nullable jxlog_block_t behavior;
@property (nonatomic, strong) _Nullable jxlog_queue_t queue;

- (void)willBeginBehavior;
- (void)didBeginBehavior;

@required
+ (instancetype)createBehavior:(id<JXLogBehavior>)behavior;
+ (instancetype)nodeWithBehavior:(nullable jxlog_block_t)behavior
                         queueIn:(nullable jxlog_queue_t)queue;

@end

@interface JXLogBehaviorNode: NSObject <JXLogBehavior>
@end

FOUNDATION_EXTERN NSString * const JXLOG_CONSOLE_NAME;
FOUNDATION_EXTERN NSString * const JXLOG_FILE_NAME;

#ifndef JX_DEBUG
#define JX_DEBUG 1
#endif

#define JXLogDebug(frmt, ...)                                                       \
do {                                                                                \
    if (JX_DEBUG)                                                                   \
        NSLog((frmt), ##__VA_ARGS__);                                               \
} while(0)                                                                          \

@interface JXLog : NSObject

+ (void)log:(JXLogOptions)opts
       content:(id<JXLogContent>)content;
+ (void)defineBehavior:(id<JXLogBehavior>)behavior;
+ (void)defineBehavior_f:(jxlog_block_t)behavior for:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
