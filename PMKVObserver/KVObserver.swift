//
//  KVObserver.swift
//  PMKVObserver
//
//  Created by Kevin Ballard on 11/18/15.
//  Copyright © 2015 Kevin Ballard. All rights reserved.
//

import Foundation

public typealias KVObserver = PMKVObserver

extension KVObserver {
    /// Establishes a KVO relationship to `object`. The KVO will be active until `object` deallocates or
    /// until the `cancel()` method is invoked.
    public convenience init<Object: AnyObject>(object: Object, keyPath: String, options: NSKeyValueObservingOptions = [], block: (object: Object, change: Change, kvo: KVObserver) -> Void) {
        self.init(__object: object, keyPath: keyPath, options: options, block: { (object, change, kvo) in
            block(object: unsafeDowncast(object), change: Change(rawDict: change), kvo: kvo)
        })
    }
    
    /// Establishes a KVO relationship to `object`. The KVO will be active until either `object` or `observer`
    /// deallocates or until the `cancel()` method is invoked.
    public convenience init<T: AnyObject, Object: AnyObject>(observer: T, object: Object, keyPath: String, options: NSKeyValueObservingOptions = [], block: (observer: T, object: Object, change: Change, kvo: KVObserver) -> Void) {
        self.init(__observer: observer, object: object, keyPath: keyPath, options: options, block: { (observer, object, change, kvo) in
            block(observer: unsafeDowncast(observer), object: unsafeDowncast(object), change: Change(rawDict: change), kvo: kvo)
        })
    }
    
    /// A type that provides type-checked accessors for the defined change keys.
    public struct Change {
        /// The kind of the change.
        /// - seealso: `NSKeyValueChangeKindKey`
        public var kind: NSKeyValueChange? {
            return (self.rawDict?[NSKeyValueChangeKindKey] as? UInt).flatMap(NSKeyValueChange.init)
        }
        
        /// The old value from the change.
        /// - seealso: `NSKeyValueChangeOldKey`
        public var old: AnyObject? {
            return self.rawDict?[NSKeyValueChangeOldKey]
        }
        
        /// The new value from the change.
        /// - seealso: `NSKeyValueChangeNewKey`
        public var new: AnyObject? {
            return self.rawDict?[NSKeyValueChangeNewKey]
        }
        
        /// Whether this callback is being sent prior to the change.
        /// - seealso: `NSKeyValueChangeNotificationIsPriorKey`
        public var isPrior: Bool {
            return self.rawDict?[NSKeyValueChangeNotificationIsPriorKey] as? Bool ?? false
        }
        
        /// The indexes of the inserted, removed, or replaced objects when relevant.
        /// - seealso: `NSKeyValueChangeIndexesKey`
        public var indexes: NSIndexSet? {
            return self.rawDict?[NSKeyValueChangeIndexesKey] as? NSIndexSet
        }
        
        /// The raw change dictionary passed to `observeValueForKeyPath(_:ofObject:change:context:)`.
        public let rawDict: [String: AnyObject]?
        
        private init(rawDict: [String: AnyObject]?) {
            self.rawDict = rawDict
        }
    }
}
