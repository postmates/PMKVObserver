//
//  KVObserver.swift
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

import Foundation

public typealias KVObserver = PMKVObserver

extension KVObserver {
    /// Establishes a KVO relationship to `object`. The KVO will be active until `object` deallocates or
    /// until the `cancel()` method is invoked.
    public convenience init<Object: AnyObject>(object: Object, keyPath: String, options: NSKeyValueObservingOptions = [], block: (object: Object, change: Change, kvo: KVObserver) -> Void) {
        self.init(__object: object, keyPath: keyPath, options: options, block: { (object, change, kvo) in
            block(object: unsafeDowncast(object, to: Object.self), change: Change(rawDict: change), kvo: kvo)
        })
    }
    
    /// Establishes a KVO relationship to `object`. The KVO will be active until either `object` or `observer`
    /// deallocates or until the `cancel()` method is invoked.
    public convenience init<T: AnyObject, Object: AnyObject>(observer: T, object: Object, keyPath: String, options: NSKeyValueObservingOptions = [], block: (observer: T, object: Object, change: Change, kvo: KVObserver) -> Void) {
        self.init(__observer: observer, object: object, keyPath: keyPath, options: options, block: { (observer, object, change, kvo) in
            block(observer: unsafeDowncast(observer, to: T.self), object: unsafeDowncast(object, to: Object.self), change: Change(rawDict: change), kvo: kvo)
        })
    }
    
    /// A type that provides type-checked accessors for the defined change keys.
    public struct Change {
        /// The kind of the change.
        /// - seealso: `NSKeyValueChangeKindKey`
        public var kind: NSKeyValueChange? {
            return (self.rawDict?[NSKeyValueChangeKey.kindKey] as? UInt).flatMap(NSKeyValueChange.init)
        }
        
        /// The old value from the change.
        /// - seealso: `NSKeyValueChangeOldKey`
        public var old: AnyObject? {
            return self.rawDict?[NSKeyValueChangeKey.oldKey]
        }
        
        /// The new value from the change.
        /// - seealso: `NSKeyValueChangeNewKey`
        public var new: AnyObject? {
            return self.rawDict?[NSKeyValueChangeKey.newKey]
        }
        
        /// Whether this callback is being sent prior to the change.
        /// - seealso: `NSKeyValueChangeNotificationIsPriorKey`
        public var isPrior: Bool {
            return self.rawDict?[NSKeyValueChangeKey.notificationIsPriorKey] as? Bool ?? false
        }
        
        /// The indexes of the inserted, removed, or replaced objects when relevant.
        /// - seealso: `NSKeyValueChangeIndexesKey`
        public var indexes: IndexSet? {
            return self.rawDict?[NSKeyValueChangeKey.indexesKey] as? IndexSet
        }
        
        /// The raw change dictionary passed to `observeValueForKeyPath(_:ofObject:change:context:)`.
        public let rawDict: [NSKeyValueChangeKey: AnyObject]?
        
        private init(rawDict: [NSKeyValueChangeKey: AnyObject]?) {
            self.rawDict = rawDict
        }
    }
    
    /// Returns `true` iff the observer has already been cancelled.
    ///
    /// Returns `true` if `cancel()` has been invoked on any thread. If `cancel()` is invoked
    /// concurrently with accessing this property, it may or may not see the cancellation depending
    /// on the precise timing involved.
    ///
    /// - Note: This property does not support key-value observing.
    @nonobjc public var isCancelled: Bool {
        return __isCancelled
    }
}
