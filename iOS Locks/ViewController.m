//
//  ViewController.m
//  iOS Locks
//
//  Created by BlueDancer on 2019/4/29.
//  Copyright © 2019 SanJiang. All rights reserved.
//

#import "ViewController.h"

@import Darwin.libkern.OSAtomic;
void _osspinLock(void) {
    // OSSpinLock不推荐使用了, 特别是不同优先级的线程在同一个自旋锁上.
    
    OSSpinLock spinLock = OS_SPINLOCK_INIT;
    
    OSSpinLockLock(&spinLock);
    //    OSSpinLockTry(&spinLock);
    // ....
    OSSpinLockUnlock(&spinLock);
}

@import os.lock;
void _unfairLock(void) {
    // os_unfair_lock iOS 10.0 之后可用. 跟踪汇编调用过程看起来是 互斥锁.
    
    os_unfair_lock unfairLock = OS_UNFAIR_LOCK_INIT;
    
    os_unfair_lock_lock(&unfairLock);
    //    os_unfair_lock_trylock(&unfairLock);
    // ...
    os_unfair_lock_unlock(&unfairLock);
}

void _dispatch_semaphore(void) {
    // semaphore. 推荐使用. 在 iOS 中使用率比较高, 源码调用的内核函数. 稍次于 `os_unfair_lock`, 高版本可以使用 `os_unfair_lock`, 低版本使用`semaphore`
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    // ...
    dispatch_semaphore_signal(semaphore);
}

#import <pthread.h>
void _pthread_mutexLock(void) {
    // 跨平台. 推荐使用
    
    pthread_mutexattr_t mutexAttr;
    pthread_mutexattr_init(&mutexAttr);
    pthread_mutexattr_settype(&mutexAttr, PTHREAD_MUTEX_DEFAULT);
    
    pthread_mutex_t mutexLock;
    pthread_mutex_init(&mutexLock, &mutexAttr);
    pthread_mutexattr_destroy(&mutexAttr);
    
    pthread_mutex_lock(&mutexLock);
    // ...
    pthread_mutex_unlock(&mutexLock);
    
    pthread_mutex_destroy(&mutexLock);
}

#import <pthread.h>
void _pthread_recursive_lock(void) {
    pthread_mutexattr_t mutexAttr;
    pthread_mutexattr_init(&mutexAttr);
    pthread_mutexattr_settype(&mutexAttr, PTHREAD_MUTEX_RECURSIVE);
    
    pthread_mutex_t mutexLock;
    pthread_mutex_init(&mutexLock, &mutexAttr);
    pthread_mutexattr_destroy(&mutexAttr);
    
    pthread_mutex_lock(&mutexLock);
    // ...
    {
        pthread_mutex_lock(&mutexLock);
        // ...
        pthread_mutex_unlock(&mutexLock);
    }
    // ...
    pthread_mutex_unlock(&mutexLock);
    
    pthread_mutex_destroy(&mutexLock);
}

void _NSLock(void) {
    // pthread_mutex 的封装
    
    NSLock *lock = [NSLock new];
    
    [lock lock];
    // ...
    [lock unlock];
}

void _NSCondition(void) {
    // pthread_mutex 的封装
    
    static int condition = 0;
    
    NSCondition *lock = [[NSCondition alloc] init];
    
    /// thread 0
    { ///< wait
        [lock lock];
        
        if ( condition == 0 )
            [lock wait];
        // ...
        
        [lock unlock];
    }
    
    
    /// thread 1
    { ///< signal
        [lock lock];
        
        // ...
        condition += 1;
        
        [lock unlock];
        
        [lock signal]; //  or [lock broadcast];
    }
}

void _NSRecursiveLock(void) {
    // pthread_mutex_recursive 的封装
    
    NSRecursiveLock *lock = [NSRecursiveLock new];
    
    [lock lock]; {
        [lock lock]; {
            [lock lock];
            // ...
            [lock unlock];
        } [lock unlock];
    } [lock unlock];
}

void _NSConditionLock(void) {
    // pthread_mutex 的封装
    
    NSConditionLock *lock = [[NSConditionLock alloc] initWithCondition:0];
    
    // thread 0
    [lock lock];
    // ....
    [lock unlockWithCondition:1];
    
    // thread 1
    [lock lockWhenCondition:1];
    // ...
    [lock unlockWithCondition:2];
    
    // thread 2
    [lock lockWhenCondition:2];
    [lock unlock];
}

void _synchronized(id self) {
    // pthread_mutex_recursive 的封装
    
    @synchronized (self) {
        // ...
        @synchronized (self) {
            // ...
            @synchronized (self) {
                // ...
            }
        }
    }
}



NS_ASSUME_NONNULL_BEGIN
@interface ViewController ()

@end

@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}
@end
NS_ASSUME_NONNULL_END
