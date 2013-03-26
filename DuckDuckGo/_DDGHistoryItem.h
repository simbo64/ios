// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to DDGHistoryItem.h instead.

#import <CoreData/CoreData.h>


extern const struct DDGHistoryItemAttributes {
	__unsafe_unretained NSString *timeStamp;
	__unsafe_unretained NSString *title;
	__unsafe_unretained NSString *urlString;
} DDGHistoryItemAttributes;

extern const struct DDGHistoryItemRelationships {
	__unsafe_unretained NSString *story;
} DDGHistoryItemRelationships;

extern const struct DDGHistoryItemFetchedProperties {
	__unsafe_unretained NSString *fetchedProperty;
} DDGHistoryItemFetchedProperties;

@class DDGStory;





@interface DDGHistoryItemID : NSManagedObjectID {}
@end

@interface _DDGHistoryItem : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (DDGHistoryItemID*)objectID;




@property (nonatomic, strong) NSDate* timeStamp;


//- (BOOL)validateTimeStamp:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* title;


//- (BOOL)validateTitle:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* urlString;


//- (BOOL)validateUrlString:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) DDGStory* story;

//- (BOOL)validateStory:(id*)value_ error:(NSError**)error_;




+ (NSArray*)fetchHistoryItemsWithPrefix:(NSManagedObjectContext*)moc_ ;
+ (NSArray*)fetchHistoryItemsWithPrefix:(NSManagedObjectContext*)moc_ error:(NSError**)error_;



@property (nonatomic, readonly) NSArray *fetchedProperty;


@end

@interface _DDGHistoryItem (CoreDataGeneratedAccessors)

@end

@interface _DDGHistoryItem (CoreDataGeneratedPrimitiveAccessors)


- (NSDate*)primitiveTimeStamp;
- (void)setPrimitiveTimeStamp:(NSDate*)value;




- (NSString*)primitiveTitle;
- (void)setPrimitiveTitle:(NSString*)value;




- (NSString*)primitiveUrlString;
- (void)setPrimitiveUrlString:(NSString*)value;





- (DDGStory*)primitiveStory;
- (void)setPrimitiveStory:(DDGStory*)value;


@end