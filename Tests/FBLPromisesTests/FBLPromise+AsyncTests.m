/**
 Copyright 2018 Google Inc. All rights reserved.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at:

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "FBLPromise+Then.h"

#import <XCTest/XCTest.h>

#import "FBLPromise+Async.h"
#import "FBLPromise+Testing.h"
#import "FBLPromisesTestHelpers.h"

@interface FBLPromiseAsyncTests : XCTestCase
@end

@implementation FBLPromiseAsyncTests

- (void)testPromiseAsyncFulfill {
  // Arrange & Act.
  FBLPromise<NSNumber *> *promise =
      [FBLPromise async:^(FBLPromiseFulfillBlock fulfill, FBLPromiseRejectBlock __unused _) {
        fulfill(@42);
      }];

  // Assert.
  XCTAssert(FBLWaitForPromisesWithTimeout(10));
  XCTAssertEqualObjects(promise.value, @42);
  XCTAssertNil(promise.error);
}

- (void)testPromiseAsyncReject {
  // Arrange & Act.
  FBLPromise<NSNumber *> *promise =
      [FBLPromise async:^(FBLPromiseFulfillBlock __unused _, FBLPromiseRejectBlock reject) {
        reject([NSError errorWithDomain:FBLPromiseErrorDomain code:42 userInfo:nil]);
      }];

  // Assert.
  XCTAssert(FBLWaitForPromisesWithTimeout(10));
  XCTAssertEqualObjects(promise.error.domain, FBLPromiseErrorDomain);
  XCTAssertEqual(promise.error.code, 42);
  XCTAssertNil(promise.value);
}

- (void)testPromiseAsyncThrow {
  // Arrange & Act.
  FBLPromise<NSNumber *> *promise =
      [FBLPromise async:^(FBLPromiseFulfillBlock __unused _, FBLPromiseRejectBlock __unused __) {
        @throw [NSException exceptionWithName:@"name" reason:@"reason" userInfo:nil];  // NOLINT
      }];

  // Assert.
  XCTAssert(FBLWaitForPromisesWithTimeout(10));
  XCTAssertEqualObjects(promise.error.domain, FBLPromiseErrorDomain);
  XCTAssertEqual(promise.error.code, FBLPromiseErrorCodeException);
  XCTAssertEqualObjects(promise.error.userInfo[FBLPromiseErrorUserInfoExceptionNameKey], @"name");
  XCTAssertEqualObjects(promise.error.userInfo[FBLPromiseErrorUserInfoExceptionReasonKey],
                        @"reason");
}

/**
 Promise created with `async` should not deallocate until it gets resolved.
 */
- (void)testPromiseAsyncNoDeallocUntilFulfilled {
  // Arrange.
  FBLPromise __weak *weakExtendedPromise1;
  FBLPromise __weak *weakExtendedPromise2;

  // Act.
  @autoreleasepool {
    XCTAssertNil(weakExtendedPromise1);
    XCTAssertNil(weakExtendedPromise2);
    FBLPromise *promise1 =
        [FBLPromise async:^(FBLPromiseFulfillBlock fulfill, FBLPromiseRejectBlock __unused _) {
          fulfill(@42);
        }];
    FBLPromise *promise2 =
        [FBLPromise async:^(FBLPromiseFulfillBlock fulfill, FBLPromiseRejectBlock __unused _) {
          fulfill(@42);
        }];
    FBLPromise *extendedPromise1 = promise1;
    FBLPromise *extendedPromise2 = promise2;
    weakExtendedPromise1 = extendedPromise1;
    weakExtendedPromise2 = extendedPromise2;
    XCTAssertNotNil(weakExtendedPromise1);
    XCTAssertNotNil(weakExtendedPromise2);
  }

  // Assert.
  XCTAssertNotNil(weakExtendedPromise1);
  XCTAssertNotNil(weakExtendedPromise2);
  XCTAssert(FBLWaitForPromisesWithTimeout(10));
  XCTAssertNil(weakExtendedPromise1);
  XCTAssertNil(weakExtendedPromise2);
}

@end
