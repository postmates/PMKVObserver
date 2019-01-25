//
//  KVOHelper.swift
//  PMKVObserver
//
//  Created by Lily Ballard on 11/19/15.
//  Copyright © 2015 Postmates. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
//  http://www.apache.org/licenses/LICENSE-2.0> or the MIT license
//  <LICENSE-MIT or http://opensource.org/licenses/MIT>, at your
//  option. This file may not be copied, modified, or distributed
//  except according to those terms.
//

import Foundation

public final class KVOHelper: NSObject {
    @objc public dynamic var str: String = ""
    @objc public dynamic var optStr: String?
    
    @objc public dynamic var int: Int = 0
    @objc public dynamic var bool: Bool = false
    
    @objc public dynamic var num: NSNumber = 0
    @objc public dynamic var optNum: NSNumber?
    
    @objc public dynamic var ary: [String] = []
    @objc public dynamic var optAry: [String]?
    
    @objc public dynamic var firstName: String?
    @objc public dynamic var lastName: String?
    @objc public  var computed: String? {
        switch (firstName, lastName) {
        case let (a?, b?): return "\(a) \(b)"
        case let (a?, nil): return a
        case let (nil, b?): return b
        case (nil, nil): return nil
        }
    }
    @objc public  static let keyPathsForValuesAffectingComputed: Set<String> = ["firstName", "lastName"]
    
    @objc(KVOHelperEnum) public enum Enum: Int {
        case zero, one, two
    }
    
    @objc public dynamic var enumValue: Enum = .zero
    
    @objc public dynamic var any: Any = 42
    @objc public dynamic var optAny: Any?
    
    @objc public dynamic var null: NSNull = NSNull()
    @objc public dynamic var optNull: NSNull?
}
