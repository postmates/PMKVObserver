//
//  PMKVObserver.m
//  PMKVObserver
//
//  Created by Kevin Ballard on 11/18/15.
//  Copyright © 2015 Kevin Ballard. All rights reserved.
//

#import "KVObserver.h"
#import <stdatomic.h>
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

static void *kContext = &kContext;

@interface PMKVObserverDeallocSpy: NSObject
- (instancetype)initWithObserver:(PMKVObserver *)observer shouldBlock:(BOOL)flag NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end

typedef NS_ENUM(uint_fast8_t, PMKVObserverState) {
    PMKVObserverStateSetup = 1 << 0,
    PMKVObserverStateActive = 1 << 1,
    PMKVObserverStateCancellable = (PMKVObserverStateSetup | PMKVObserverStateActive)
};

typedef void (^Callback)(id object, NSDictionary<NSString *,id> * _Nullable change, PMKVObserver *kvo);
typedef void (^ObserverCallback)(id observer, id object, NSDictionary<NSString *,id> * _Nullable change, PMKVObserver *kvo);

@implementation PMKVObserver {
    __weak id _Nullable _object;
    // if we cancel because the object started dealloc, our __weak ivar will be nil already, so we need a non-weak version
    __unsafe_unretained id _Nullable _unsafeObject;
    __weak id _Nullable _observer;
    NSString *_keyPath;
    atomic_uint_fast8_t _state;
    BOOL _hasObserver;
    
    // the callback needs a spinlock because we need to be able to  nil it out in -cancel,
    // but this may happen while an observation block is executing.
    atomic_flag _spinlock;
    id _Nullable _callback;
    
    // cancelling also needs a spinlock because if the object deallocates immediately after -cancel is
    // invoked on another thread, we need to block the object deallocation until the cancel succeeds.
    atomic_flag _cancelSpinlock;
}

+ (instancetype)observeObject:(id)object keyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options block:(void (^)(id object, NSDictionary<NSString *,id> * _Nullable change, PMKVObserver *kvo))block {
    return [[self alloc] initWithObject:object keyPath:keyPath options:options block:block];
}

+ (instancetype)observeObject:(id)object observer:(id)observer keyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options block:(void (^)(id observer, id object, NSDictionary<NSString *,id> * _Nullable change, PMKVObserver *kvo))block {
    return [[self alloc] initWithObserver:observer object:object keyPath:keyPath options:options block:block];
}

- (instancetype)initWithObject:(id)object keyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options block:(Callback)block {
    if ((self = [super init])) {
        _observer = nil;
        _hasObserver = NO;
        
        _object = object;
        _unsafeObject = object;
        _keyPath = [keyPath copy];
        _spinlock = (atomic_flag)ATOMIC_FLAG_INIT;
        _callback = (id)[block copy];
        _cancelSpinlock = (atomic_flag)ATOMIC_FLAG_INIT;
        atomic_init(&_state, PMKVObserverStateActive);
        [self installDeallocSpiesForObject:object observer:nil];
        [object addObserver:self forKeyPath:_keyPath options:options context:kContext];
        if ((atomic_fetch_or(&_state, PMKVObserverStateSetup) & PMKVObserverStateActive) == 0) {
            // we cancelled during init, shut it down
            [self teardown];
        }
    }
    return self;
}

- (instancetype)initWithObserver:(id)observer object:(id)object keyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options block:(void (^)(id observer, id object, NSDictionary<NSString *,id> * _Nullable change, PMKVObserver *kvo))block {
    if ((self = [super init])) {
        _observer = observer;
        _hasObserver = YES;
        
        _object = object;
        _unsafeObject = object;
        _keyPath = [keyPath copy];
        _spinlock = (atomic_flag)ATOMIC_FLAG_INIT;
        _callback = (id)[block copy];
        _cancelSpinlock = (atomic_flag)ATOMIC_FLAG_INIT;
        atomic_init(&_state, PMKVObserverStateActive);
        [self installDeallocSpiesForObject:object observer:observer];
        [object addObserver:self forKeyPath:_keyPath options:options context:kContext];
        if ((atomic_fetch_or(&_state, PMKVObserverStateSetup) & PMKVObserverStateActive) == 0) {
            // we cancelled during init, shut it down
            [self teardown];
        }
    }
    return self;
}

- (instancetype)init {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"-[PMKVObserver init] is not available" userInfo:nil];
}

- (void)cancel {
    [self cancel:NO];
}

- (void)cancel:(BOOL)shouldBlock {
    // because we must unregister KVO before the object finishes deallocating, if `shouldBlock` is set,
    // then we need to enter the spinlock anyway.
    if ((atomic_exchange(&_state, 0) & PMKVObserverStateCancellable) == PMKVObserverStateCancellable || shouldBlock) {
        [self teardown];
    }
}

- (void)teardown {
    while (atomic_flag_test_and_set_explicit(&_cancelSpinlock, memory_order_acquire));
    if (_unsafeObject == nil) {
        // we must have cleared it out in a concurrent teardown
        atomic_flag_clear_explicit(&_cancelSpinlock, memory_order_release);
        return;
    }
    [_unsafeObject removeObserver:self forKeyPath:_keyPath context:kContext];
    _unsafeObject = nil;
    atomic_flag_clear_explicit(&_cancelSpinlock, memory_order_release);
    while (atomic_flag_test_and_set_explicit(&_spinlock, memory_order_acquire));
    _callback = nil;
    atomic_flag_clear_explicit(&_spinlock, memory_order_release);
    [self clearDeallocSpies];
}

- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSString *,id> *)change context:(nullable void *)context {
    if (context != kContext) {
        return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
    if (keyPath == nil || object == nil) {
        // how is this even possible?
        return;
    }
    if ((atomic_load(&_state) & PMKVObserverStateActive) == 0) {
        // we must have cancelled on another thread at the same time. Skip the callback.
        return;
    }
    while (atomic_flag_test_and_set_explicit(&_spinlock, memory_order_acquire));
    id callback = _callback;
    atomic_flag_clear_explicit(&_spinlock, memory_order_release);
    if (!callback) {
        // again, we must have cancelled at the same time. Skip the callback.
        return;
    }
    if (_hasObserver) {
        id observer = _observer;
        if (!observer) {
            // our observer is deallocating. Skip the callback.
            return;
        }
        ((ObserverCallback)callback)(observer, object, change, self);
    } else {
        ((Callback)callback)(object, change, self);
    }
}

- (void)installDeallocSpiesForObject:(id)object observer:(nullable id)observer {
    PMKVObserverDeallocSpy *objectSpy = [[PMKVObserverDeallocSpy alloc] initWithObserver:self shouldBlock:YES];
    void * const key = [self deallocSpyAssociatedObjectKey];
    objc_setAssociatedObject(object, key, objectSpy, OBJC_ASSOCIATION_RETAIN);
    if (observer && observer != object) {
        objectSpy = [[PMKVObserverDeallocSpy alloc] initWithObserver:self shouldBlock:NO];
        objc_setAssociatedObject(observer, key, objectSpy, OBJC_ASSOCIATION_RETAIN);
    }
}

- (void)clearDeallocSpies {
    id object = _object;
    void * const key = [self deallocSpyAssociatedObjectKey];
    if (object) {
        objc_setAssociatedObject(object, key, nil, OBJC_ASSOCIATION_RETAIN);
    }
    id observer = _observer;
    if (observer) {
        objc_setAssociatedObject(observer, key, nil, OBJC_ASSOCIATION_RETAIN);
    }
}

- (void *)deallocSpyAssociatedObjectKey {
    // We could return `self`, but that runs the risk of client code also trying to use us as a key
    // (though that's rather unlikely).
    // So instead lets return a pointer to one of our ivars. Doesn't really matter which one, so
    // we'll go with the first one.
    return &_object;
}
@end

@implementation PMKVObserverDeallocSpy {
    PMKVObserver * _Nonnull _observer;
    BOOL _shouldBlock;
}
- (instancetype)initWithObserver:(PMKVObserver *)observer shouldBlock:(BOOL)flag {
    if ((self = [super init])) {
        _observer = observer;
        _shouldBlock = flag;
    }
    return self;
}

- (void)dealloc {
    [_observer cancel:_shouldBlock];
}
@end

NS_ASSUME_NONNULL_END
