//
//  AFManagedObjectModelBuilder.h
//  AFIncrementalStore
//
//  Created by Luke Redpath on 30/11/2012.
//  Copyright (c) 2012 LJR Software Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class AFEntityDefinition;

/* Provides a high-level API for constructing a managed object model.
 */
@interface AFManagedObjectModelBuilder : NSObject

/* Designated initializer.
 
 The passed in managed object model must not be assigned to a persistent store
 coordinator, or it will no longer be mutable.
 */
- (id)initWithManagedObjectModel:(NSManagedObjectModel *)managedObjectModel;

/* Defines a new entity. 
 
 The definition block is called with an AFEntityDefinition, which provides the 
 interface for defining the named entity.
 */
- (void)defineEntityNamed:(NSString *)entityName definition:(void (^)(AFEntityDefinition *definition))definitionBlock;

/* Updates the model with the configured definitions.
 */
- (void)build;

@end

@interface AFEntityDefinition : NSObject

- (void)addAttribute:(NSString *)attributeName type:(NSAttributeType)type isIndexed:(BOOL)isIndexed;

@end
