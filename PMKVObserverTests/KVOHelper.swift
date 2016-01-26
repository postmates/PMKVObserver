//
//  KVOHelper.swift
//  PMKVObserver
//
//  Created by Kevin Ballard on 11/19/15.
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
    public dynamic var str: String = ""
    public dynamic var optStr: String?
    
    public dynamic var int: Int = 0
    public dynamic var bool: Bool = false
    
    public dynamic var num: NSNumber = 0
    public dynamic var optNum: NSNumber?
    
    public dynamic var ary: [String] = []
    public dynamic var optAry: [String]?
    
    public dynamic var firstName: String?
    public dynamic var lastName: String?
    @objc public  var computed: String? {
        switch (firstName, lastName) {
        case let (a?, b?): return "\(a) \(b)"
        case let (a?, nil): return a
        case let (nil, b?): return b
        case (nil, nil): return nil
        }
    }
    @objc public  static let keyPathsForValuesAffectingComputed: Set<String> = ["firstName", "lastName"]
}
