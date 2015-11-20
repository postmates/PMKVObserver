# PMKVObserver

![Platform](https://img.shields.io/badge/platform-ios%20%7C%20osx-lightgrey.svg)
![Languages](https://img.shields.io/badge/Languages-Swift%20%7C%20ObjC-orange.svg)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

PMKVObserver provides a safe block-based wrapper around Key-Value Observing, with APIs for both Obj-C and Swift. Features include:

* Thread-safety. Observers can be registered on a different thread than KVO notifications are sent on, and can be cancelled on yet another thread. An observer can even be cancelled from two thread simultaneously.
* Automatic unregistering when the observed object deallocates.
* Support for providing an observing object that is given to the block, and automatic unregistering when this observing object deallocates. This lets you call methods on `self` without retaining it or dealing with a weak reference.
* Thread-safety for the automatic deallocation. This protects against receiving messages on another thread while the object is deallocating.
* First-class support for both Obj-C and Swift, including strong typing in the Swift API.

## Usage

TODO

## Requirements

As part of this framework is implemented in Swift, it requires iOS 7 or later, or OS X 10.9 or later.

## Installation

TODO

## License

TODO - insert MIT license here
