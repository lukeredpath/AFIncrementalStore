//
//  AFMockServer.h
//  AFIncrementalStore
//
//  Created by Luke Redpath on 30/11/2012.
//  Copyright (c) 2012 LJR Software Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AFServerStub : NSObject

/* Designated initializer. 
 
 The mock server will only handle requests with the specified base URL.
 */
- (id)initWithBaseURL:(NSURL *)URL;

/* Stubs responses to the specified path to return the given JSON object.
 
 Responses will have a 200 status code and an application/json content type.
 */
- (void)requestsForPath:(NSString *)path willReturnJSONObject:(id)object;

@end
