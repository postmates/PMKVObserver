# PMKVObserver

[![Version](https://img.shields.io/badge/version-v1.0.4-blue.svg)](https://github.com/postmates/PMKVObserver/releases/latest)
![Platforms](https://img.shields.io/badge/platforms-ios%20%7C%20osx%20%7C%20watchos%20%7C%20tvos-lightgrey.svg)
![Languages](https://img.shields.io/badge/languages-swift%20%7C%20objc-orange.svg)
![License](https://img.shields.io/badge/license-MIT%2FApache-blue.svg)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)][Carthage]
[![CocoaPods](https://img.shields.io/cocoapods/v/PMKVObserver.svg)](http://cocoadocs.org/docsets/PMKVObserver)

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
    print("User's full name changed to \(object.fullName)")
}

// Convenience methods for working with the change dictionary
_ = KVObserver(object: user, keyPath: "fullName", options: [.Old, .New]) { _, change, _ in
    // unfortunately we don't know what the type of fullName is, so change uses AnyObject
    let old = change.old as? String
    let new = change.new as? String
    if old != new {
        print("User's full name changed to \(new ?? "nil")")
    }
}

// Unregistering can be done from within the block, even in an .Initial callback
_ = KVObserver(object: user, keyPath: "fullName", options: [.Initial]) { object, _, kvo in
    guard !object.fullName.isEmpty else { return }
    print("User's full name is \(object.fullName)")
    kvo.cancel()
}

// Or you can unregister externally
let token = KVObserver(object: user, keyPath: "fullName") { object, _, _ in
    print("User's full name changed to \(object.fullName)")
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

Installing as a framework requires a minimum of iOS 8, OS X 10.9, watchOS 2.0, or tvOS 9.0.

If you install by copying the source into your project, it should work on iOS 7 or later (iOS 6 if you remove KVObserver.swift), and OS X 10.7 or later. Please note that it has not been tested on these versions.

## Installation

To install using [Carthage][], add the following to your Cartfile:

```
github "postmates/PMKVObserver" ~> 1.0
```

You may also install manually by adding the framework to your workspace, or by adding the 3 files KVObserver.h, KVObserver.m, and (optionally) KVObserver.swift to your project.

Once installed, you can use this by adding `import PMKVObserver` (Swift) or `@import PMKVObserver;` (Objective-C) to your code.

## License

Licensed under either of
 * Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE) or
   http://www.apache.org/licenses/LICENSE-2.0)
 * MIT license ([LICENSE-MIT](LICENSE-MIT) or
   http://opensource.org/licenses/MIT) at your option.

### Contribution

Unless you explicitly state otherwise, any contribution intentionally submitted for inclusion in the work by you shall be dual licensed as above, without any additional terms or conditions.

## Version History

#### v1.0.4 (2016-03-02)

* Update CocoaPods podspec to split Swift support into a subspec.

#### v1.0.3 (2015-01-28)

* Add property `cancelled` to `PMKVObserver`.

#### v1.0.2 (2016-01-26)

* Switch to dual-licensed as MIT or Apache 2.0.

#### v1.0.1 (2015-12-17)

* Stop leaking our `pthread_mutex_t`s.

#### v1.0 (2015-12-17)

Initial release.
