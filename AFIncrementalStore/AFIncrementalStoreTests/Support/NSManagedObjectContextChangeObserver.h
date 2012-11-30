//
//  NSManagedObjectContextChangeObserver.h
//  AFIncrementalStore
//
//  Created by Luke Redpath on 30/11/2012.
//  Copyright (c) 2012 LJR Software Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

typedef void (^NSManagedObjectContextChangedObserverNotificationHandlerBlock) (NSNotification *note, BOOL *stopObserving);

@interface NSManagedObjectContextChangeObserver : NSObject

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context
               notificationHandler:(NSManagedObjectContextChangedObserverNotificationHandlerBlock)notificationHandler;

+ (id)observerForChangesToContext:(NSManagedObjectContext *)context
              notificationHandler:(NSManagedObjectContextChangedObserverNotificationHandlerBlock)notificationHandler;

@end
