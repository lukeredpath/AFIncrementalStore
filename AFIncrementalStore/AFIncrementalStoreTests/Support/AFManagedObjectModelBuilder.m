//
//  AFManagedObjectModelBuilder.m
//  AFIncrementalStore
//
//  Created by Luke Redpath on 30/11/2012.
//  Copyright (c) 2012 LJR Software Ltd. All rights reserved.
//

#import "AFManagedObjectModelBuilder.h"

@interface AFEntityDefinition ()

- (id)initWithEntityName:(NSString *)name;
- (NSEntityDescription *)build;

@end

@implementation AFManagedObjectModelBuilder {
    NSManagedObjectModel *_model;
    NSMutableSet *_entityDefinitions;
}

- (id)initWithManagedObjectModel:(NSManagedObjectModel *)managedObjectModel
{
    if ((self = [super init])) {
	    _model = managedObjectModel;
        _entityDefinitions = [[NSMutableSet alloc] init];
    }
    return self;
}

- (void)defineEntityNamed:(NSString *)entityName definition:(void (^)(AFEntityDefinition *))definitionBlock
{
    NSParameterAssert(definitionBlock);
    
    AFEntityDefinition *definition = [[AFEntityDefinition alloc] initWithEntityName:entityName];
    definitionBlock(definition);
    
    [_entityDefinitions addObject:definition];
}

- (void)build
{
    NSMutableArray *entities = [NSMutableArray arrayWithCapacity:_entityDefinitions.count];
    
    for (AFEntityDefinition *definition in _entityDefinitions) {
        [entities addObject:[definition build]];
    }
    
    [_model setEntities:entities];
}

@end

@implementation AFEntityDefinition {
    NSEntityDescription *_entityDescription;
    NSMutableSet *_attributes;
}

- (id)initWithEntityName:(NSString *)name
{
    if ((self = [super init])) {
	    _entityDescription = [[NSEntityDescription alloc] init];
        _entityDescription.name = name;
        
        _attributes = [[NSMutableSet alloc] init];
    }
    return self;
}

- (NSEntityDescription *)build
{
    [_entityDescription setProperties:[_attributes allObjects]];
    return _entityDescription;
}

- (void)addAttribute:(NSString *)attributeName type:(NSAttributeType)type isIndexed:(BOOL)isIndexed
{
    NSAttributeDescription *attribute = [[NSAttributeDescription alloc] init];
    [attribute setName:attributeName];
    [attribute setAttributeType:type];
    [attribute setIndexed:isIndexed];
    [_attributes addObject:attribute];
}

@end