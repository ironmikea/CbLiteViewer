//
//  CBLiteDBController.m
//  CbLiteViewer
//
//  Created by Mike Anderson on 12/9/20.
//

// 1660

#import "CBLiteDBController.h"

#import "ImageFileViewer.h"
#import "AddViewDateViewer.h"
#import "AppDelegate.h"

#import "CBLBlob+copyZone.h"

#import "Document.h"


#import <CouchbaseLite/CouchbaseLite.h>
#import <Quartz/Quartz.h>

@class CBLBlob;

static NSString *newDocument = @"New Document";
static NSString *dateFormatString = @"MM-dd-yyyy HH:mm";
static NSString *cbLiteDateFormatStr = @"yyyy-MM-dd'T'HH:mm.ss.SSSZ";

@implementation DBTable

- (id) initWithName:(NSString *)name andDetails:(NSMutableDictionary*)details{
    
    self = [super init];
    if (self)
    {
        self.name = name;
        self.detailsDict = details;
        self.mStatus = NOCHANGE;
    }
    return self;
}

- (id)initWithTableCopy:(DBTable *)table {
    
    self = [super init];
    if (self) {
        
        self.name = newDocument;
        NSMutableDictionary *newDict = [[NSMutableDictionary alloc]init];
        self.detailsDict = [DBTable deepCopyFromDictionary:table.detailsDict toDictionary:newDict];
        self.mStatus = NEW;
    }
    return self;
}

+ (NSMutableDictionary *)deepCopyFromDictionary:(NSDictionary *)existingTableDict
                                   toDictionary:(NSMutableDictionary *)newTableDict {
        
    for (id key in [existingTableDict allKeys]) {

        id value =  [existingTableDict objectForKey:key];
        if ([value isKindOfClass:[NSDictionary class]]) {
            
            NSMutableDictionary *dict = [NSMutableDictionary new];
            dict = [DBTable deepCopyFromDictionary:value toDictionary:dict];
            [newTableDict setObject:dict forKey:key];
        }
        else if ([value isKindOfClass:[NSArray class]]) {
            
            NSMutableArray *newArray = [NSMutableArray new];
            for (id item in value) {
                
                if ([item isKindOfClass:[NSDictionary class]]) {
                    
                    NSMutableDictionary *dict = [NSMutableDictionary new];
                    dict = [DBTable deepCopyFromDictionary:item toDictionary:dict];
                    [newArray addObject:dict];
                }
                else if ([item isKindOfClass:[NSArray class]]) {
                    
                    NSMutableArray *secondNewArray = [NSMutableArray new];
                    for (id entry in item) {
                        
                        if ([entry isKindOfClass:[NSDictionary class]]) {
                            
                            NSMutableDictionary *dict = [NSMutableDictionary new];
                            dict = [DBTable deepCopyFromDictionary:entry toDictionary:dict];
                            [secondNewArray addObject:dict];
                        }
                        else if ([entry isKindOfClass:[NSArray class]]) {
                            NSAssert(NO, @"3rd nesting, array of array or array not supported");
                        }
                        else {
                            id newItem = [item copy];
                            [secondNewArray addObject:newItem];
                        }
                    }
                }
                else {
                    id newItem = [item copy];
                    [newArray addObject:newItem];
                }
            }
            [newTableDict setObject:newArray forKey:key];
        }
        else {
            id newValue = [value copy];
            [newTableDict setObject:newValue forKey:key];
        }
        
    }
    return newTableDict;
}

- (NSInteger)getIndex {
    
    return mIndex;
}
- (void)setIndex:(NSInteger)index {
    
    mIndex = index;
}


@end

static NSString *itemStr = @"item";
static NSString *newValue = @"new item";
static NSString *newKey = @"new key";

@interface CBLiteDBController () {

    @private
    NSMutableArray<DBTable *> *mDatabaseTables;
    NSMutableArray<DBTable *> *mDeleteTables;
    NSMutableArray<NSArray<NSString *>*>*mArrayOfKeysArray;
    id copyTable;
}

@end

@implementation CBLiteDBController


- (id)initWithTableData: (NSMutableArray<DBTable *> *)databaseTables withKeys:
    (NSMutableArray<NSArray<NSString *>*>*)arrayOfKeysArray andDeleteArray:(NSMutableArray<DBTable *> *)deleteTables {
    
    NSParameterAssert(databaseTables != nil);
    NSParameterAssert(arrayOfKeysArray != nil);
    self = [super initWithWindowNibName: @"CBLiteDBController"];
    if (self) {
        mDatabaseTables = databaseTables;
        mArrayOfKeysArray = arrayOfKeysArray;
        mDeleteTables = deleteTables;
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    
    self.mAddBtn.enabled = NO;
    self.addDateBtn.enabled = NO;
    self.addPhotoBtn.enabled = NO;
    self.addArrayWDictBtn.enabled = NO;
    self.addDictBtn.enabled = NO;
    
    copyTable = nil;
    
    NSWindow *window = self.window;
    NSView *contentView = window.contentView;
    NSScrollView *scrollView = contentView.subviews[0];
    NSView *nextView = scrollView.contentView;
    self.outlineView = nextView.subviews[0];

    self.outlineView.delegate = self;
    self.outlineView.dataSource = self;
    //self.outlineView.doubleAction;
}




#pragma mark - NSOutlineView datasource

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(nullable id)item {
    
    id value = nil;
    DBTable *table = nil;
    if (item == nil) {
       return [mDatabaseTables count];  // return number of tables
    }
    else if ([item isKindOfClass:[DBTable class]]) {
        
        table = (DBTable *)item;
        return [[table.detailsDict allKeys] count];
    }
    else if ([item isKindOfClass:[NSArray class]]) { // level 2
        
        NSArray *array = (NSArray *)item;
        NSString *previousKey = array[0];
        table = array[1];
        id container = nil;
        
        value = [self getSelectedValueAndContainer:&container withKey:previousKey fromTable:table];
        //
        if ([value isKindOfClass:[NSDictionary class]]) {
            // advance to next level
            return [value count];
        }
        else if ([value isKindOfClass:[NSArray class]]) {
            
            id subValue = [(NSArray *)value objectAtIndex:0];
            if (![self isIntrinsicTypes:subValue]) {
                
                return [value count];
            }
        }
    }
    return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(nullable id)item {
    
    DBTable *table = nil;
    if (item == nil) { // each table
        return mDatabaseTables[index];
    }
    else if ([item isKindOfClass:[DBTable class]]) { // level 1
        
        table = (DBTable *)item;
        NSArray *keys = [table.detailsDict allKeys];
        //return keys[index];
        return [NSArray arrayWithObjects:keys[index], table, nil];
    }
    else if ([item isKindOfClass:[NSArray class]]) { // level 2
        
        NSArray *array = (NSArray *)item;
        NSString *previousKey = array[0];
        table = array[1];
        NSMutableArray *keyArray = nil;
        if (![self keyHasArrayIndex:previousKey withItems:&keyArray])
        {
            id value = [table.detailsDict valueForKeyPath:previousKey];
            if (value != nil) {
                
                NSMutableString *theKey = [NSMutableString new];
                [theKey appendString:previousKey];
                [theKey appendString:@"."];
                
                if ([value isKindOfClass:[NSDictionary class]]) {
                    
                    NSArray *keys = [(NSDictionary *)value allKeys];
                    [theKey appendString:keys[index]];
                    return [NSArray arrayWithObjects:theKey, table, nil];
                }
                else if ([value isKindOfClass:[NSArray class]]) {
                    
                    if ([(NSArray *)value count] > 0) {
                        
                        id subValue = [(NSArray *)value objectAtIndex:index];
                        if ([subValue isKindOfClass:[NSDictionary class]]) {
                            
                            // fabricating a key at this point
                            [theKey appendString:[NSString stringWithFormat:@"%lu", index]];
                            return [NSArray arrayWithObjects:theKey, table, nil];
                        }
                    }
                }
            }
        }
        else {
            
            NSInteger count = 0;
            NSDictionary *dictionary = table.detailsDict;
            NSMutableString *keyNew = [NSMutableString new];
            [keyNew appendString:previousKey];
            for (id entry in keyArray) {
                id value;
                if ([entry isKindOfClass:[NSNumber class]]) {
                    if ([dictionary isKindOfClass:[NSArray class]]) {
                        
                        NSArray *array = (NSArray *)dictionary;
                        id nextValue = [array objectAtIndex:((NSNumber *)entry).intValue];
                        if ([nextValue isKindOfClass:[NSDictionary class]]) {
                            
                            dictionary = (NSDictionary *)nextValue;
                            if (count == [keyArray count] - 1) {
                                NSArray* nextKeys = [dictionary allKeys];
                                // this is the end
                                [keyNew appendString:@"."];
                                [keyNew appendString:nextKeys[index]];
                                return [NSArray arrayWithObjects:keyNew, table, nil];
                            }
                        }
                        else if ([nextValue isKindOfClass:[NSArray class]]) {
                            
                            // what about an array of arrays???
                        }
                    }
                }
                else {
                    
                    value = [dictionary objectForKey:entry];
                    dictionary = value;
                    if (count == [keyArray count] - 1) {
                        if ([value isKindOfClass:[NSDictionary class]]) {
                        
                            NSArray* nextKeys = [dictionary allKeys];
                            [keyNew appendString:@"."];
                            [keyNew appendString:nextKeys[index]];
                            return [NSArray arrayWithObjects:keyNew, table, nil];
                        }
                    }
                }
                count++;
            }
            
        }
    }
    return nil;
}


- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    
    id value = nil;
    if ([item isKindOfClass:[DBTable class]]) {
        
        return YES;
    }
    else if ([item isKindOfClass:[NSArray class]]) { // level 2
        
        NSArray *array = (NSArray *)item;
        NSString *previousKey = array[0];
        DBTable *table = array[1];
        id container = nil;
        
        value = [self getSelectedValueAndContainer:&container withKey:previousKey fromTable:table];
        //
        if ([value isKindOfClass:[NSDictionary class]]) {
            // advance to next level
            return YES;
        }
        else if ([value isKindOfClass:[NSArray class]]) {
            
            id subValue = [(NSArray *)value objectAtIndex:0];
            if (![self isIntrinsicTypes:subValue]) {
                return YES;
            }
        }
    }
    return NO;
}


- (nullable NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(nullable NSTableColumn *)tableColumn item:(id)item {
    
    NSTableCellView* cell = nil;
    NSString *columnIdentifier = tableColumn.identifier;
    if (columnIdentifier != nil) {
        NSString *text = @"";
    
        if ([columnIdentifier isEqualToString:@"keyColumn"]) {
            
            cell = [outlineView makeViewWithIdentifier:@"KeyColumnCell" owner:self];
            
            if ([item isKindOfClass:[DBTable class]]) {
                
                DBTable *table = (DBTable *)item;
                text = table.name;
                cell.textField.editable = NO;
            }
            else if ([item isKindOfClass:[NSArray class]]) {
                
                NSArray *array = (NSArray *)item;
                
                NSMutableArray *keyArray = nil;
                [self keyHasArrayIndex:array[0] withItems:&keyArray];
                
                id value = keyArray[[keyArray count] - 1];
                if ([value isKindOfClass:[NSNumber class]]) {
                    
                    text = [NSString stringWithFormat:@"%@ %d", itemStr, ((NSNumber *)value).intValue + 1];
                }
                else {
                    text = value;
                    cell.textField.editable = YES;
                    [cell.textField setTarget:self];
                    [cell.textField setAction:@selector(onEditColumn:)];
                }
            }
        }
        else if ([columnIdentifier isEqualToString:@"valueColumn"]) {
            
            cell = [outlineView makeViewWithIdentifier:@"ValueColumnCell" owner:self];
            
            if ([item isKindOfClass:[NSArray class]]) {
                
                NSArray *array = (NSArray *)item;
                id container = nil;
                NSString *key = array[0];
                DBTable *table = array[1];
                
                id value = [self getSelectedValueAndContainer:&container withKey:key fromTable:table];
                
                if ([value isKindOfClass:[NSString class]]) {
                    
                    if ([self isDateAsString:value]) {
                        
                        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                        dateFormatter.dateFormat = cbLiteDateFormatStr;
                        NSDate *createdDate = [dateFormatter dateFromString:value];
                        dateFormatter.dateFormat = dateFormatString;
                        text = [dateFormatter stringFromDate:createdDate];
                    }
                    else {
                    
                        cell.textField.editable = YES;
                        [cell.textField setTarget:self];
                        [cell.textField setAction:@selector(onEditRow:)];
                        text = value;
                    }
                }
                else if ([value isKindOfClass:[NSDate class]]) {
                    
                    NSDateFormatter *dateFormatter = [NSDateFormatter new];
                    NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
                    [dateFormatter setLocale:usLocale];
                    [dateFormatter setDateFormat:dateFormatString];
                    
                    text = [dateFormatter stringFromDate:(NSDate *)value];
                }
                else if ([value isKindOfClass:[NSNumber class]]) {
                    
                    cell.textField.editable = YES;
                    [cell.textField setTarget:self];
                    [cell.textField setAction:@selector(onEditRow:)];
                    
                    if (strcmp([value objCType], @encode(double)) == 0) {
                        
                        NSNumberFormatter *formatter = [NSNumberFormatter new];
                        formatter.maximumFractionDigits = 5;
                        text = [formatter stringFromNumber:value];
                    }
                    else {
                        text = [(NSNumber *)value stringValue];
                    }
                }
                else if ([value isKindOfClass:[CBLBlob class]]) {
                    
                    text = [NSString stringWithFormat:@"%@", value];
                }
                else if ([value isKindOfClass:[NSArray class]]) {
                    
                    id subValue = [(NSArray *)value objectAtIndex:0];
                    if ([self isIntrinsicTypes:subValue]) {
                        
                        cell.textField.editable = YES;
                        [cell.textField setTarget:self];
                        [cell.textField setAction:@selector(onEditRow:)];
                        
                        NSMutableString *string = [NSMutableString new];
                        [string appendString:@"["];
                        for (id entry in (NSArray *)value) {
                            if ([entry isKindOfClass:NSString.class]) {
                                [string appendString: entry];
                                [string appendString:@", "];
                            }
                        }
                        // minus the last ", "
                        if ([string length] > 0) {
                            [string setString:[string substringWithRange: NSMakeRange(0, ([string length] - 2))]];
                            [string appendString:@"]"];
                            text = string;
                        }
                    }
                    else {
                        
                        text = [NSString stringWithFormat:@"%lu items", (unsigned long)[value count]];
                        cell.textField.editable = NO;
                    }
                }
                else if ([value isKindOfClass:[NSDictionary class]]) {
                    
                    text = [NSString stringWithFormat:@"%lu items", (unsigned long)[value count]];
                    cell.textField.editable = NO;
                }
            }
        }
        cell.textField.stringValue = text;
    }
    return cell;
}


- (IBAction)onEditRow:(id)sender
{
    NSInteger row = [self.outlineView rowForView:sender];
    BOOL updated = NO;
    NSString *entryKey = nil;
    if (row != -1) {
        DBTable *table = nil;
        id dictionary = nil;
        NSString *str = [sender stringValue];  //sender NSTextField
        id selectedItem = [self.outlineView itemAtRow:row]; // array key, dbtable
        
        if ([selectedItem isKindOfClass:[NSArray class]] ) {
            // parent is an array table, parent key (string)
            NSArray *entry = (NSArray *)selectedItem;
            NSString *key = entry[0];
            table = entry[1];
            
            id value = nil;
            NSMutableArray *keyArray = nil;
            NSInteger count = 0;
            if (![self keyHasArrayIndex:key withItems:&keyArray])
            {
                value = [table.detailsDict valueForKeyPath:key];
                dictionary = table.detailsDict;
                entryKey = key;
            }
            else {
                
                value = [table.detailsDict objectForKey:keyArray[0]];
                while (++count < [keyArray count]) {
                    
                    if ([keyArray[count] isKindOfClass:[NSNumber class]]) {
                        if ([value isKindOfClass:[NSArray class]]) {
                            
                            NSArray *array = (NSArray *)value;
                            value = [array objectAtIndex:((NSNumber *)keyArray[count]).intValue];
                        }
                    }
                    else {
                        dictionary = value;
                        value = [value objectForKey:keyArray[count]];
                    }
                }
                entryKey = keyArray[count - 1];
            }
            if ([dictionary isKindOfClass:[NSMutableDictionary class]] ) {
                
                id newValue = nil;
                NSLog(@"Changing value from %@, to %@", value, str);
                if ([str length] != 0) {
                
                    newValue = [self convertToValueTypeFromString:str];
                }
                else {
                    newValue = value;
                }
                [dictionary setValue:newValue forKeyPath:entryKey];
                updated = YES;
            }
        }
        
        if (updated) {
            
            if (table.mStatus == NOCHANGE) {
                
                table.mStatus = EDITED;
            }
            
            //[self.outlineView collapseItem:table];
            [self.outlineView beginUpdates];
            if (table != nil) {
                
                [self.outlineView reloadItem:table reloadChildren:YES];
            }
            [self.outlineView endUpdates];
        }
    }
}


- (IBAction)onEditColumn:(id)sender
{
    NSInteger row = [self.outlineView rowForView:sender];
    
    if (row != -1) {
        NSString *str = [sender stringValue];
        id selectedItem = [self.outlineView itemAtRow:row]; // array key, dbtable
        NSLog(@"string change %@, row : %@", str, selectedItem);
        
        if ([selectedItem isKindOfClass:[NSArray class]] ) {
            // parent is an array table, parent key (string)
            NSArray *entry = (NSArray *)selectedItem;
            NSString *key = entry[0];
            DBTable *table = entry[1];
            
            id value = nil;
            NSMutableArray *keyArray = nil;
            NSInteger count = 0;
            
            [self keyHasArrayIndex:key withItems:&keyArray];
            id dictionary = table.detailsDict;
            value = [table.detailsDict objectForKey:keyArray[0]];
            while (++count < [keyArray count]) {
                
                if ([keyArray[count] isKindOfClass:[NSNumber class]]) {
                    if ([value isKindOfClass:[NSArray class]]) {
                        
                        NSArray *array = (NSArray *)value;
                        value = [array objectAtIndex:((NSNumber *)keyArray[count]).intValue];
                    }
                }
                else {
                    dictionary = value;
                    value = [value objectForKey:keyArray[count]];
                }
            }
            
            if ([dictionary isKindOfClass:[NSMutableDictionary class]] ) {
                
                NSString *newStr = nil;
                NSLog(@"Renaming from %@, to %@", keyArray[count - 1], str);
                if ([str length] != 0) {
                    
                    [dictionary removeObjectForKey:keyArray[count - 1]];
                    [dictionary setObject:value forKey:newStr];
                    if (table.mStatus == NOCHANGE) {
                    
                        table.mStatus = EDITED;
                    }
                }
                
                [self.outlineView beginUpdates];
                [self.outlineView reloadItem:table reloadChildren:YES];
                [self.outlineView endUpdates];
                self.mAddBtn.enabled = NO;
            }
        }
    }
}



#pragma mark - NSOutlineView delegate

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
    
    id value = nil;
    
    self.mAddBtn.enabled = NO;  //add key,value
    self.addDateBtn.enabled = NO;
    self.addPhotoBtn.enabled = NO;
    self.addArrayWDictBtn.enabled = NO;
    self.addDictBtn.enabled = NO;
    
    NSOutlineView *outlineView = notification.object;
    id selectedItem = [outlineView itemAtRow:[outlineView selectedRow]];
    if ([selectedItem isKindOfClass:[DBTable class]] ) {
        // table was selected
        if ([selectedItem isKindOfClass:[DBTable class]] ) {
                NSLog(@"Selected Table name:%@", ((DBTable *)selectedItem).name);
        }
    }
    else  {
        if ([selectedItem isKindOfClass:[NSArray class]] ) {
            // parent is an array table, parent key (string)
            NSArray *entry = (NSArray *)selectedItem;
            NSString *key = entry[0];
            DBTable *table = entry[1];
            id container = nil;
            
            value = [self getSelectedValueAndContainer:&container withKey:key fromTable:table];
            NSLog(@"Selected Table:%@, key:%@, value:%@", ((DBTable *)table).name, key, value);
            
        }
        self.mAddBtn.enabled = YES;
        if ([self isIntrinsicTypes:value]) {
            
            self.addDateBtn.enabled = YES;
            self.addPhotoBtn.enabled = YES;
            self.addArrayWDictBtn.enabled = YES;
            self.addDictBtn.enabled = YES;
        }
    }
}

/* View Based OutlineView: See the delegate method -tableView:rowViewForRow: in NSTableView.
 */

/*
- (nullable NSTableRowView *)outlineView:(NSOutlineView *)outlineView rowViewForItem:(id)item {
    
    return nil;
}
 
 */

/* View Based OutlineView: This delegate method can be used to know when a new 'rowView' has been added to the table. At this point, you can choose to add in extra views, or modify any properties on 'rowView'.
 */
/*
- (void)outlineView:(NSOutlineView *)outlineView didAddRowView:(NSTableRowView *)rowView forRow:(NSInteger)row {
    
    
}
 */

/* View Based OutlineView: This delegate method can be used to know when 'rowView' has been removed from the table. The removed 'rowView' may be reused by the table so any additionally inserted views should be removed at this point. A 'row' parameter is included. 'row' will be '-1' for rows that are being deleted from the table and no longer have a valid row, otherwise it will be the valid row that is being removed due to it being moved off screen.
 */

/*
- (void)outlineView:(NSOutlineView *)outlineView didRemoveRowView:(NSTableRowView *)rowView forRow:(NSInteger)row {
    
    
*/

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn
               item:(id)item {
    
    return YES;
}

- (BOOL)isIntrinsicTypes:(id)item {
    
    return ([item isKindOfClass:NSString.class] ||
            [item isKindOfClass:NSNumber.class] ||
            [item isKindOfClass:NSDate.class] ||
            [item isKindOfClass:CBLBlob.class]);
}


- (IBAction)viewImageMenuItemSelected:(id)sender {
    
    NSLog(@"View Image menu item selected");
    id selectedItem = [self.outlineView itemAtRow:[self.outlineView selectedRow]];
    
    self.mAddBtn.enabled = YES;
    //self.mDeleteBtn.enabled = YES;

    id value = nil;
    if ([selectedItem isKindOfClass:[NSArray class]] ) {
        // parent is an array table, parent key (string)
        NSArray *entry = (NSArray *)selectedItem;
        NSString *key = entry[0];
        DBTable *table = entry[1];
        id container = nil;
        
        value = [self getSelectedValueAndContainer:&container withKey:key fromTable:table];
    }
        
    if ([value isKindOfClass:[CBLBlob class]] ) {
        
        NSView *view = [self.outlineView viewAtColumn:1 row:[self.outlineView selectedRow]
                       makeIfNecessary:YES];
        ImageFileViewer *imageFileViewer = [[ImageFileViewer alloc]initWithNibName:nil bundle:nil];
        imageFileViewer.imageToDisplay = value;

        NSPopover *popover = [[NSPopover alloc] init];
        popover.contentViewController = imageFileViewer; // Missing this.
        NSLog(@"Showing popover...");
        [popover showRelativeToRect:[view frame]
                             ofView:view
                      preferredEdge:NSMinYEdge];
    }
}

- (IBAction)addDictBtnPressed:(id)sender {
    
    // get the selection
    BOOL entryAdded = NO;
    id value = nil;
    DBTable *table = nil;
    id selectedItem = [self.outlineView itemAtRow:[self.outlineView selectedRow]];
    NSMutableDictionary *newDict = [[NSMutableDictionary alloc]initWithDictionary:@{newKey : newValue}];
    
    if ([selectedItem isKindOfClass:[NSArray class]] ) {
        // parent is an array table, parent key (string)
        NSArray *entry = (NSArray *)selectedItem;
        NSString *key = entry[0];
        table = entry[1];
        id dictionary = table.detailsDict;
        NSMutableArray *keyArray = nil;
        NSInteger count = 0;
        NSString *theKey = nil;
        
        if (![self keyHasArrayIndex:key withItems:&keyArray])
        {
         
            value = [table.detailsDict valueForKeyPath:key];
            theKey = key;
        }
        else {
            
            value = [table.detailsDict objectForKey:keyArray[0]];
            while (++count < [keyArray count]) {
                
                if ([keyArray[count] isKindOfClass:[NSNumber class]]) {
                    if ([value isKindOfClass:[NSArray class]]) {
                        
                        NSArray *array = (NSArray *)value;
                        value = [array objectAtIndex:((NSNumber *)keyArray[count]).intValue];
                    }
                }
                else {
                    
                    dictionary = value;
                    value = [value objectForKey:keyArray[count]];
                }
            }
            theKey = keyArray[count - 1];
        }
        //
        if ([dictionary isKindOfClass:[NSMutableDictionary class]] ) {
            
            if ([self isIntrinsicTypes:value]) {
                
                [dictionary setValue:newDict forKeyPath:theKey];
                entryAdded = YES;
            }
        }
    }
    
    if (entryAdded) {
        
        if (table.mStatus == NOCHANGE) {
            
            table.mStatus = EDITED;
        }
        // reload table
    
        [self.outlineView beginUpdates];
        [self.outlineView reloadItem:table reloadChildren:YES];
        [self.outlineView endUpdates];
        self.mAddBtn.enabled = NO;
    }
}

- (IBAction)addArrayWDictBtnPressed:(id)sender {
    
    DBTable *table = nil;
    BOOL entryAdded = NO;
    id value = nil;
    id dictionary = nil;
    
    id selectedItem = [self.outlineView itemAtRow:[self.outlineView selectedRow]];
    NSString *dictKey = nil;
    
    if ([selectedItem isKindOfClass:[NSArray class]] ) {
        // parent is an array table, parent key (string)
        NSArray *entry = (NSArray *)selectedItem;
        NSString *key = entry[0];
        table = entry[1];
        dictionary = table.detailsDict;
        
        NSMutableArray *keyArray = nil;
        NSInteger count = 0;
        if (![self keyHasArrayIndex:key withItems:&keyArray])
        {
            dictKey = key;
        }
        else {
            
            value = [table.detailsDict objectForKey:keyArray[0]];
            
            while (++count < [keyArray count]) {
                
                if ([keyArray[count] isKindOfClass:[NSNumber class]]) {
                    if ([value isKindOfClass:[NSArray class]]) {
                        
                        NSArray *array = (NSArray *)value;
                        value = [array objectAtIndex:((NSNumber *)keyArray[count]).intValue];
                    }
                }
                else {
                    dictionary = value;
                    value = [value objectForKey:keyArray[count]];
                }
            }
            dictKey = keyArray[count - 1];
        }
    }
    
    if (([dictionary isKindOfClass:[NSMutableDictionary class]]) &&
            ([dictKey isKindOfClass:[NSString class]])) {
        
        NSMutableArray *newArray = [NSMutableArray new];
        NSMutableDictionary *newDictionary = [[NSMutableDictionary alloc]initWithDictionary:@{newKey : newValue}];
        [newArray addObject:newDictionary];
        [dictionary setValue:newArray forKeyPath:dictKey];
        entryAdded = YES;
    }
    
    if (entryAdded) {
        //[self.outlineView collapseItem:table];
        if (table.mStatus == NOCHANGE) {
            
            [table setMStatus:EDITED];
        }
        // reload table
    
        [self.outlineView beginUpdates];
        [self.outlineView reloadItem:table reloadChildren:YES];
        [self.outlineView endUpdates];
        self.mAddBtn.enabled = NO;
    }
}


- (IBAction)addnewTableBtnPressed:(id)sender {
    
    NSMutableDictionary *mutableDict = [NSMutableDictionary new];
    [mutableDict setObject:newValue forKey:newKey];
    
    DBTable *dbTable = [[DBTable alloc]initWithName:newDocument andDetails:mutableDict];
    [dbTable setIndex:[mDatabaseTables count]]; //before
    NSArray<NSString *> *keys = [mutableDict allKeys];
    dbTable.mStatus = NEW;
    
    [mDatabaseTables addObject:dbTable];
    [mArrayOfKeysArray addObject:keys];
    
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:[mDatabaseTables count] - 1]; //after
    
    [self.outlineView beginUpdates];
    
    [self.outlineView insertItemsAtIndexes:indexSet inParent:nil
                   withAnimation:NSTableViewAnimationEffectNone];
    
    [self.outlineView endUpdates];
    
}


- (IBAction)addPhotoBtnPressed:(id)sender {
    
    [[IKPictureTaker pictureTaker] beginPictureTakerSheetForWindow:self.outlineView.window withDelegate:self didEndSelector:@selector(pictureTakerDidEnd:returnCode:contextInfo:) contextInfo:nil];
}


- (void) pictureTakerDidEnd:(IKPictureTaker *) picker
                 returnCode:(NSInteger) code
                contextInfo:(void*) contextInfo {
    
    NSImage *image = [picker outputImage];
    if (image != nil && (code == NSModalResponseOK)) {
        
        DBTable *table = nil;
        BOOL entryAdded = NO;
        id value = nil;
        id dictionary = nil;
        
        id selectedItem = [self.outlineView itemAtRow:[self.outlineView selectedRow]];
        NSString *dictKey = nil;
        
        if ([selectedItem isKindOfClass:[NSArray class]] ) {
            // parent is an array table, parent key (string)
            NSArray *entry = (NSArray *)selectedItem;
            NSString *key = entry[0];
            table = entry[1];
            dictionary = table.detailsDict;
            
            NSMutableArray *keyArray = nil;
            NSInteger count = 0;
            if (![self keyHasArrayIndex:key withItems:&keyArray])
            {
                value = [table.detailsDict valueForKeyPath:key];
                dictKey = key;
            }
            else {
                
                value = [table.detailsDict objectForKey:keyArray[0]];
                
                while (++count < [keyArray count]) {
                    
                    if ([keyArray[count] isKindOfClass:[NSNumber class]]) {
                        if ([value isKindOfClass:[NSArray class]]) {
                            
                            NSArray *array = (NSArray *)value;
                            value = [array objectAtIndex:((NSNumber *)keyArray[count]).intValue];
                        }
                    }
                    else {
                        dictionary = value;
                        value = [value objectForKey:keyArray[count]];
                    }
                }
                dictKey = keyArray[count - 1];
            }
        }
        
        if (([dictionary isKindOfClass:[NSMutableDictionary class]]) &&
                ([dictKey isKindOfClass:[NSString class]])) {
            
            CGImageRef cgRef = [image CGImageForProposedRect:NULL
                    context:nil hints:nil];
            NSBitmapImageRep *newRep = [[NSBitmapImageRep alloc] initWithCGImage:cgRef];
            [newRep setSize:[image size]];   // if you want the same resolution
            NSNumber *number = [NSNumber numberWithInt:1];
            NSDictionary *dict = @{NSImageCompressionFactor : number};
            NSData *jpegData = [newRep representationUsingType:NSBitmapImageFileTypeJPEG properties:dict];
            CBLBlob *blob = [[CBLBlob alloc] initWithContentType:@"image/jpeg" data:jpegData];
            
            [dictionary setObject:blob forKey:dictKey];
            entryAdded = YES;
        }
        
        if (entryAdded) {
            //[self.outlineView collapseItem:table];
            if (table.mStatus == NOCHANGE) {
                
                [table setMStatus:EDITED];
            }
            // reload table
        
            [self.outlineView beginUpdates];
            [self.outlineView reloadItem:table reloadChildren:YES];
            [self.outlineView endUpdates];
            self.mAddBtn.enabled = NO;
        }
    }
}


// based on what is selected, add a new {key, value} at that level
- (IBAction)addBtnPressed:(id)sender {
    
    // get the selection
    BOOL entryAdded = NO;
    id value = nil;
    DBTable *table = nil;
    id selectedItem = [self.outlineView itemAtRow:[self.outlineView selectedRow]];
    
    if ([selectedItem isKindOfClass:[NSArray class]] ) {
        // parent is an array table, parent key (string)
        NSArray *entry = (NSArray *)selectedItem;
        NSString *key = entry[0];
        table = entry[1];
        id dictionary = nil;
        NSMutableArray *keyArray = nil;
        NSInteger count = 0;
        if (![self keyHasArrayIndex:key withItems:&keyArray])
        {
            
            value = [table.detailsDict valueForKeyPath:key];
            if (value != nil) {
                
                NSMutableString *theKey = [NSMutableString new];
                for (NSInteger index = 0; index < ([keyArray count] - 1); index++) {
                    
                    [theKey appendString:[keyArray objectAtIndex:index]];
                    [theKey appendString:@"."];
                }
                [theKey appendString:newKey];
                [table.detailsDict setValue:newValue forKeyPath:theKey];
                entryAdded = YES;
            }
        }
        else {
            
            value = [table.detailsDict objectForKey:keyArray[0]];
            while (++count < [keyArray count]) {
                
                if ([keyArray[count] isKindOfClass:[NSNumber class]]) {
                    if ([value isKindOfClass:[NSArray class]]) {
                        
                        NSArray *array = (NSArray *)value;
                        value = [array objectAtIndex:((NSNumber *)keyArray[count]).intValue];
                    }
                }
                else {
                    
                    dictionary = value;
                    value = [value objectForKey:keyArray[count]];
                }
            }
        }
        //
        if ([dictionary isKindOfClass:[NSMutableDictionary class]] ) {
            
            [dictionary setObject:newValue forKey:newKey];
            entryAdded = YES;
        }
    }
    
    if (entryAdded) {
        
        if (table.mStatus == NOCHANGE) {
            
            table.mStatus = EDITED;
        }
        // reload table
    
        [self.outlineView beginUpdates];
        [self.outlineView reloadItem:table reloadChildren:YES];
        [self.outlineView endUpdates];
        self.mAddBtn.enabled = NO;
    }
}


- (IBAction)deleteBtnPressed:(id)sender {
    
    id selectedItem = [self.outlineView itemAtRow:[self.outlineView selectedRow]];
    id parent = [self.outlineView parentForItem:selectedItem];
    id value = nil;
    BOOL updated = NO;
    if (parent == nil) {
        // table was selected
        if ([selectedItem isKindOfClass:[DBTable class]] ) {
            
            [self removeTable:((DBTable *)selectedItem)];
        }
    }
    else {
        
        DBTable *table = nil;
        if ([selectedItem isKindOfClass:[NSArray class]] ) {
            // parent is an array table, parent key (string)
            NSArray *entry = (NSArray *)selectedItem;
            NSString *key = entry[0];
            table = entry[1];
            
            NSMutableArray *keyArray = nil;
            NSInteger count = 0;
            id container = nil;
            
            [self keyHasArrayIndex:key withItems:&keyArray];
            value = [table.detailsDict objectForKey:keyArray[0]];
            container = table.detailsDict;
            while (++count < [keyArray count]) {
                
                if ([keyArray[count] isKindOfClass:[NSNumber class]]) {
                    if ([value isKindOfClass:[NSMutableArray class]]) {
                        
                        NSMutableArray *array = (NSMutableArray *)value;
                        container = array;
                        value = [array objectAtIndex:((NSNumber *)keyArray[count]).intValue];
                    }
                }
                else {
                    container = value;
                    value = [value objectForKey:keyArray[count]];
                }
            }
            --count; //decrement the count since it advances past the key array
            if ([container isKindOfClass:[NSMutableDictionary class]] ) {
                
                [container removeObjectForKey:keyArray[count]];
                if ([container count] == 0) {
                    
                    if (count == 1) {
                        // one layer from the top
                        [table.detailsDict removeObjectForKey:keyArray[count - 1]];
                        if ([table.detailsDict count] == 0) {
                            
                            [self removeTable:table];
                        }
                    }
                    else if (count > 1) {
                        
                        
                        
                    }
                }
                updated = YES;
            }
            else if ([container isKindOfClass:[NSMutableArray class]] ) {
                
                [container removeObjectAtIndex:((NSNumber *)keyArray[count]).intValue];
                // for now, make it so if table has one dictionary entry, you delete the table.
                if ([container count] == 0) {
                    
                    if (count == 1) {
                        // one layer from the top
                        [table.detailsDict removeObjectForKey:keyArray[count - 1]];
                        if ([table.detailsDict count] == 0) {
                            
                            [self removeTable:table];
                        }
                    }
                    else if (count > 1) {
               
               
                    }
                }
                updated = YES;
            }
        }
            
        if (updated) {
            //NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:index];
            
            if (table.mStatus == NOCHANGE) {
            
                table.mStatus = EDITED;
            }
            [self.outlineView beginUpdates];
            [self.outlineView reloadItem:table reloadChildren:YES];
            [self.outlineView endUpdates];
            
            self.mAddBtn.enabled = NO;  //add key,value
            self.addDateBtn.enabled = NO;
            self.addPhotoBtn.enabled = NO;
            self.addArrayWDictBtn.enabled = NO;
            self.addDictBtn.enabled = NO;
        }
    }
}


- (IBAction)pasteBtnPressed:(id)sender {
    
    //self.mCopyBtn.enabled = NO;
    if ([copyTable isKindOfClass:[DBTable class]]) {
        // check to see if this works if table is expanded
        
        DBTable *newTable = [[DBTable alloc]initWithTableCopy:copyTable];
        newTable.name = newDocument;
        NSArray<NSString *> *keys = [newTable.detailsDict allKeys];
    
        [newTable setIndex:[mDatabaseTables count]]; //before
        [mDatabaseTables addObject:newTable];
        [mArrayOfKeysArray addObject:keys];
        
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:[mDatabaseTables count] - 1]; //after
        
        [self.outlineView beginUpdates];
        
        [self.outlineView insertItemsAtIndexes:indexSet inParent:nil
                       withAnimation:NSTableViewAnimationEffectNone];
        
        [self.outlineView endUpdates];
    }
    else {
        
        BOOL entryAdded = NO;
        id container = nil;
        id selectedItem = [self.outlineView itemAtRow:[self.outlineView selectedRow]];
        
        if ([selectedItem isKindOfClass:[NSArray class]] ) {
            // parent is an array table, parent key (string)
            NSArray *entry = (NSArray *)selectedItem;
            NSString *key = entry[0];
            DBTable *table = entry[1];

            id value = [self getSelectedValueAndContainer:&container withKey:key fromTable:table];
            id parent = [self.outlineView parentForItem:selectedItem];
            
            if ([copyTable isKindOfClass:[NSArray class]]) {
                
                NSArray *selection = (NSArray *)copyTable;
                id selValue = selection[1];
                     
                if ([value isKindOfClass:[NSMutableDictionary class]]) { //value is selected item
                
                    if ([parent isKindOfClass:[NSArray class]]) { // this is a selection
                        // check this, this is the case where you select the dictionary in the array
                        // key : [==>{key1 : value1}, {key2 : value2}]
                        NSArray *entry = (NSArray *)parent;
                        NSString *selectedKey = entry[0];
                        DBTable *selectedTable = entry[1];
                        
                        // copy value
                        NSMutableArray *arrayItem = [selectedTable.detailsDict objectForKey:selectedKey];
                        NSInteger index = [arrayItem indexOfObject:value];
                        if (index != NSNotFound) {
                            
                            if ([selValue isKindOfClass:[NSDictionary class]]) {
                                NSMutableDictionary *copiedDict = [NSMutableDictionary new];
                                copiedDict = [DBTable deepCopyFromDictionary:selValue toDictionary:copiedDict];
                                [arrayItem insertObject:copiedDict atIndex:index];
                                entryAdded = YES;
                            }
                            else {
                                
                                NSAssert(NO, @"pasteBtnPressed: selected value is not a dictionary: %@", selValue);
                            }
                        }
                        else {
                            
                            NSAssert(NO, @"pasteBtnPressed: index is %lu", index);
                        }
                    }
                }
                else if ([value isKindOfClass:[NSMutableArray class]]) {
                
                   //paste a dictionary to an array of dictionaries
                    id arrayEntry = [((NSMutableArray *)value) objectAtIndex:0];
                    if ([arrayEntry isKindOfClass:[NSDictionary class]]) {
                        // copy and add
                        if ([selValue isKindOfClass:[NSDictionary class]]) {
                            NSMutableDictionary *copiedDict = [NSMutableDictionary new];
                            copiedDict = [DBTable deepCopyFromDictionary:selValue toDictionary:copiedDict];
                            [((NSMutableArray *)value) addObject:copiedDict];
                            entryAdded = YES;
                        }
                        // this is the case where you select the dictionary key of the array
                        //  ==> key : [{key1 : value1}, {key2 : value2}]
                    }
                }
                else if ([container isKindOfClass:[NSMutableDictionary class]]) {
                    // copy key, value to an existing dictionary
                    // this could be an array
                    NSLog(@"Copying key, value to a dictionary");
                    NSArray *entry = (NSArray *)copyTable;
                    // the key could be a number if it's an index
                    
                    NSString *selectedKey = ([entry[0] isKindOfClass:[NSNumber class]]) ? newKey : entry[0];
                    id valueToCopy = entry[1];
                    
                    // key : value selected
                    id copiedValueToCopy = nil;
                    if ([valueToCopy isKindOfClass:[NSDictionary class]]) {
                        
                        copiedValueToCopy = [NSMutableDictionary new];
                        copiedValueToCopy = [DBTable deepCopyFromDictionary:valueToCopy toDictionary:copiedValueToCopy];
                    }
                    else if ([valueToCopy isKindOfClass:[NSArray class]]) {
                        
                        id valueCopied = nil;
                        copiedValueToCopy = [NSMutableArray new];
                        NSArray *array = (NSArray *)valueToCopy;
                        for (id object in array) {
                            
                            if ([object isKindOfClass:[NSDictionary class]]) {
                                
                                valueCopied = [NSMutableDictionary new];
                                valueCopied = [DBTable deepCopyFromDictionary:object toDictionary:valueCopied];
                            }
                            if ([object isKindOfClass:[NSArray class]]) {
                                
                                [NSException raise:@"UnimplementedMethod" format:@"%@ is unimplemented", @"Array of arrays"];
                            }
                            [copiedValueToCopy addObject:valueCopied];
                        }
                    }
                    else {
                        copiedValueToCopy = [valueToCopy copy];
                    }
                    if (copiedValueToCopy != nil) {
                        [((NSMutableDictionary *)container) setObject:copiedValueToCopy forKey:selectedKey];
                        entryAdded = YES;
                    }
                }
            }
            
            if (entryAdded) {
                //[self.outlineView collapseItem:table];
                if (table.mStatus == NOCHANGE) {
                    
                    table.mStatus = EDITED;
                }
                // reload table
            
                [self.outlineView beginUpdates];
                [self.outlineView reloadItem:table reloadChildren:YES];
                [self.outlineView endUpdates];
                self.mAddBtn.enabled = NO;
            }
        }
    }
}


- (IBAction)copyBtnPressed:(id)sender {
    
    id value = nil;
    id selectedItem = [self.outlineView itemAtRow:[self.outlineView selectedRow]];
    id parent = [self.outlineView parentForItem:selectedItem];
    if (parent == nil) {
        // table was selected
        if ([selectedItem isKindOfClass:[DBTable class]] ) {
                NSLog(@"Selected Table name:%@", ((DBTable *)selectedItem).name);
            copyTable = selectedItem;
        }
    }
    else {
        
        if ([selectedItem isKindOfClass:[NSArray class]] ) {
            // parent is an array table, parent key (string)
            NSArray *entry = (NSArray *)selectedItem;
            NSString *key = entry[0];
            DBTable *table = entry[1];
            
            NSMutableArray *keyArray = nil;
            NSInteger count = 0;
            
            [self keyHasArrayIndex:key withItems:&keyArray];
            id dictionary = table.detailsDict;
            value = [table.detailsDict objectForKey:keyArray[0]];
            while (++count < [keyArray count]) {
                
                if ([keyArray[count] isKindOfClass:[NSNumber class]]) {
                    if ([value isKindOfClass:[NSArray class]]) {
                        
                        NSArray *array = (NSArray *)value;
                        dictionary = value;
                        value = [array objectAtIndex:((NSNumber *)keyArray[count]).intValue];
                    }
                }
                else {
                    dictionary = value;
                    value = [value objectForKey:keyArray[count]];
                }
            }
            
            if (value != nil) {
                // copy a dictionary
                //check if key is a index
                copyTable = @[keyArray[count - 1], value];
            }
        }
    }
}

- (NSArray *)isArrayAsString:(NSString *)item {
    
    unichar openBracket = '[';
    unichar closeBracket = ']';
    NSMutableArray* builtArray = [NSMutableArray new];
    
    if (([item characterAtIndex:0] == openBracket) &&
        ([item characterAtIndex:[item length] - 1] == closeBracket)) {
        
        NSRange range = NSMakeRange(1, ([item length] - 2));
        NSString *strWithoutBrackets = [item substringWithRange:range];
        NSArray *strItems = [strWithoutBrackets componentsSeparatedByString:@","];
        if (strItems != nil) {
            // check for dates, ints, floats, etc.
            for (NSString *str in strItems) {
                NSString *newStr = [str stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
                id value = [self isNumberAsString:newStr];
                if (value == nil) {
                    value = [self isDateAsString:newStr];
                }
                if (value == nil) {
                    
                    value = newStr;
                }
                [builtArray addObject:value];
            }
        }
        else {
            
            NSLog(@"Error condition: %@ is not an array", item);
        }
    }
    return builtArray;
}

- (NSDictionary *)isDictionaryAsString:(NSString *)item {
    
    NSArray *strItems;
    unichar openBrace = '{';
    unichar closeBrace = '}';
    NSMutableDictionary* builtDict = [NSMutableDictionary new];
    
    if (([item characterAtIndex:0] == openBrace) &&
        ([item characterAtIndex:[item length] - 1] == closeBrace)) {
        
        NSRange range = NSMakeRange(1, ([item length] - 2));
        NSString *strWithoutBrackets = [item substringWithRange:range];
        strItems = [strWithoutBrackets componentsSeparatedByString:@","];
        if (strItems == nil) {
            // check for dates, ints, floats, etc.
            NSString *newStr = [strWithoutBrackets stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
            NSArray *seperatedItems = [newStr componentsSeparatedByString:@":"];
            if ([seperatedItems count] == 2) { //key, value
                
                [builtDict setObject:[seperatedItems[0] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet]
                    forKey:[seperatedItems[1] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet]];
            }
        }
        else {
            
            for (NSString *str in strItems) {
                
                NSString *newStr = [str stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
                NSArray *seperatedItems = [newStr componentsSeparatedByString:@":"];
                if ([seperatedItems count] == 2) { //key,value
                    
                    [builtDict setObject:[seperatedItems[0] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet]
                        forKey:[seperatedItems[1] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet]];
                }
            }
        }
    }
    return builtDict;
}

- (NSNumber *)isNumberAsString:(NSString *)item {
    
    NSNumberFormatter *numberFormat = [NSNumberFormatter new];
    numberFormat.maximumFractionDigits = 3;
    return [numberFormat numberFromString:item];
}

- (NSDate *)isDateAsString:(NSString *)dateStr {
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = cbLiteDateFormatStr;
    return [dateFormatter dateFromString:dateStr];
}

- (void)updateAfterSaving:(DBTable *)table {
    
    //[self.outlineView collapseItem:table];
    // reload table
    table.mStatus = NOCHANGE;
    [self.outlineView beginUpdates];
    [self.outlineView reloadItem:table reloadChildren:YES];
    [self.outlineView endUpdates];
    self.mAddBtn.enabled = NO;
}

- (IBAction)addDateBtnPressed:(id)sender {
    
    NSView *view = [self.outlineView viewAtColumn:1 row:[self.outlineView selectedRow]
                   makeIfNecessary:YES];
    AddViewDateViewer *addViewDateViewer = [[AddViewDateViewer alloc]initWithNibName:nil bundle:nil];
    addViewDateViewer.delegate = self;
    addViewDateViewer.mValueToDisplay = nil;
    addViewDateViewer.mReadOnly = NO;

    NSPopover *popover = [[NSPopover alloc] init];
    popover.contentViewController = addViewDateViewer;
    NSLog(@"Showing popover...");
    [popover showRelativeToRect:[view frame]
                         ofView:view
                  preferredEdge:NSMinYEdge];
}


- (IBAction)viewDateMenuItemSelected:(id)sender {
    
    id selectedItem = [self.outlineView itemAtRow:[self.outlineView selectedRow]];
    id value = nil;
    if ([selectedItem isKindOfClass:[NSArray class]] ) {
        // parent is an array table, parent key (string)
        NSArray *entry = (NSArray *)selectedItem;
        NSString *key = entry[0];
        DBTable *table = entry[1];
        id container = nil;
        
        value = [self getSelectedValueAndContainer:&container withKey:key fromTable:table];
    }
        
    if (([value isKindOfClass:[NSNumber class]] ) || ([value isKindOfClass:[NSString class]] )) {
            
        if ([value isKindOfClass:[NSString class]] ) {
                
            NSDate *createdDate = [self isDateAsString:value];
            if (createdDate != nil) {
                    
                value = createdDate;
            }
            else {
                    
                NSLog(@"%@ is not a date", value);
                return;
            }
        }
            
        NSView *view = [self.outlineView viewAtColumn:1 row:[self.outlineView selectedRow]
                       makeIfNecessary:YES];
        AddViewDateViewer *addViewDateViewer = [[AddViewDateViewer alloc]initWithNibName:nil bundle:nil];
        addViewDateViewer.delegate = self;
        addViewDateViewer.mValueToDisplay = value;
        addViewDateViewer.mReadOnly = YES;

        NSPopover *popover = [[NSPopover alloc] init];
        popover.contentViewController = addViewDateViewer;
        NSLog(@"Showing popover...");
        [popover showRelativeToRect:[view frame]
                             ofView:view
                      preferredEdge:NSMinYEdge];
    }
}

- (void)didUpdateDate:(nullable id)dateField {
    
    BOOL updated = NO;
    if (dateField != nil) {
        
        DBTable *table = nil;
        id value = nil;
        id selectedItem = [self.outlineView itemAtRow:[self.outlineView selectedRow]];
        if ([selectedItem isKindOfClass:[NSArray class]] ) {
            // parent is an array table, parent key (string)
            NSArray *entry = (NSArray *)selectedItem;
            NSString *key = entry[0];
            table = entry[1];
            id dictionary = nil;
            NSMutableArray *keyArray = nil;
            NSInteger count = 0;
            if (![self keyHasArrayIndex:key withItems:&keyArray])
            {
                
                [table.detailsDict setValue:dateField forKeyPath:key];
                updated = YES;
            }
            else {
                
                value = [table.detailsDict objectForKey:keyArray[0]];
                while (++count < [keyArray count]) {
                    
                    if ([keyArray[count] isKindOfClass:[NSNumber class]]) {
                        if ([value isKindOfClass:[NSArray class]]) {
                            
                            NSArray *array = (NSArray *)value;
                            value = [array objectAtIndex:((NSNumber *)keyArray[count]).intValue];
                        }
                    }
                    else {
                        
                        dictionary = value;
                        value = [value objectForKey:keyArray[count]];
                    }
                }
            }
            //
            if ([dictionary isKindOfClass:[NSMutableDictionary class]] ) {
                
                [dictionary setObject:dateField forKey:keyArray[count - 1]];
                updated = YES;
            }
        }
            
        if (updated) {
            //[self.outlineView collapseItem:table];
            if (table.mStatus == NOCHANGE) {
            
                table.mStatus = EDITED;
            }
            [self.outlineView beginUpdates];
            if (table != nil) {
                
                [self.outlineView reloadItem:table reloadChildren:YES];
            }
            [self.outlineView endUpdates];
        }
    }
}

- (BOOL)validateMenuItem:(NSMenuItem *)item {
    
    id selectedItem = [self.outlineView itemAtRow:[self.outlineView selectedRow]];
    //id parent = [self.outlineView parentForItem:selectedItem];
    
    id value = nil;
    id container = nil;
    
    if ([selectedItem isKindOfClass:[NSArray class]] ) {
        // parent is an array table, parent key (string)
        NSArray *entry = (NSArray *)selectedItem;
        NSString *key = entry[0];
        DBTable *table = entry[1];
        
        NSMutableArray *keyArray = nil;
        NSInteger count = 0;
        
        [self keyHasArrayIndex:key withItems:&keyArray];
        container = table.detailsDict;
        value = [table.detailsDict objectForKey:keyArray[0]];
        while (++count < [keyArray count]) {
            
            if ([keyArray[count] isKindOfClass:[NSNumber class]]) {
                if ([value isKindOfClass:[NSArray class]]) {
                    
                    NSArray *array = (NSArray *)value;
                    container = value;
                    value = [array objectAtIndex:((NSNumber *)keyArray[count]).intValue];
                }
            }
            else {
                container = value;
                value = [value objectForKey:keyArray[count]];
            }
        }
    }
    
    if ([item action] == @selector(copyBtnPressed:)) {
        
        // table was selected
        if ([selectedItem isKindOfClass:[DBTable class]] ) {
            
            return YES;
        }
        else if (value != nil) {
                // copy a dictionary
                return YES;
        }
    }
    
    if ([item action] == @selector(pasteBtnPressed:)) {
        
        if (copyTable != nil) {
            
            if ([selectedItem isKindOfClass:[DBTable class]]) {
                
                if ([copyTable isKindOfClass:[DBTable class]]) {
                 
                    return YES;
                }
            }
            else if (value != nil) {
                
                if ([copyTable isKindOfClass:[NSDictionary class]]) {
                    
                    if ([value isKindOfClass:[NSArray class]]) {
                        
                        id arrayEntry = [((NSArray *)value) objectAtIndex:0];
                        if ([arrayEntry isKindOfClass:[NSDictionary class]]) {
                        
                            return YES;
                        }
                    }
                }
                else if ([copyTable isKindOfClass:[NSArray class]]) {
                    // need to filter further
                    return YES;
                }
            }
        }
    }
    
    if ([item action] == @selector(deleteBtnPressed:)) {
        
        if ([selectedItem isKindOfClass:[DBTable class]] ) {
            
            return YES;
        }
        else if (value != nil) {
        
            return YES;
        }
    }
    
    
    if ([item action] == @selector(viewImageMenuItemSelected:)) {
            
        if ([value isKindOfClass:[CBLBlob class]] ) {
            
            return YES;
        }
    }
    
    if ([item action] == @selector(viewDateMenuItemSelected:)) {
        
        if ([value isKindOfClass:[NSNumber class]] ) {
            
            return YES;
        }
        else if ([value isKindOfClass:[NSString class]] ) {
            
            if ([self isDateAsString:value]) {
            
                return YES;
            }
        }
    }
    return NO;
}

- (id)convertToValueTypeFromString:(NSString *)string {
    
    id newValue = nil;
    
    newValue = [self isArrayAsString:string];
    // this guy always returns an array, whether it's empty of not
    if ([(NSArray *)newValue count] > 0) {
        
        return newValue;
    }
    else {
        newValue = nil;
    }
     
    newValue = [self isDateAsString:string];
    if (newValue != nil) {
        
        return newValue;
    }
    
    newValue = [self isNumberAsString:string];
    if (newValue != nil) {
        
        return newValue;
    }
    return string;
}

- (BOOL)keyHasArrayIndex:(NSString *)key withItems:(NSMutableArray **) separatedItems {
    
    BOOL hasArrayIndex = NO;
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    *separatedItems = [NSMutableArray new];
    
    NSArray *items = [key componentsSeparatedByString:@"."];
    for (NSString *item in items) {
        
        NSNumber *number = [formatter numberFromString:item];
        if (number != nil) {
            
            hasArrayIndex = YES;
            [*separatedItems addObject:number];
        }
        else {
            [*separatedItems addObject:item];
        }
    }
    return hasArrayIndex;
}

- (id)getSelectedValueAndContainer:(id *)container withKey:(NSString *)key fromTable:(DBTable *)table  {
    
    id value = nil;
        
    NSMutableArray *keyArray = nil;
    NSInteger count = 0;
    if (![self keyHasArrayIndex:key withItems:&keyArray])
    {
        *container = table.detailsDict;
        value = [table.detailsDict valueForKeyPath:key];
    }
    else {
        
        value = [table.detailsDict objectForKey:keyArray[0]];
        while (++count < [keyArray count]) {
            
            if ([keyArray[count] isKindOfClass:[NSNumber class]]) {
                if ([value isKindOfClass:[NSArray class]]) {
                    
                    NSMutableArray *array = (NSMutableArray *)value;
                    *container = array;
                    value = [array objectAtIndex:((NSNumber *)keyArray[count]).intValue];
                }
            }
            else {
                NSAssert([value isKindOfClass:[NSMutableDictionary class]],
                         @"value is:  [%@],getSelectedValueAndContainer:withKey:fromTable:", value);
                *container = value;
                value = [value objectForKey:keyArray[count]];
            }
        }
    }
    return value;
}

- (void)removeTable:(DBTable *)table {
    
    NSInteger index = [table getIndex];
    
    [mDeleteTables addObject:table];

    [mDatabaseTables removeObjectAtIndex:index];
    [mArrayOfKeysArray removeObjectAtIndex:index];
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:index];
    [self.outlineView beginUpdates];
    
    [self.outlineView removeItemsAtIndexes:indexSet inParent:nil withAnimation:NSTableViewAnimationEffectNone];
    [self.outlineView endUpdates];
    
    // re-adjust the indexes
    for (NSInteger count = index; count < [mDatabaseTables count]; count++) {
        
        DBTable *table = [mDatabaseTables objectAtIndex:count];
        NSInteger oldIndex = [table getIndex];
        --oldIndex;
        [table setIndex:oldIndex];
    }
    
}

- (BOOL)windowShouldClose:(id)sender {

    if ([self.document isKindOfClass:[Document class]] ) {
        
        if ([self.document respondsToSelector:@selector(checkForTempDatabase)]) {
            
            [self.document checkForTempDatabase];
        }
    }
    return YES;
}

@end


