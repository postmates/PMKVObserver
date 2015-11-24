# PMKVObserver

![Version](https://img.shields.io/badge/version-v0.1-blue.svg)
![Platform](https://img.shields.io/badge/platform-ios%20%7C%20osx-lightgrey.svg)
![Languages](https://img.shields.io/badge/languages-swift%20%7C%20objc-orange.svg)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/postmates/PMKVObserver/blob/master/LICENSE)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)][Carthage]

[Carthage]: https://github.com/carthage/carthage

PMKVObserver provides a safe block-based wrapper around Key-Value Observing, with APIs for both Obj-C and Swift. Features include:

* Thread-safety. Observers can be registered on a different thread than KVO notifications are sent on, and can be cancelled on yet another thread. An observer can even be cancelled from two thread simultaneously.
* Automatic unregistering when the observed object deallocates.
* Support for providing an observing object that is given to the block, and automatic unregistering when this observing object deallocates. This lets you call methods on `self` without retaining it or dealing with a weak reference.
* Thread-safety for the automatic deallocation. This protects against receiving messages on another thread while the object is deallocating.
* First-class support for both Obj-C and Swift, including strong typing in the Swift API.

## Examples

### Swift

```swift
// Observe an object for as long as the object is alive.
_ = KVObserver(object: user, keyPath: "fullName") { object, _, _ in
    // `object` has the same type as `user`
    NSLog("User's full name changed to %@", object.fullName)
}

// Convenience methods for working with the change dictionary
_ = KVObserver(object: user, keyPath: "fullName", options: [.Old, .New]) { _, change, _ in
    // unfortunately we don't know what the type of fullName is, so change uses AnyObject
    let old = change.old as? String
    let new = change.new as? String
    if old != new {
        NSLog("User's full name changed to %@", new ?? "nil")
    }
}

// Unregistering can be done from within the block, even in an .Initial callback
_ = KVObserver(object: user, keyPath: "fullName", options: [.Initial]) { object, _, kvo in
    guard !object.fullName.isEmpty else { return }
    NSLog("User's full name is %@", object.fullName)
    kvo.cancel()
}

// Or you can unregister externally
let token = KVObserver(object: user, keyPath: "fullName") { object, _, _ in
    NSLog("User's full name changed to %@", object.fullName)
}
// ... sometime later ...
token.cancel()

// You can also pass an observing object and KVO will be unregistered when that object deallocates
_ = KVObserver(observer: self, object: user, keyPath: "fullName") { observer, object, _, _ in
    // `observer` has the same type as `self`
    observer.nameLabel.text = object.fullName
}
```

### Objective-C

Objective-C provides all the same functionality as Swift, albeit without the strong-typing of the observer/object.

```objc
// Observe an object for as long as the object is alive.
[PMKVObserver observeObject:self.user keyPath:@"fullName" options:0
                      block:^(id  _Nonnull object, NSDictionary<NSString *,id> * _Nullable change, PMKVObserver * _Nonnull kvo) {
    NSLog(@"User's full name changed to %@", [object fullName]);
}];

// Change dictionary is provided, but without the convenience methods.
[PMKVObserver observeObject:self.user keyPath:@"fullName"
                    options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
                      block:^(id  _Nonnull object, NSDictionary<NSString *,id> * _Nullable change, PMKVObserver * _Nonnull kvo) {
    NSString *old = change[NSKeyValueChangeOldKey];
    NSString *new = change[NSKeyValueChangeNewKey];
    if (old != new && (new == nil || ![old isEqualToString:new])) {
        NSLog(@"User's full name changed to %@", new);
    }
}];

// Unregistering and observing object support is also provided (see Swift examples).
```

## Caveats

As this is a brand-new framework, it has not yet been battle-tested. The test suite covers the basic functionality, but it can't test for multi-threading race conditions. To be the best of my knowledge it is implemented correctly, but if you find any problems, please [file an issue](https://github.com/postmates/PMKVObserver/issues).

## Requirements

Installing as a framework requires iOS 8 or later, or OS X 10.9 or later.

If you install by copying the source into your project, it should work on iOS 7 or later (iOS 6 if you remove KVObserver.swift), and OS X 10.7 or later. Please note that it has not been tested on these versions.

## Installation

To install using [Carthage][], add the following to your Cartfile:

```
github "postmates/PMKVObserver"
```

You may also install manually by adding the framework to your workspace, or by adding the 3 files KVObserver.h, KVObserver.m, and (optionally) KVObserver.swift to your project.

Once installed, you can use this by adding `import PMKVObserver` (Swift) or `@import PMKVObserver;` (Objective-C) to your code.

## Version History

#### v0.1

Initial release.

## License

The MIT License (MIT)

Copyright (c) 2015 Postmates Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
