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
    #if swift(>=3.2)
    /// Establishes a KVO relationship to `object`. The KVO will be active until `object` deallocates or
    /// until the `cancel()` method is invoked.
    public convenience init<Object: AnyObject, Value>(object: Object, keyPath: KeyPath<Object,Value>, options: NSKeyValueObservingOptions = [], block: @escaping (_ object: Object, _ change: Change<Value>, _ kvo: KVObserver) -> Void) {
        // FIXME: (SR-5220) We shouldn't need to use the _kvcKeyPathString SPI
        guard let keyPathStr = keyPath._kvcKeyPathString else {
            fatalError("Could not extract a String from KeyPath \(keyPath)")
        }
        self.init(__object: object, keyPath: keyPathStr, options: options, block: { (object, change, kvo) in
            block(unsafeDowncast(object as AnyObject, to: Object.self), Change(rawDict: change), kvo)
        })
    }
    
    /// Establishes a KVO relationship to `object`. The KVO will be active until either `object` or `observer`
    /// deallocates or until the `cancel()` method is invoked.
    public convenience init<T: AnyObject, Object: AnyObject, Value>(observer: T, object: Object, keyPath: KeyPath<Object,Value>, options: NSKeyValueObservingOptions = [], block: @escaping (_ observer: T, _ object: Object, _ change: Change<Value>, _ kvo: KVObserver) -> Void) {
        // FIXME: (SR-5220) We shouldn't need to use the _kvcKeyPathString SPI
        guard let keyPathStr = keyPath._kvcKeyPathString else {
            fatalError("Could not extract a String from KeyPath \(keyPath)")
        }
        self.init(__observer: observer, object: object, keyPath: keyPathStr, options: options, block: { (observer, object, change, kvo) in
            block(unsafeDowncast(observer as AnyObject, to: T.self), unsafeDowncast(object as AnyObject, to: Object.self), Change(rawDict: change), kvo)
        })
    }
    #endif
    
    /// Establishes a KVO relationship to `object`. The KVO will be active until `object` deallocates or
    /// until the `cancel()` method is invoked.
    public convenience init<Object: AnyObject>(object: Object, keyPath: String, options: NSKeyValueObservingOptions = [], block: @escaping (_ object: Object, _ change: Change<Any>, _ kvo: KVObserver) -> Void) {
        self.init(__object: object, keyPath: keyPath, options: options, block: { (object, change, kvo) in
            block(unsafeDowncast(object as AnyObject, to: Object.self), Change(rawDict: change), kvo)
        })
    }
    
    /// Establishes a KVO relationship to `object`. The KVO will be active until either `object` or `observer`
    /// deallocates or until the `cancel()` method is invoked.
    public convenience init<T: AnyObject, Object: AnyObject>(observer: T, object: Object, keyPath: String, options: NSKeyValueObservingOptions = [], block: @escaping (_ observer: T, _ object: Object, _ change: Change<Any>, _ kvo: KVObserver) -> Void) {
        self.init(__observer: observer, object: object, keyPath: keyPath, options: options, block: { (observer, object, change, kvo) in
            block(unsafeDowncast(observer as AnyObject, to: T.self), unsafeDowncast(object as AnyObject, to: Object.self), Change(rawDict: change), kvo)
        })
    }
    
    /// A type that provides type-checked accessors for the defined change keys.
    public struct Change<Value> {
        /// The kind of the change.
        /// - seealso: `NSKeyValueChangeKey.kindKey`
        public var kind: NSKeyValueChange {
            // NB: Block-based KVO force-unwraps this, so we'll assume that it's safe to do the same.
            return NSKeyValueChange(rawValue: rawDict[.kindKey] as! UInt)!
        }
        
        /// The old value from the change.
        /// - seealso: `NSKeyValueChangeKey.oldKey`
        public var old: Value? {
            return rawDict[.oldKey] as? Value
        }
        
        /// The new value from the change.
        /// - seealso: `NSKeyValueChangeKey.newKey`
        public var new: Value? {
            return rawDict[.newKey] as? Value
        }
        
        /// Whether this callback is being sent prior to the change.
        /// - seealso: `NSKeyValueChangeKey.notificationIsPriorKey`
        public var isPrior: Bool {
            return self.rawDict[.notificationIsPriorKey] as? Bool ?? false
        }
        
        /// The indexes of the inserted, removed, or replaced objects when relevant.
        /// - seealso: `NSKeyValueChangeKey.indexesKey`
        public var indexes: IndexSet? {
            return self.rawDict[.indexesKey] as? IndexSet
        }
        
        /// The raw change dictionary passed to `observeValueForKeyPath(_:ofObject:change:context:)`.
        public let rawDict: [NSKeyValueChangeKey: Any]
        
        fileprivate init(rawDict: [NSKeyValueChangeKey: Any]) {
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
