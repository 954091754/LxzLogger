//
//  JXLogger.m
//  logger
//
//  Created by laoluoro on 2019/8/6.
//  Copyright © 2019 laoluoro. All rights reserved.
//

#import "JXLog.h"

#import <objc/runtime.h>
#import <stdatomic.h>

#define autoreleasebehavior(node, log)                                              \
autoreleasepool {                                                                   \
if ([node respondsToSelector:@selector(willBeginBehavior)]) {                       \
    [node willBeginBehavior]; }                                                     \
if (node.behavior) { node.behavior(log); }                                          \
if ([node respondsToSelector:@selector(didBeginBehavior)]) {                        \
    [node didBeginBehavior]; }                                                      \
}                                                                                   \

#define JX_GENERATE_NODE(name, cls, block, queue, node)                             \
do {                                                                                \
    cls *_node = [cls nodeWithBehavior:[block copy]                                 \
                               queueIn:queue];                                      \
    node = _node;                                                                   \
    node.behaviorName = name;                                                       \
} while(0)                                                                          \

#define JX_FETCH_NODE(name, cls, node)                                              \
do {                                                                                \
    node = (cls *)[[JXLog manager].logBehaviors objectForKey:name];                 \
} while(0)                                                                          \

#define JX_MAP_NODE(name, node, mapTable)                                           \
do {                                                                                \
    id<JXLogBehavior> prev = [mapTable objectForKey:name];                          \
    if (prev) {                                                                     \
        prev.behavior = node.behavior;                                              \
    } else {                                                                        \
        [mapTable setObject:node forKey:name];                                      \
    }                                                                               \
} while(0)                                                                          \

NSString * const JXLOG_CONSOLE_NAME    = @"console";
NSString * const JXLOG_FILE_NAME       = @"file";

static atomic_bool _consoleSet;
static atomic_bool _fileSet;
// All logging statements are added to the same queue to ensure FIFO operation.
static dispatch_queue_t _loggingQueue;

// Individual loggers are executed concurrently per log statement.
// Each logger has it's own associated queue, and a dispatch group is used for synchronization.
static dispatch_group_t _loggingGroup;

static dispatch_semaphore_t _loggingSemaphore;

@interface JXLogBehaviorNode()
@end
@implementation JXLogBehaviorNode
@synthesize queue = _queue;
@synthesize behavior = _behavior;
@synthesize behaviorName = _behaviorName;
@synthesize behaviorCancle = _behaviorCancle;

+ (instancetype)createBehavior:(id<JXLogBehavior>)behavior {
    JXLogBehaviorNode *node = [JXLogBehaviorNode nodeWithBehavior:behavior.behavior queueIn:behavior.queue];
    node.behaviorName = behavior.behaviorName;
    
    {
        Method originalMethod = class_getInstanceMethod([node class], @selector(willBeginBehavior));
        Method swizzleMethod = class_getInstanceMethod([behavior class], @selector(willBeginBehavior));
        method_setImplementation(originalMethod, method_getImplementation(swizzleMethod));
    }
    
    {
        Method originalMethod = class_getInstanceMethod([node class], @selector(didBeginBehavior));
        Method swizzleMethod = class_getInstanceMethod([behavior class], @selector(didBeginBehavior));
        method_setImplementation(originalMethod, method_getImplementation(swizzleMethod));
    }
    
    return node;
}

+ (instancetype)nodeWithBehavior:(nullable jxlog_block_t)behavior queueIn:(nullable jxlog_queue_t)queue {
    return [[JXLogBehaviorNode alloc] initWithBehavior:behavior queueIn:queue];
}

- (instancetype)initWithBehavior:(nullable jxlog_block_t)behavior queueIn:(nullable jxlog_queue_t)queue {
    if ((self = [super init])) {
        if (queue) {
            _queue = queue;
        } else {
            const char *queueName = NULL;
            
            if ([self respondsToSelector:@selector(behaviorName)]) {
                queueName = [[self behaviorName] UTF8String];
            }
            
            _queue = dispatch_queue_create(queueName, NULL);
            
            void *key = (__bridge void *)self;
            void *nonNullValue = (__bridge void *)self;
            
            dispatch_queue_set_specific(_queue, key, nonNullValue, NULL);
        }
        
        _behavior = behavior;
    }
    return self;
}

- (nonnull JXLogBehaviorNode *)concat:(nullable JXLogBehaviorNode *)behavior content:(id<JXLogContent>)content {
    if (behavior && !behavior.behaviorCancle && behavior.behavior)
        dispatch_group_async(_loggingGroup, behavior.queue, ^{
            @autoreleasebehavior(behavior, content);
        });
    return self;
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return [JXLogBehaviorNode createBehavior:self];
}

@end

static void *const GlobalLoggingQueueIdentityKey = (void *)&GlobalLoggingQueueIdentityKey;

@interface JXLog()

@property (nonatomic, strong) NSMapTable<NSString *, id<JXLogBehavior>> *logBehaviors;

@end

@implementation JXLog

+ (instancetype)manager {
    static dispatch_once_t onceToken;
    static JXLog *manager;
    dispatch_once(&onceToken, ^{
        manager = [[JXLog alloc] init];
    });
    return manager;
}

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _loggingQueue = dispatch_queue_create("jx.log", NULL);
        _loggingGroup = dispatch_group_create();
        
        void *nonNullValue = GlobalLoggingQueueIdentityKey;
        dispatch_queue_set_specific(_loggingQueue, GlobalLoggingQueueIdentityKey, nonNullValue, NULL);
        
        _loggingSemaphore = dispatch_semaphore_create(1);
    });
}

+ (void)log:(JXLogOptions)opts content:(id<JXLogContent>)content {
    dispatch_semaphore_wait(_loggingSemaphore, DISPATCH_TIME_FOREVER);
    dispatch_barrier_async(_loggingQueue, ^{
        [self defineDefaultBehavior:opts content:content];
        dispatch_group_wait(_loggingGroup, DISPATCH_TIME_FOREVER);
    });
    dispatch_semaphore_signal(_loggingSemaphore);
}

- (instancetype)init {
    if (self = [super init]) {
        _logBehaviors = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsCopyIn valueOptions:NSPointerFunctionsStrongMemory];
        
        JXLogBehaviorNode *consoleNode, *fileNode = nil;
        
        JX_GENERATE_NODE(JXLOG_CONSOLE_NAME, JXLogBehaviorNode, (jxlog_block_t)nil, nil, consoleNode);
        JX_GENERATE_NODE(JXLOG_FILE_NAME, JXLogBehaviorNode, (jxlog_block_t)nil, nil, fileNode);
        
        JX_MAP_NODE(JXLOG_CONSOLE_NAME, consoleNode, _logBehaviors);
        JX_MAP_NODE(JXLOG_FILE_NAME, fileNode, _logBehaviors);
    }
    return self;
}

+ (void)defineDefaultBehavior:(JXLogOptions)opts content:(id<JXLogContent>)content {
    JXLogBehaviorNode *consoleNode, *fileNode= nil;
    JXLogBehaviorNode *logNode = [JXLogBehaviorNode new];
    
    JX_FETCH_NODE(JXLOG_CONSOLE_NAME, JXLogBehaviorNode, consoleNode);
    JX_FETCH_NODE(JXLOG_FILE_NAME, JXLogBehaviorNode, fileNode);

    if (opts & JXLogOpt_Console) {
        consoleNode.behaviorCancle = false;
    } else {
        consoleNode.behaviorCancle = true;
    }
    
    if (opts & JXLogOpt_File) {
        fileNode.behaviorCancle = false;
    } else {
        fileNode.behaviorCancle = true;
    }
    
    [[logNode concat:consoleNode content:content] concat:fileNode content:content];
}

+ (void)defineBehavior:(id<JXLogBehavior>)behavior  {
    BOOL r = 1, e = 0;
    if ([behavior.behaviorName isEqualToString:JXLOG_FILE_NAME]) {
        r = atomic_compare_exchange_strong(&_fileSet, &e, 0);
    }
    if ([behavior.behaviorName isEqualToString:JXLOG_CONSOLE_NAME]) {
        r = atomic_compare_exchange_strong(&_consoleSet, &e, 0);
    }
    if (r) {
        JX_MAP_NODE(behavior.behaviorName, behavior, [JXLog manager].logBehaviors);
    }
}

+ (void)defineBehavior_f:(jxlog_block_t)behavior for:(NSString *)name {
    id<JXLogBehavior> _behavior = [[JXLog manager].logBehaviors objectForKey:name];
    if (_behavior) {
        _behavior.behavior = behavior;
    }
}

- (void)dealloc {
    NSEnumerator *behaviors = self.logBehaviors.objectEnumerator;
    for (id<JXLogBehavior> behavior in behaviors) {
        behavior.behavior = nil;
    }
}

@end
