//
//  PMKVObserverTests.m
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

@import XCTest;
#import "PMKVObserver.h"
#import "PMKVObserverTests-Swift.h"

@interface PMKVObserverTests : XCTestCase
@property (nonatomic) KVOHelper *helper;
@end

@implementation PMKVObserverTests

- (void)setUp {
    [super setUp];
    self.helper = [[KVOHelper alloc] init];
}

- (void)tearDown {
    self.helper = nil;
    [super tearDown];
}

- (void)testKVO {
    __block BOOL fired = NO;
    __block PMKVObserver *token = [PMKVObserver observeObject:self.helper keyPath:@"str" options:0 block:^(id  _Nonnull object, NSDictionary<NSString *,id> * _Nullable change, PMKVObserver * _Nonnull kvo) {
        fired = YES;
        XCTAssertEqual(object, self.helper);
        XCTAssertEqualObjects(change[NSKeyValueChangeKindKey], @(NSKeyValueChangeSetting));
        XCTAssertEqual(token, kvo);
        XCTAssertEqualObjects([object str], @"foo");
    }];
    self.helper.str = @"foo";
    XCTAssertTrue(fired);
    fired = NO;
    [token cancel];
    self.helper.str = @"bar";
    XCTAssertFalse(fired);
    fired = NO;
}

- (void)testKVOPrimitive {
    __block BOOL fired = NO;
    PMKVObserver *token = [PMKVObserver observeObject:self.helper keyPath:@"int" options:0 block:^(id  _Nonnull object, NSDictionary<NSString *,id> * _Nullable change, PMKVObserver * _Nonnull kvo) {
        fired = YES;
        XCTAssertEqual([object int], 42);
    }];
    self.helper.int_ = 42;
    XCTAssertTrue(fired);
    [token cancel];
}

- (void)testKVOComputed {
    __block BOOL fired = NO;
    __block NSString *expected;
    PMKVObserver *token = [PMKVObserver observeObject:self.helper keyPath:@"computed" options:0 block:^(id  _Nonnull object, NSDictionary<NSString *,id> * _Nullable change, PMKVObserver * _Nonnull kvo) {
        fired = YES;
        XCTAssertEqualObjects([object computed], expected);
    }];
    expected = @"Bob";
    self.helper.firstName = @"Bob";
    XCTAssertTrue(fired);
    fired = NO;
    expected = @"Bob Jones";
    self.helper.lastName = @"Jones";
    XCTAssertTrue(fired);
    fired = NO;
    expected = @"Jones";
    self.helper.firstName = nil;
    XCTAssertTrue(fired);
    fired = NO;
    expected = nil;
    self.helper.lastName = nil;
    XCTAssertTrue(fired);
    [token cancel];
}

- (void)testKVOTeardown {
    __block BOOL fired = NO;
    __weak PMKVObserver *weakToken;
    @autoreleasepool {
        PMKVObserver *token = [PMKVObserver observeObject:self.helper keyPath:@"str" options:0 block:^(id  _Nonnull object, NSDictionary<NSString *,id> * _Nullable change, PMKVObserver * _Nonnull kvo) {
            fired = YES;
        }];
        weakToken = token;
        self.helper.str = @"a";
        XCTAssertTrue(fired);
        fired = NO;
    }
    self.helper.str = @"b";
    XCTAssertTrue(fired);
    fired = NO;
    @autoreleasepool {
        XCTAssertNotNil(weakToken);
        [weakToken cancel];
    }
    XCTAssertNil(weakToken);
    self.helper.str = @"c";
    XCTAssertFalse(fired);
}

- (void)testKVORetainCycle {
    __block BOOL fired = NO;
    __weak PMKVObserver *weakToken;
    @autoreleasepool {
        __block PMKVObserver *token;
        token = [PMKVObserver observeObject:self.helper keyPath:@"str" options:0 block:^(id  _Nonnull object, NSDictionary<NSString *,id> * _Nullable change, PMKVObserver * _Nonnull kvo) {
            fired = YES;
            (void)token; // capture it
        }];
        weakToken = token;
        self.helper.str = @"a";
        XCTAssertTrue(fired);
        fired = NO;
        [token cancel];
    }
    XCTAssertNil(weakToken);
    self.helper.str = @"b";
    XCTAssertFalse(fired);
}

- (void)testObserver {
    __block BOOL fired = NO;
    __weak PMKVObserver *weakToken;
    __weak NSObject *weakFoo;
    @autoreleasepool {
        NSObject *foo = [[NSObject alloc] init];
        weakFoo = foo;
        @autoreleasepool {
            PMKVObserver *token = [PMKVObserver observeObject:self.helper observer:foo keyPath:@"str" options:0 block:^(id  _Nonnull observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nullable change, PMKVObserver * _Nonnull kvo) {
                fired = YES;
                XCTAssertEqual(observer, weakFoo);
            }];
            weakToken = token;
            self.helper.str = @"a";
            XCTAssertTrue(fired);
            fired = NO;
        }
        @autoreleasepool {
            XCTAssertNotNil(weakToken);
        }
        self.helper.str = @"b";
        XCTAssertTrue(fired);
        fired = NO;
        foo = nil;
    }
    @autoreleasepool {
        XCTAssertNil(weakFoo);
        XCTAssertNil(weakToken);
    }
    self.helper.str = @"c";
    XCTAssertFalse(fired);
}

- (void)testObjectDealloc {
    __block BOOL fired = NO;
    __weak PMKVObserver *weakToken;
    __weak KVOHelper *weakHelper;
    @autoreleasepool {
        KVOHelper *helper = [[KVOHelper alloc] init];
        weakHelper = helper;
        @autoreleasepool {
            PMKVObserver *token = [PMKVObserver observeObject:helper keyPath:@"str" options:0 block:^(id  _Nonnull object, NSDictionary<NSString *,id> * _Nullable change, PMKVObserver * _Nonnull kvo) {
                fired = YES;
            }];
            weakToken = token;
            helper.str = @"a";
            XCTAssertTrue(fired);
            fired = NO;
        }
        @autoreleasepool {
            XCTAssertNotNil(weakToken);
        }
        helper.str = @"b";
        XCTAssertTrue(fired);
        fired = NO;
        helper = nil;
    }
    @autoreleasepool {
        XCTAssertNil(weakHelper);
        XCTAssertNil(weakToken);
    }
    XCTAssertFalse(fired);
}

- (void)testInitial {
    __block BOOL fired = NO;
    self.helper.str = @"foo";
    __block NSString *expected = @"foo";
    PMKVObserver *token = [PMKVObserver observeObject:self.helper keyPath:@"str" options:NSKeyValueObservingOptionInitial block:^(id  _Nonnull object, NSDictionary<NSString *,id> * _Nullable change, PMKVObserver * _Nonnull kvo) {
        fired = YES;
        XCTAssertEqualObjects([object str], expected);
    }];
    XCTAssertTrue(fired);
    fired = NO;
    expected = @"bar";
    self.helper.str = @"bar";
    XCTAssertTrue(fired);
    [token cancel];
}

- (void)testInitialCancel {
    __block BOOL fired = NO;
    self.helper.str = @"foo";
    __weak PMKVObserver *weakToken;
    @autoreleasepool {
        PMKVObserver *token = [PMKVObserver observeObject:self.helper keyPath:@"str" options:NSKeyValueObservingOptionInitial block:^(id  _Nonnull object, NSDictionary<NSString *,id> * _Nullable change, PMKVObserver * _Nonnull kvo) {
            fired = YES;
            XCTAssertEqualObjects([object str], @"foo");
            [kvo cancel];
        }];
        weakToken = token;
        XCTAssertTrue(fired);
        fired = NO;
        self.helper.str = @"bar";
        XCTAssertFalse(fired);
        fired = NO;
    }
    XCTAssertNil(weakToken);
    
    @autoreleasepool {
        PMKVObserver *token = [PMKVObserver observeObject:self.helper observer:self keyPath:@"str" options:NSKeyValueObservingOptionInitial block:^(id  _Nonnull observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nullable change, PMKVObserver * _Nonnull kvo) {
            fired = YES;
            XCTAssertEqualObjects([object str], @"bar");
            [kvo cancel];
        }];
        weakToken = token;
        XCTAssertTrue(fired);
        fired = NO;
        self.helper.str = @"baz";
        XCTAssertFalse(fired);
        fired = NO;
    }
    XCTAssertNil(weakToken);
}

- (void)testCancelTwice {
    __block BOOL fired = NO;
    PMKVObserver *token = [PMKVObserver observeObject:self.helper keyPath:@"str" options:0 block:^(id  _Nonnull object, NSDictionary<NSString *,id> * _Nullable change, PMKVObserver * _Nonnull kvo) {
        fired = YES;
    }];
    self.helper.str = @"foo";
    XCTAssertTrue(fired);
    fired = NO;
    [token cancel];
    [token cancel];
    self.helper.str = @"bar";
    XCTAssertFalse(fired);
}

- (void)testCancelConcurrently {
    __block BOOL fired = NO;
    PMKVObserver *token = [PMKVObserver observeObject:self.helper keyPath:@"str" options:0 block:^(id  _Nonnull object, NSDictionary<NSString *,id> * _Nullable change, PMKVObserver * _Nonnull kvo) {
        fired = YES;
    }];
    self.helper.str = @"foo";
    XCTAssertTrue(fired);
    fired = NO;
    dispatch_group_t group = dispatch_group_create();
    for (int i = 0; i < 2; ++i) {
        dispatch_group_async(group, dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
            [token cancel];
        });
    }
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    self.helper.str = @"bar";
    XCTAssertFalse(fired);
}

- (void)testIsCancelled {
    PMKVObserver *token = [PMKVObserver observeObject:self.helper keyPath:@"str" options:0 block:^(id  _Nonnull object, NSDictionary<NSString *,id> * _Nullable change, PMKVObserver * _Nonnull kvo) {
    }];
    XCTAssertFalse(token.cancelled);
    self.helper.str = @"foo";
    XCTAssertFalse(token.cancelled);
    [token cancel];
    XCTAssertTrue(token.cancelled);
}

@end
