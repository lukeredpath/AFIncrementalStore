//
//  AFIncrementalStoreTests.m
//  AFIncrementalStoreTests
//
//  Created by Luke Redpath on 29/11/2012.
//  Copyright (c) 2012 LJR Software Ltd. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "AFIncrementalStore.h"
#import "AFRESTClient.h"
#import "AFServerStub.h"
#import "NSManagedObjectContextChangeObserver.h"

@interface TestCaseIncrementalStore : AFIncrementalStore
@end

@implementation TestCaseIncrementalStore

+ (void)initialize
{
    [NSPersistentStoreCoordinator registerStoreClass:self forStoreType:[self type]];
}

+ (NSString *)type
{
    return NSStringFromClass(self);
}

+ (NSManagedObjectModel *)model
{
    static NSManagedObjectModel *_model = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _model = [[NSManagedObjectModel alloc] init];
        
        [self defineModel:_model];
    });
    
    return _model;
}

+ (void)defineModel:(NSManagedObjectModel *)model
{
    NSEntityDescription *widgetEntity = [[NSEntityDescription alloc] init];
    widgetEntity.name = @"Widget";
    
    NSAttributeDescription *hrefAttribute = [[NSAttributeDescription alloc] init];
    hrefAttribute.name = @"href";
    hrefAttribute.attributeType = NSStringAttributeType;
    hrefAttribute.indexed = YES;
    
    NSAttributeDescription *nameAttribute = [[NSAttributeDescription alloc] init];
    nameAttribute.name = @"name";
    nameAttribute.attributeType = NSStringAttributeType;
    
    [widgetEntity setProperties:@[hrefAttribute, nameAttribute]];
    
    [model setEntities:@[widgetEntity]];
}

@end

@interface TestCaseHTTPClient : AFRESTClient

- (void)waitUntilAllOperationsAreFinished;

@end

@implementation TestCaseHTTPClient

+ (id)sharedClient
{
    static TestCaseHTTPClient *_sharedClient;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[self alloc] initWithBaseURL:[NSURL URLWithString:@"http://example.com"]];
    });
    
    return _sharedClient;
}

- (id)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (!self) {
        return nil;
    }
    
    [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
    [self setDefaultHeader:@"Accept" value:@"application/json"];
    
    return self;
}

- (NSString *)pathForEntity:(NSEntityDescription *)entity
{
    if ([entity.name isEqualToString:@"Widget"]) {
        return @"widgets";
    }
    return nil;
}

- (NSString *)pathForObject:(NSManagedObject *)object
{
    return [object valueForKey:@"href"];
}

- (NSString *)resourceIdentifierForRepresentation:(NSDictionary *)representation
                                         ofEntity:(NSEntityDescription *)entity
                                     fromResponse:(NSHTTPURLResponse *)response
{
    NSString *identifier = [super resourceIdentifierForRepresentation:representation ofEntity:entity fromResponse:response];
    
    if (identifier == nil) {
        identifier = [representation objectForKey:@"href"];
    }
    return identifier;
}

- (void)waitUntilAllOperationsAreFinished
{
    [self.operationQueue waitUntilAllOperationsAreFinished];
}

@end

DEFINE_TEST_CASE(AFIncrementalStoreIntegrationTests) {
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSManagedObjectContext *managedObjectContext;
    AFIncrementalStore *incrementalStore;
    AFServerStub *server;
}

- (void)setUp
{
    [super setUp];
    
    NSManagedObjectModel *model = [TestCaseIncrementalStore model];
    
    NSAssert(model, @"Could not create a managed object model, aborting test case.");

    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    
    incrementalStore = (AFIncrementalStore *)[persistentStoreCoordinator addPersistentStoreWithType:[TestCaseIncrementalStore type] configuration:nil URL:nil options:nil error:nil];
    
    NSAssert(incrementalStore, @"Incremental store could not be created, aborting test case.");
    
    incrementalStore.HTTPClient = [TestCaseHTTPClient sharedClient];
    
    NSDictionary *backingStoreOptions = @{NSInferMappingModelAutomaticallyOption : @YES};
    NSError *error = nil;
    
    if(![incrementalStore.backingPersistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:backingStoreOptions error:&error]) {
        NSAssert1(nil, @"Could not create in-memory backing store (error: %@)", error);
    }
    
    managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator;
    
    server = [[AFServerStub alloc] initWithBaseURL:incrementalStore.HTTPClient.baseURL];
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testFetchRequestWhenNoLocalObjectsExistEnqueuesAnOperationAndReturnsAnEmptyResultSet
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Widget"];
    
    [server requestsForPath:@"/widgets" willReturnJSONObject:@{}];

    __block NSArray *results;
    
    [managedObjectContext performBlockAndWait:^{
        results = [managedObjectContext executeFetchRequest:fetchRequest error:nil];
    }];
    
    expect(incrementalStore.HTTPClient.operationQueue.operationCount).to.equal(1);
    expect(results).to.haveCountOf(0);
}

- (void)testFetchRequestWillEventuallyReturnResultsFromServerAndUpdateTheManagedObjectContext
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Widget"];
    
    [server requestsForPath:@"/widgets" willReturnJSONObject:@{
        @"name": @"Test Widget",
        @"href": @"/widgets/123"
    }];
    
    [managedObjectContext performBlockAndWait:^{
        [managedObjectContext executeFetchRequest:fetchRequest error:nil];
    }];
    
    __block BOOL contextDidChange = NO;
    __block NSArray *objectsFromServerResponse = nil;
    
    [NSManagedObjectContextChangeObserver observerForChangesToContext:managedObjectContext notificationHandler:^(NSNotification *note, BOOL *stopObserving) {
        objectsFromServerResponse = [[note.userInfo objectForKey:NSInsertedObjectsKey] allObjects];
        contextDidChange = YES;
        *stopObserving = YES;
    }];
    
    expect(contextDidChange).will.beTruthy();
    expect(objectsFromServerResponse).to.haveCountOf(1);
    
    expect([[objectsFromServerResponse lastObject] valueForKey:@"name"]).to.equal(@"Test Widget");
    expect([[objectsFromServerResponse lastObject] valueForKey:@"href"]).to.equal(@"/widgets/123");
}

- (void)testNewRemoteObjectsReceivedAsResultOfFetchRequestWillBeAddedToLocalBackingStore
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Widget"];
    
    [server requestsForPath:@"/widgets" willReturnJSONObject:@{
        @"name": @"Test Widget",
        @"href": @"/widgets/123"
    }];
    
    __block NSArray *results = nil;
    
    [managedObjectContext performBlockAndWait:^{
        results = [managedObjectContext executeFetchRequest:fetchRequest error:nil];
    }];
    
    expect(results).to.haveCountOf(0);
    
    [NSManagedObjectContextChangeObserver observerForChangesToContext:managedObjectContext notificationHandler:^(NSNotification *note, BOOL *stopObserving) {
        *stopObserving = YES;
        
        [managedObjectContext performBlockAndWait:^{
            results = [managedObjectContext executeFetchRequest:fetchRequest error:nil];
        }];
    }];
    
    expect(results).will.haveCountOf(1);
}

END_TEST_CASE
