//
//  PMKVObserverTests.m
//  PMKVObserver
//
//  Created by Kevin Ballard on 11/19/15.
//  Copyright © 2015 Postmates. All rights reserved.
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

- (void)testCancelOnBackgroundThread {
    __block BOOL fired = NO;
    dispatch_queue_t queue = dispatch_queue_create("com.postmates.PMKVObserver.queue", DISPATCH_QUEUE_SERIAL);
    NSString* value1 = @"value1";
    NSString* value2 = @"value2";

    PMKVObserver *token = [PMKVObserver observeObject:self.helper keyPath:@"str" options:NSKeyValueObservingOptionNew block:^(id  _Nonnull object, NSDictionary<NSString *,id> * _Nullable change, PMKVObserver * _Nonnull kvo) {
        XCTAssertEqualObjects([object str], value1);
        fired = YES;
    }];
    dispatch_sync(queue, ^{
        self.helper.str = value1;
        [token cancel];
        self.helper.str = value2;
    });

    XCTAssertTrue(fired);
}

- (void)testObserverDeallocatedOnBackgroundThread {
    __block BOOL fired = NO;
    dispatch_queue_t queue = dispatch_queue_create("com.postmates.PMKVObserver.queue", DISPATCH_QUEUE_SERIAL);
    NSString* value1 = @"value1";
    NSString* value2 = @"value2";

    __block NSObject* observer = [[NSObject alloc] init];
    [PMKVObserver observeObject:self.helper observer:observer keyPath:@"str" options:NSKeyValueObservingOptionNew block:^(id  _Nonnull observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nullable change, PMKVObserver * _Nonnull kvo) {
        XCTAssertEqualObjects([object str], value1);
        fired = YES;
    }];

    dispatch_sync(queue, ^{
        self.helper.str = value1;
        observer = nil;
        self.helper.str = value2;
    });

    XCTAssertTrue(fired);
}

- (void)testRegisterAndCancelOnBackgroundThreads {
    __block BOOL fired = NO;
    dispatch_queue_t queue1 = dispatch_queue_create("com.postmates.PMKVObserver.queue1", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t queue2 = dispatch_queue_create("com.postmates.PMKVObserver.queue2", DISPATCH_QUEUE_SERIAL);
    NSString* value1 = @"value1";
    NSString* value2 = @"value2";

    __block PMKVObserver *token = nil;
    dispatch_sync(queue1, ^{
        token = [PMKVObserver observeObject:self.helper observer:self keyPath:@"str" options:NSKeyValueObservingOptionNew block:^(id  _Nonnull observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nullable change, PMKVObserver * _Nonnull kvo) {
            XCTAssertEqualObjects([object str], value1);
            fired = YES;
        }];
    });
    self.helper.str = value1;
    dispatch_sync(queue2, ^{
        [token cancel];
        self.helper.str = value2;
    });

    XCTAssertTrue(fired);
}

@end
