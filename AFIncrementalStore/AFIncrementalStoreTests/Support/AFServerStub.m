//
//  AFMockServer.m
//  AFIncrementalStore
//
//  Created by Luke Redpath on 30/11/2012.
//  Copyright (c) 2012 LJR Software Ltd. All rights reserved.
//

#import "AFServerStub.h"
#import "OHHTTPStubs.h"

@implementation AFServerStub {
    NSURL *_baseURL;
}

- (id)initWithBaseURL:(NSURL *)URL
{
    if ((self = [super init])) {
	    _baseURL = URL;
    }
    return self;
}

- (void)requestsForPath:(NSString *)path willReturnJSONObject:(id)object
{
    [OHHTTPStubs addRequestHandler:^OHHTTPStubsResponse *(NSURLRequest *request, BOOL onlyCheck) {
        if (![request.URL isEqual:[_baseURL URLByAppendingPathComponent:path]]) {
            return nil;
        }
        return [OHHTTPStubsResponse responseWithData:[NSJSONSerialization dataWithJSONObject:object options:0 error:nil]
                                          statusCode:200
                                        responseTime:0
                                             headers:@{@"Content-Type" : @"application/json"}];
    }];
}

@end
