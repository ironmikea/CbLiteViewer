//
//  Document.m
//  CbLiteViewer
//
//  Created by Mike Anderson on 12/1/20.
//

#import "Document.h"
#import "CBLiteDBController.h"

#import <Foundation/NSObject.h>
#import <CouchbaseLite/CouchbaseLite.h>

@interface Document (){
    @private
    
    NSString* _path;
    CBLDatabase* _db;
    NSString *_fileName;
    NSMutableArray<DBTable *> *_databaseTables;
    NSMutableArray<NSArray<NSString *>*>*_arrayOfKeysArray;
    NSMutableArray<DBTable *> *_deletedTables;
}

@end

@implementation Document

- (instancetype)init {
    self = [super init];
    if (self) {
        // Add your subclass-specific initialization here.
    }
    return self;
}

+ (BOOL)autosavesInPlace {
    return YES;
}


- (void)makeWindowControllers {
    
    // Override to return the Storyboard file name of the document.
    
    CBLiteDBController* controller = [[CBLiteDBController alloc]
                initWithTableData:_databaseTables withKeys:_arrayOfKeysArray andDeleteArray:_deletedTables];
    [self addWindowController: controller];
}

- (instancetype)initWithType:(NSString *)typeName
                       error:(NSError * _Nullable *)outError {
    NSError *error = nil;
    
    self = [super init];
    if (self) {
        //Do your custom initialization
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        _path = [paths objectAtIndex:0];
        NSLog(@"%@ : path", _path);
        
        CBLDatabaseConfiguration *cbConfig = [CBLDatabaseConfiguration new];
        cbConfig.directory = _path;
        _db = [[CBLDatabase alloc]initWithName:@"New_Database" config:cbConfig error:&error];
        
        _databaseTables = [NSMutableArray new];
        _arrayOfKeysArray = [NSMutableArray new];
        _deletedTables = [NSMutableArray new];
    }
    return self;
}

///- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    // Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error if you return nil.
    // Alternatively, you could remove this method and override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
///    [NSException raise:@"UnimplementedMethod" format:@"%@ is unimplemented", NSStringFromSelector(_cmd)];
///    return nil;
///}


- (BOOL)writeSafelyToURL:(NSURL *)url
                  ofType:(NSString *)typeName
        forSaveOperation:(NSSaveOperationType)saveOperation
                   error:(NSError * _Nullable *)outError {
    
    NSLog(@"writeSafelyToURL:ofType:forSaveOperation:error:");
    
    return NO;
}

- (NSFileWrapper *)fileWrapperOfType:(NSString *)typeName
                               error:(NSError * _Nullable *)outError {
    
    NSString *someFileData = @"This is some data to put in a file";
    NSData *data = [someFileData dataUsingEncoding:NSUTF8StringEncoding];
    NSFileWrapper *fileWrapper = [[NSFileWrapper alloc]initRegularFileWithContents:data];
    return fileWrapper;
}


- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    // Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error if you return NO.
    // Alternatively, you could remove this method and override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    // If you do, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
    [NSException raise:@"UnimplementedMethod" format:@"%@ is unimplemented", NSStringFromSelector(_cmd)];
    return YES;
}

- (BOOL)readFromURL:(NSURL *)absoluteURL
             ofType:(NSString *)typeName
              error:(NSError **)outError
{
    
    //BOOL isNewFormat = [extension isEqualToString: @"cblite2"];
    NSString *path = nil;
    
    if (absoluteURL) {
        
        NSLog(@"Opening %@", absoluteURL.path);
        _path = absoluteURL.path;
        NSString* extension = _path.pathExtension;
        if (![absoluteURL isFileURL] || ![@[@"cblite", @"cblite2"] containsObject: extension]) {
            return returnErrorWithMessage(@"This file format is not supported.", outError);
        }
        path = absoluteURL.path;
        NSString *searchStr = @"/";
        NSRange searchRange = NSMakeRange(0, [path length] - 1);
        NSRange range = [path rangeOfString:searchStr
                         options:NSLiteralSearch | NSBackwardsSearch
                                                    range:searchRange];
        if (range.location != NSNotFound) {
            
            NSRange directoryRange = NSMakeRange(0, range.location);
            NSRange fileNameRange = NSMakeRange(range.location + 1, ([path length] - (range.location + 1))) ;
            CBLDatabaseConfiguration *cbConfig = [CBLDatabaseConfiguration new];
            _path = [path substringWithRange:directoryRange];
            cbConfig.directory = _path;
            NSString *filenameWithExtension = [path substringWithRange:fileNameRange];
            NSString *period = @".";
            NSRange newRange = [filenameWithExtension rangeOfString:period];
            _fileName = [filenameWithExtension substringWithRange:NSMakeRange(0, newRange.location)];
            _db = [[CBLDatabase alloc]initWithName:_fileName config:cbConfig error:outError];
            
            if (!_db) {
                returnErrorWithMessage(@"Failed to open database.", outError);
                return NO;
            }
            [self loadData];
            return YES;
        }
    }
    return NO;
}

static BOOL returnErrorWithMessage(NSString* message, NSError **outError) {
    if (outError) {
        NSDictionary* userInfo = @{NSLocalizedFailureReasonErrorKey: message};
        *outError = [NSError errorWithDomain: @"CbLiteViewer" code: -1 userInfo: userInfo];
    }
    return NO;
}

- (void)loadData {
    
    _databaseTables = [NSMutableArray new];
    _arrayOfKeysArray = [NSMutableArray new];
    _deletedTables = [NSMutableArray new];
    
    NSError *error;
    NSInteger count = 0;
    //- (CBLQuery*) createAllDocumentsQuery
    CBLQuery *query = [CBLQueryBuilder select:@[[CBLQuerySelectResult all], [CBLQuerySelectResult expression:[CBLQueryMeta id]]]
                from:[CBLQueryDataSource database:_db]];
    
    NSEnumerator* rs = [query execute:&error];
    for (CBLQueryResult *result in rs) {
        
        id value = [result valueAtIndex:0];
        id value_id = [result valueAtIndex:1];
        if([value isKindOfClass:[CBLDictionary class]]) {
            NSDictionary *dict = [value toDictionary];
            NSMutableDictionary *mutableDict = [[NSMutableDictionary alloc]initWithDictionary:dict];
            DBTable *dbTable = [[DBTable alloc]initWithName:value_id andDetails:mutableDict];
            //[self makeTableEditable:dbTable.detailsDict];
            [dbTable setIndex:count++];
            NSArray<NSString *> *keys = [dict allKeys];
            
            [_databaseTables addObject:dbTable];
            [_arrayOfKeysArray addObject:keys];
        }
        else {
            // intrinsic types
            NSLog(@"%@", [NSString stringWithFormat:@"value = %@", value]);
        }
    }
}

- (NSString *)createDocument:(NSDictionary *)genericDocDict andError:(NSError **)error {
    
    NSString *name = nil;
    CBLMutableDocument *mutableDoc;
        
    mutableDoc = [[CBLMutableDocument alloc] init];
    [mutableDoc setValuesForKeysWithDictionary:genericDocDict];
    
    // Save it to the database.
    if (mutableDoc != nil) {
        BOOL retVal = [_db saveDocument:mutableDoc error:error];
        if (retVal == NO) {
            
            // display error
        }
        
        // test code to read it back
        CBLDocument *cbGenericDoc = [_db documentWithID:mutableDoc.id];
        NSDictionary* dict = [cbGenericDoc toDictionary];
        NSLog(@"%@ dictionary saved, read back: %@", mutableDoc.id, dict);
        name = mutableDoc.id;
    }
    return name;
}

-(BOOL)updateDocument:(NSDictionary *)updatedDict usingID:(NSString *)identifier
    andError:(NSError **)error {
    
    BOOL retVal = NO;
    CBLMutableDocument *mutableDoc = nil;
    
    CBLDocument *cbDocument = [_db documentWithID:identifier];
    
    if (cbDocument != nil) {
        // first iteration checks to see if anything was added or changed
        mutableDoc = [cbDocument toMutable];
        NSEnumerator *enumerator = [updatedDict keyEnumerator];
        id key;
        while (key = [enumerator nextObject])
        {
            id value = [updatedDict valueForKey:key];
            id savedValue = [mutableDoc valueForKey:key];
            if (savedValue == nil) {
                [mutableDoc setValue:value forKey:key];
                continue;
            }
            
            if([value isKindOfClass:[NSString class]]) {
                // here we are not going to compare dates since couchbase lite stores
                // them as strings and there really is no need to compare them
                NSString *strValue = value;
                if (![(NSString *)strValue isEqualToString:savedValue]) {
                    
                    [mutableDoc setValue:value forKey:key];
                }
            }
            else if([value isKindOfClass:[CBLBlob class]]) {
                
                CBLBlob *imageData = (CBLBlob *)value;
                if (imageData != nil) {
                    
                    [mutableDoc setBlob:imageData forKey:key];
                }
            }
            else if([value isKindOfClass:[NSNumber class]]) {
                
                NSNumber *numberValue = (NSNumber *)value;
                NSComparisonResult result = [numberValue compare:(NSNumber *)savedValue];
                if (result != NSOrderedSame) {
                    [mutableDoc setValue:numberValue forKey:key];
                }
            }
            else if([value isKindOfClass:[NSArray class]]) {
                
                NSArray *arrayItems = (NSArray *)value;
                [mutableDoc setValue:arrayItems forKey:key];
            }
            else if([value isKindOfClass:[NSDictionary class]]) {
                
                NSDictionary *dictionaryItems = (NSDictionary *)value;
                //[mutableDoc setValue:dictionaryItems forKey:keyStr];
                // dictionary compare (could be recursive)
                //
                // if anything changed
                // set new dictionary
                [mutableDoc setValue:dictionaryItems forKey:key];
            }
            else {
                NSAssert(NO, @"CouchBaseDatabaseMgr::updateVessel: some other data type");
            }
        }
        // second itertion checks to see if anything was removed
        NSDictionary *savedDictionary = [mutableDoc toDictionary];
        NSEnumerator *enumer = [savedDictionary keyEnumerator];
        id saveKey;
        while (saveKey = [enumer nextObject]) {
            
            id newValue = [updatedDict valueForKey:saveKey];
            if (newValue == nil) {
                [mutableDoc removeValueForKey:saveKey];
            }
        }
    }
    else {
        NSAssert(NO, @"Unable to read back the vessel document");
    }
    // Save it to the database.
    if (mutableDoc != nil) {
        
        retVal = [_db saveDocument:mutableDoc error:error];
    }
    return retVal;
}



- (IBAction)saveAsDocument:(id)sender {
    
    NSLog(@"saveAsDocument");
    
    [self runModalSavePanelForSaveOperation:NSSaveAsOperation
                delegate:self
                didSaveSelector:@selector(document:didSave:contextInfo:) contextInfo:nil];
    
    
}

- (void)document:(NSDocument *)doc didSave:(BOOL)didSave contextInfo:(void  *)contextInfo {
    
    NSLog(@"document:didSave:contextInfo:");
}

- (IBAction)revertToSaved:(id)sender {
    
    
}

- (IBAction)closeDocument:(id)sender {
    
    NSError *error;
    NSLog(@"closeDocument called");
    [_db close:&error];
}

- (IBAction)saveDocument:(id)sender {
    
    NSError *error;
    for (DBTable *table in _databaseTables) {
        
        BOOL tableUpdated = NO;
        NSMutableDictionary *mutableDict = table.detailsDict;
        if (table.mStatus == NEW) {
            
            NSString *docName = [self createDocument:mutableDict andError:&error];
            if (docName != nil) {
                table.name = docName;
            }
            tableUpdated = YES;
        }
        else if (table.mStatus == EDITED) {
            
            BOOL updated = [self updateDocument:mutableDict usingID:table.name andError:&error];
            if (updated ) {
                tableUpdated = YES;
            }
        }
        if (tableUpdated) {
            
            NSArray<NSWindowController *> *controllers = self.windowControllers;
            if ([controllers[0] isKindOfClass:[CBLiteDBController class]]) {
                
                CBLiteDBController *controller = (CBLiteDBController *)controllers[0];
                [controller updateAfterSaving:table];
            }
        }
    }
    
    // deleted tables
    for (DBTable *table in _deletedTables) {
        
        CBLDocument *cblDocument = [_db documentWithID:table.name];
        if (cblDocument != nil) {
            BOOL success = [_db deleteDocument:cblDocument error:&error];
            if (!success) {
                //display error
                NSLog(@"CouchBase delete error: %@", [error localizedDescription]);
            }
        }
    }
    if ([_deletedTables count] > 0) {
        
        [_deletedTables removeAllObjects];
    }
}


- (BOOL)isIntrinsicTypes:(id)item {
    
    return ([item isKindOfClass:NSString.class] ||
            [item isKindOfClass:NSNumber.class] ||
            [item isKindOfClass:NSDate.class] ||
            [item isKindOfClass:CBLBlob.class]);
}

- (void)checkForTempDatabase {
    
    NSLog(@"checkForTempDatabase called");
}


@end
