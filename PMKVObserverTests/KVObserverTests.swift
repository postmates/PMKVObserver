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
@testable import PMKVObserver

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
    
    #if swift(>=3.2)
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
    #endif
    
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
}
