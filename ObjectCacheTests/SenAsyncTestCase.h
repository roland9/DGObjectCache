//
//  SenAsyncTestCase.h
//  Viscis
//
//  Created by Damien Glancy on 02/10/2012.
//  Copyright (c) 2012 com.viscis. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SenTestingKit/SenTestingKit.h>

enum {
    SenAsyncTestCaseStatusUnknown = 0,
    SenAsyncTestCaseStatusWaiting,
    SenAsyncTestCaseStatusSucceeded,
    SenAsyncTestCaseStatusFailed,
    SenAsyncTestCaseStatusCancelled,
};
typedef NSUInteger SenAsyncTestCaseStatus;


@interface SenAsyncTestCase : SenTestCase

- (void)waitForStatus:(SenAsyncTestCaseStatus)status timeout:(NSTimeInterval)timeout;
- (void)waitForTimeout:(NSTimeInterval)timeout;
- (void)notify:(SenAsyncTestCaseStatus)status;

@end