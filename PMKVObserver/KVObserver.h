//
//  KVObserver.h
//  PMKVObserver
//
//  Created by Kevin Ballard on 11/18/15.
//  Copyright © 2015 Postmates. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
//  http://www.apache.org/licenses/LICENSE-2.0> or the MIT license
//  <LICENSE-MIT or http://opensource.org/licenses/MIT>, at your
//  option. This file may not be copied, modified, or distributed
//  except according to those terms.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/// A class that manages a single KVO observation.
///
/// This class does not retain the observed object, and if the observed object deallocates,
/// this class automatically unregisters the KVO.
/// An observing object may also be provided. If it is, it is also not retained, and if the
/// observering object deallocates, this class automatically unregisters the KVO.
///
/// In Swift, the initializers and callbacks provide a strongly-typed access to the observed object.
/// In Objective-C, the initializers and callbacks use <tt>id</tt>.
///
/// This class is thread-safe and observation and deregistration may occur on any thread.
/// Deregistration may also occur within the initial callback when using
/// <tt>NSKeyValueObservingOptions.Initial</tt>. It's safe for the callback block to retain
/// the <tt>KVObserver</tt>, but because it's awkward to set that up, the callback is provided
/// with the \c KVObserver object as well. However, the callback should not retain \c object or
/// \c observer (if provided).
///
/// If the observing object does not want to unregister the KVO (until either it or the observed
/// object deallocates), it may freely discard this class instance. It only needs to hold onto
/// this class instance if it wants to unregister manually.
///
/// @note If observing a key path with multiple components, and one of those components is a
/// \c weak reference, if the referenced object deallocates without sending any KVO events for
/// the property, then this will likely result in an exception. This is due to how KVO works and
/// cannot be handled by <tt>KVObserver</tt>.
///
/// @note Any observed object must support weak references, and when using the optional observing
/// object support, it also must support weak references.
#if defined(__has_attribute) && __has_attribute(objc_subclassing_restricted)
__attribute__((objc_subclassing_restricted))
#endif
@interface PMKVObserver : NSObject
/// Establishes a KVO relationship to <tt>object</tt>. The KVO will be active until \c object deallocates or
/// until the \c cancel() method is invoked.
+ (instancetype)observeObject:(id)object keyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options block:(void (^)(id object, NSDictionary<NSKeyValueChangeKey,id> * _Nullable change, PMKVObserver *kvo))block NS_SWIFT_UNAVAILABLE("use init(object:keyPath:options:block:)");

/// Establishes a KVO relationship to <tt>object</tt>. The KVO will be active until either \c object or
/// \c observer deallocates or until the \c cancel() method is invoked.
+ (instancetype)observeObject:(id)object observer:(id)observer keyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options block:(void (^)(id observer, id object, NSDictionary<NSKeyValueChangeKey,id> * _Nullable change, PMKVObserver *kvo))block NS_SWIFT_UNAVAILABLE("use init(observer:object:keyPath:options:block:)");

/// Establishes a KVO relationship to <tt>object</tt>. The KVO will be active until \c object deallocates or
/// until the \c cancel() method is invoked.
- (instancetype)initWithObject:(id)object keyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options block:(void (^)(id object, NSDictionary<NSKeyValueChangeKey,id> * _Nullable change, PMKVObserver *kvo))block NS_DESIGNATED_INITIALIZER NS_REFINED_FOR_SWIFT;

/// Establishes a KVO relationship to <tt>object</tt>. The KVO will be active until either \c object or
/// \c observer deallocates or until the \c cancel() method is invoked.
- (instancetype)initWithObserver:(id)observer object:(id)object keyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options block:(void (^)(id observer, id object, NSDictionary<NSKeyValueChangeKey,id> * _Nullable change, PMKVObserver *kvo))block NS_DESIGNATED_INITIALIZER NS_REFINED_FOR_SWIFT;

- (instancetype)init NS_UNAVAILABLE;

/// Unregisters the KVO. This can be called multiple times and can be called from any thread.
- (void)cancel;

/// Returns \c YES iff the observer has already been cancelled.
///
/// Returns \c YES if \c -cancel has been invoked on any thread. If \c -cancel is invoked
/// concurrently with accessing this property, it may or may not see the cancellation depending
/// on the precise timing involved.
///
/// \note This property does not support key-value observing.
@property (atomic, readonly, getter=isCancelled) BOOL cancelled __attribute__((swift_private));
@end

NS_ASSUME_NONNULL_END
