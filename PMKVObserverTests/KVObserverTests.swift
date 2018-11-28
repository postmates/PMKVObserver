//
//  KVObserverTests.swift
//  PMKVObserverTests
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

import XCTest
import PMKVObserver

class KVObserverTests: XCTestCase {
    var helper: KVOHelper!
    
    override func setUp() {
        super.setUp()
        helper = KVOHelper()
    }
    
    override func tearDown() {
        helper = nil
        super.tearDown()
    }
    
    func testKVO() {
        var fired = false
        var token: KVObserver!
        token = KVObserver(object: helper, keyPath: #keyPath(KVOHelper.str)) { [weak helper] object, change, kvo in
            fired = true
            XCTAssert(object === helper)
            XCTAssertEqual(change.kind, .setting)
            XCTAssert(kvo === token)
            XCTAssertEqual(object.str, "foo")
            XCTAssertNil(change.old)
            XCTAssertNil(change.new)
        }
        helper.str = "foo"
        XCTAssertTrue(fired)
        fired = false
        token.cancel()
        helper.str = "bar"
        XCTAssertFalse(fired)
        fired = false
        
        let foo = NSObject()
        token = KVObserver(observer: foo, object: helper, keyPath: #keyPath(KVOHelper.str)) { [weak foo] observer, object, _, _ in
            fired = true
            XCTAssert(observer === foo)
            XCTAssertEqual(object.str, "foo")
        }
        XCTAssertFalse(fired)
        fired = false
        helper.str = "foo"
        XCTAssertTrue(fired)
        fired = false
        token.cancel()
        helper.str = "bar"
        XCTAssertFalse(fired)
        fired = false
        
        token = KVObserver(object: helper, keyPath: #keyPath(KVOHelper.str), options: [.old, .new], block: { (object, change, kvo) in
            fired = true
            XCTAssertEqual(change.old as? String, "bar")
            XCTAssertEqual(change.new as? String, "foo")
        })
        helper.str = "foo"
        XCTAssertTrue(fired)
        token.cancel()
        fired = false
    }
    
    func testSwift4KVO() {
        var fired = false
        var token: KVObserver!
        token = KVObserver(object: helper, keyPath: \KVOHelper.str) { [weak helper] object, change, kvo in
            fired = true
            XCTAssert(object === helper)
            XCTAssertEqual(change.kind, .setting)
            XCTAssert(kvo === token)
            XCTAssertEqual(object.str, "foo")
            XCTAssertNil(change.old)
            XCTAssertNil(change.new)
        }
        helper.str = "foo"
        XCTAssertTrue(fired)
        fired = false
        token.cancel()
        helper.str = "bar"
        XCTAssertFalse(fired)
        fired = false
        
        let foo = NSObject()
        token = KVObserver(observer: foo, object: helper, keyPath: \KVOHelper.str) { [weak foo] observer, object, _, _ in
            fired = true
            XCTAssert(observer === foo)
            XCTAssertEqual(object.str, "foo")
        }
        XCTAssertFalse(fired)
        fired = false
        helper.str = "foo"
        XCTAssertTrue(fired)
        fired = false
        token.cancel()
        helper.str = "bar"
        XCTAssertFalse(fired)
        
        token = KVObserver(object: helper, keyPath: \KVOHelper.str, options: [.old, .new], block: { (object, change, kvo) in
            fired = true
            XCTAssertEqual(change.old, "bar")
            XCTAssertEqual(change.new, "foo")
        })
        helper.str = "foo"
        XCTAssertTrue(fired)
        token.cancel()
        fired = false
    }
    
    func testInitialCancel() {
        var fired = false
        weak var weakToken: KVObserver!
        helper.str = "foo"
        autoreleasepool {
            let token = KVObserver(object: helper, keyPath: #keyPath(KVOHelper.str), options: .initial) { object, _, kvo in
                fired = true
                XCTAssertEqual(object.str, "foo")
                kvo.cancel()
            }
            weakToken = token
            XCTAssertTrue(fired)
            fired = false
            helper.str = "bar"
            XCTAssertFalse(fired)
            fired = false
        }
        XCTAssertNil(weakToken)
        
        autoreleasepool {
            let token = KVObserver(observer: self, object: helper, keyPath: #keyPath(KVOHelper.str), options: .initial) { _, object, _, kvo in
                fired = true
                XCTAssertEqual(object.str, "bar")
                kvo.cancel()
            }
            weakToken = token
            XCTAssertTrue(fired)
            fired = false
            helper.str = "baz"
            XCTAssertFalse(fired)
            fired = false
        }
        XCTAssertNil(weakToken)
    }
    
    func testSameObserverObject() {
        var fired = false
        let token = KVObserver(observer: helper, object: helper, keyPath: #keyPath(KVOHelper.str)) { [weak helper] observer, object, _, _ in
            fired = true
            XCTAssert(observer === helper)
            XCTAssert(object === helper)
            XCTAssertEqual(object.str, "foo")
        }
        helper.str = "foo"
        XCTAssertTrue(fired)
        token.cancel()
    }
    
    func testObservingEnum() {
        var fired = false
        let token = KVObserver(object: helper, keyPath: \KVOHelper.enumValue, options: [.old, .new]) { (object, change, kvo) in
            fired = true
            XCTAssertEqual(change.old, KVOHelper.Enum.zero)
            XCTAssertEqual(change.new, KVOHelper.Enum.one)
            kvo.cancel()
        }
        helper.enumValue = .one
        XCTAssertTrue(fired)
        token.cancel()
    }
    
    func testObservingOptionalEnum() {
        class Wrapper: NSObject {
            @objc dynamic var helper: KVOHelper?
        }
        let wrapper = Wrapper()
        var fireCount = 0
        let token = KVObserver(object: wrapper, keyPath: \Wrapper.helper?.enumValue, options: [.initial, .old, .new]) { (object, change, kvo) in
            defer { fireCount += 1 }
            switch fireCount {
            case 0:
                XCTAssertEqual(change.old, KVOHelper.Enum??.none)
                XCTAssertEqual(change.new, .some(.none))
            case 1:
                XCTAssertEqual(change.old, .some(.none))
                XCTAssertEqual(change.new, KVOHelper.Enum.zero)
            case 2:
                XCTAssertEqual(change.old, KVOHelper.Enum.zero)
                XCTAssertEqual(change.new, KVOHelper.Enum.one)
            case 3:
                XCTAssertEqual(change.old, KVOHelper.Enum.one)
                XCTAssertEqual(change.new, .some(.none))
            default:
                XCTFail("Unexpected fire count \(fireCount)")
            }
        }
        wrapper.helper = KVOHelper()
        wrapper.helper?.enumValue = .one
        wrapper.helper = nil
        XCTAssertEqual(fireCount, 4)
        token.cancel()
    }
    
    func testObservingOptionalValue() {
        var fireCount = 0
        let token = KVObserver(object: helper, keyPath: \.optNum, options: [.initial, .old, .new]) { (object, change, kvo) in
            defer { fireCount += 1 }
            switch fireCount {
            case 0: // initial
                XCTAssertEqual(change.old, NSNumber??.none)
                XCTAssertEqual(change.new, .some(.none))
            case 1:
                XCTAssertEqual(change.old, .some(.none))
                XCTAssertEqual(change.new, 42)
            case 2:
                XCTAssertEqual(change.old, 42)
                XCTAssertEqual(change.new, 84)
            case 3:
                XCTAssertEqual(change.old, 84)
                XCTAssertEqual(change.new, .some(.none))
            default:
                XCTFail("Unexpected fire count \(fireCount)")
            }
        }
        helper.optNum = 42
        helper.optNum = 84
        helper.optNum = nil
        XCTAssertEqual(fireCount, 4)
        token.cancel()
    }
    
    func testObservingAnyWithNSNull() {
        // Any will preserve NSNull values
        var fireCount = 0
        let token = KVObserver(object: helper, keyPath: \.any, options: [.initial, .old, .new]) { (object, change, kvo) in
            defer { fireCount += 1 }
            if fireCount == 0 { // initial
                XCTAssertNil(change.old)
                XCTAssert(change.new as? Int == 42, "expected 42, got \(change.new as Any)")
            } else {
                XCTAssert(change.old as? Int == 42, "expected 42, got \(change.old as Any)")
                XCTAssert(change.new is NSNull, "expected NSNull, got \(change.new as Any)")
            }
        }
        helper.any = NSNull()
        XCTAssertEqual(fireCount, 2)
        token.cancel()
    }
    
    func testObservingOptAnyWithNSNull() {
        // Any? won't preserve NSNull values
        var fireCount = 0
        let token = KVObserver(object: helper, keyPath: \.optAny, options: [.initial, .old, .new]) { (object, change, kvo) in
            defer { fireCount += 1 }
            switch fireCount {
            case 0: // initial
                switch change.old {
                case Optional<Any?>.none: break
                default: XCTFail("expected .none, got \(change.old as Any)")
                }
                switch change.new {
                case Optional<Any?>.some(.none): break
                default: XCTFail("expected .some(.none), got \(change.new as Any)")
                }
            case 1: // set to 42
                switch change.old {
                case Optional<Any?>.some(.none): break
                default: XCTFail("expected .some(.none), got \(change.old as Any)")
                }
                XCTAssert(change.new as? Int == 42, "expected 42, got \(change.new as Any)")
            case 2: // set to NSNull
                XCTAssert(change.old as? Int == 42, "expected 42, got \(change.old as Any)")
                switch change.new {
                case Optional<Any?>.some(.none): break
                default: XCTFail("expected .some(.none), got \(change.new as Any)")
                }
            default:
                XCTFail("Unexpected fire count \(fireCount)")
            }
        }
        helper.optAny = 42
        helper.optAny = NSNull()
        XCTAssertEqual(fireCount, 3)
        token.cancel()
    }
    
    func testObservingNull() {
        // NSNull will preserve NSNull values
        var fireCount = 0
        let token = KVObserver(object: helper, keyPath: \.null, options: [.initial, .old, .new]) { (object, change, kvo) in
            defer { fireCount += 1 }
            if fireCount == 0 { // initial
                XCTAssertNil(change.old)
                XCTAssertNotNil(change.new)
            } else {
                XCTAssertNotNil(change.old)
                XCTAssertNotNil(change.new)
            }
        }
        helper.null = NSNull()
        XCTAssertEqual(fireCount, 2)
        token.cancel()
    }
    
    func testObservingOptNullWithNSNull() {
        // NSNull? won't preserve NSNull values, and in fact will always return `nil`
        var fireCount = 0
        let token = KVObserver(object: helper, keyPath: \.optNull, options: [.initial, .old, .new]) { (object, change, kvo) in
            defer { fireCount += 1 }
            XCTAssertEqual(change.old, NSNull??.none)
            XCTAssertEqual(change.new, NSNull??.none)
        }
        helper.optNull = NSNull()
        helper.optNull = nil
        XCTAssertEqual(fireCount, 3)
        token.cancel()
    }
    
    func testObject() {
        let token: KVObserver
        do {
            let object = NSObject()
            token = KVObserver(object: object, keyPath: \.description, block: { (_, _, _) in })
            XCTAssert(token.object === object)
            token.cancel()
            XCTAssert(token.object === object)
        }
        XCTAssertNil(token.object)
    }
    
    func testKeyPath() {
        XCTAssertEqual(KVObserver(object: helper, keyPath: \.str, block: { (_, _, _) in }).objcKeyPath, #keyPath(KVOHelper.str))
        XCTAssertEqual(KVObserver(object: helper, keyPath: \.optNum, block: { (_, _, _) in }).objcKeyPath, #keyPath(KVOHelper.optNum))
        XCTAssertEqual(KVObserver(object: helper, keyPath: \.num.description, block: { (_, _, _) in }).objcKeyPath, #keyPath(KVOHelper.num.description))
    }
}
