//
//  NSManagedObjectContextChangeObserver.m
//  AFIncrementalStore
//
//  Created by Luke Redpath on 30/11/2012.
//  Copyright (c) 2012 LJR Software Ltd. All rights reserved.
//

#import "NSManagedObjectContextChangeObserver.h"

@implementation NSManagedObjectContextChangeObserver {
    NSManagedObjectContextChangedObserverNotificationHandlerBlock _notificationHandler;
}

+ (id)observerForChangesToContext:(NSManagedObjectContext *)context
              notificationHandler:(NSManagedObjectContextChangedObserverNotificationHandlerBlock)notificationHandler
{
    return [[self alloc] initWithManagedObjectContext:context notificationHandler:notificationHandler];
}

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context
               notificationHandler:(NSManagedObjectContextChangedObserverNotificationHandlerBlock)notificationHandler
{
    if ((self = [super init])) {
        NSParameterAssert(notificationHandler);
        
        _notificationHandler = [notificationHandler copy];
        
	    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextDidChange:) name:NSManagedObjectContextObjectsDidChangeNotification object:context];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)contextDidChange:(NSNotification *)note
{
    BOOL stopObserving = NO;
    
    _notificationHandler(note, &stopObserving);
    
    if (stopObserving) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}

@end
