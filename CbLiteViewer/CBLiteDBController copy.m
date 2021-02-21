//
//  CBLiteDBController.m
//  CbLiteViewer
//
//  Created by Mike Anderson on 12/9/20.
//

#import "CBLiteDBController.h"

#import "ImageFileViewer.h"
#import "AddViewDateViewer.h"
#import "AppDelegate.h"


#import <CouchbaseLite/CouchbaseLite.h>
#import <Quartz/Quartz.h>

@class CBLBlob;

static NSString *newDocument = @"New Document";

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
    if (self)
    {
        self.name = newDocument;
        self.detailsDict = [[NSMutableDictionary alloc]initWithDictionary:table.detailsDict];
        self.mStatus = NOCHANGE;
    }
    return self;
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
    
    copyTable = nil;
    
    NSWindow *window = self.window;
    NSView *contentView = window.contentView;
    NSScrollView *scrollView = contentView.subviews[0];
    NSView *nextView = scrollView.contentView;
    self.outlineView = nextView.subviews[0];

    self.outlineView.delegate = self;
    self.outlineView.dataSource = self;
    //self.outlineView.doubleAction
    
}




#pragma mark - NSOutlineView datasource

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(nullable id)item {
    
    if (item == nil) {
       return [mDatabaseTables count];  // return number of tables
    }
    else if ([item isKindOfClass:[DBTable class]]) {
        
        DBTable *table = (DBTable *)item;
        return [[table.detailsDict allKeys] count];
    }
    else if ([item isKindOfClass:[NSArray class]]) { // for each key, return the number of items
        
        NSArray *array = (NSArray *)item;
        NSString *key = array[0];
        DBTable *table = array[1];
        id value = [table.detailsDict objectForKey:key];
        
        if (value != nil) {
            
            if ([value isKindOfClass:[NSDictionary class]]) {
                
                return [(NSDictionary *)value count];
            }
            else if ([value isKindOfClass:[NSArray class]]) {
                id subValue = [(NSArray *)value objectAtIndex:0];
                if ([subValue isKindOfClass:[NSDictionary class]]) {
                    
                    return [(NSArray *)value count];
                }
            }
        }
        
    }
    else if ([item isKindOfClass:[NSDictionary class]]) { // this is the 4th level
        
        NSDictionary *dictionary = (NSDictionary *)item;
        NSArray* keys = [dictionary allKeys];
        id value = [dictionary objectForKey:keys[0]];
        if ([value isKindOfClass:[NSDictionary class]]) {
            return [(NSDictionary *)value count];
        }
        
    }
    
    return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(nullable id)item {
    
    if (item == nil) { // each table
        return mDatabaseTables[index];
    }
    else if ([item isKindOfClass:[DBTable class]]) { // level 2
        
        DBTable *table = (DBTable *)item;
        NSArray *keys = [table.detailsDict allKeys];
        //return keys[index];
        return [NSArray arrayWithObjects:keys[index], table, nil];
    }
    else if ([item isKindOfClass:[NSArray class]]) { // level 3
        
        NSArray *array = (NSArray *)item;
        NSString *key = array[0];
        DBTable *table = array[1];
        id value = [table.detailsDict objectForKey:key];
        if (value != nil) {
            
            if ([value isKindOfClass:[NSDictionary class]]) {
                
                NSArray *keys = [(NSDictionary *)value allKeys];
                NSString *objValue = [(NSDictionary *)value objectForKey:keys[index]];
                return @{keys[index] : objValue};
            }
            else if ([value isKindOfClass:[NSArray class]]) {
                
                id subValue = [(NSArray *)value objectAtIndex:index];
                if ([subValue isKindOfClass:[NSDictionary class]]) {
                    
                    NSDictionary *dict = ((NSArray *)value)[index];
                    // fabricating a key at this point
                    NSString *key = [NSString stringWithFormat:@"%@ %lu", itemStr, index + 1];
                    return @{key : dict};
                }
            }
        }
    }
    else if ([item isKindOfClass:[NSDictionary class]]) { // this is the 4th level
        
        NSDictionary *dictionary = (NSDictionary *)item;
        NSArray* keys = [dictionary allKeys];
        id value = [dictionary objectForKey:keys[0]];
        if ([value isKindOfClass:[NSDictionary class]]) {
            NSDictionary *valueDict = (NSDictionary *)value;
            NSArray* nextKeys = [valueDict allKeys];
            id objValue = [valueDict objectForKey:nextKeys[index]];
            return @{nextKeys[index] : objValue};
        }
        else if ([value isKindOfClass:[NSArray class]]) {
            //
            id subValue = [(NSArray *)value objectAtIndex:index];
            if ([subValue isKindOfClass:[NSDictionary class]]) {
                
                NSDictionary *dict = ((NSArray *)value)[index];
                // fabricating a key at this point
                NSString *key = [NSString stringWithFormat:@"%@ %lu", itemStr, index + 1];
                return @{key : dict};
            }
        }
        
    }
    return nil;
}


- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    
    if ([item isKindOfClass:[DBTable class]]) {
        
        return YES;
    }
    
    if ([item isKindOfClass:[NSArray class]]) {
        
        NSArray *array = (NSArray *)item;
        NSString *key = array[0];
        DBTable *table = array[1];
        id value = [table.detailsDict objectForKey:key];
        if (value != nil) {
        
            if ([value isKindOfClass:[NSDictionary class]]) {
            
                return YES;
            }
            else if ([value isKindOfClass:[NSArray class]]) {
                id subValue = [(NSArray *)value objectAtIndex:0];
                if ([subValue isKindOfClass:[NSDictionary class]]) {
                
                    return YES;
                }
            }
        }
    }
    else if ([item isKindOfClass:[NSDictionary class]]) { // this is the 4th level
        // another level check
        NSDictionary *dictionary = (NSDictionary *)item;
        NSArray *keys = [dictionary allKeys];
        id value = [dictionary objectForKey:keys[0]];
        if (([value isKindOfClass:[NSDictionary class]]) ||
            ([value isKindOfClass:[NSArray class]])) {
            return YES;
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
            
            if ([item isKindOfClass:[NSString class]]) {
                
                // the item is actually the key
                cell.textField.editable = YES;
                [cell.textField setTarget:self];
                [cell.textField setAction:@selector(onEditRow:)];
                
                text = item;
                
                // doesn't get executed
            }
            if ([item isKindOfClass:[NSArray class]]) {
                
                NSArray *array = (NSArray *)item;
                text = array[0];
                //cell.textField.editable = NO;
                [cell.textField setTarget:self];
                [cell.textField setAction:@selector(onEditColumn:)];
            }
            else if ([item isKindOfClass:[DBTable class]]) {
                
                DBTable *table = (DBTable *)item;
                text = table.name;
                cell.textField.editable = NO;
            }
            else if ([item isKindOfClass:[NSDictionary class]]) {
                NSDictionary *dict = (NSDictionary *)item;
                NSArray *keys = [dict allKeys];
                text = keys[0];
            }
        }
        else if ([columnIdentifier isEqualToString:@"valueColumn"]) {
            
            cell = [outlineView makeViewWithIdentifier:@"ValueColumnCell" owner:self];
            
            if ([item isKindOfClass:[NSArray class]]) {
                
                NSArray *array = (NSArray *)item;
                NSString *key = array[0];
                DBTable *table = array[1];
                id value = [table.detailsDict objectForKey:key];
                if ([value isKindOfClass:[NSString class]]) {
                    
                    cell.textField.editable = YES;
                    [cell.textField setTarget:self];
                    [cell.textField setAction:@selector(onEditRow:)];
                    text = value;
                }
                else if ([value isKindOfClass:[NSDate class]]) {
                    
                    NSDateFormatter *dateFormatter = [NSDateFormatter new];
                    NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
                    [dateFormatter setLocale:usLocale];
                    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
                    
                    text = [dateFormatter stringFromDate:(NSDate *)value];
                }
                else if ([value isKindOfClass:[NSNumber class]]) {
                    
                    cell.textField.editable = YES;
                    [cell.textField setTarget:self];
                    [cell.textField setAction:@selector(onEditRow:)];
                    text = [(NSNumber *)value stringValue];
                    
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
                    }
                }
                else if ([value isKindOfClass:[NSDictionary class]]) {
                    
                    text = [NSString stringWithFormat:@"%lu items", (unsigned long)[value count]];
                }
            }
            else if ([item isKindOfClass:[NSDictionary class]]) {
                NSDictionary *dict = (NSDictionary *)item;
                
                NSArray *keys = [dict allKeys];
                id value = [dict objectForKey:keys[0]];
                if ([value isKindOfClass:[NSString class]]) {
                    
                    text = (NSString *)value;
                    cell.textField.editable = YES;
                    [cell.textField setTarget:self];
                    [cell.textField setAction:@selector(onEditRow:)];
                }
                else if ([value isKindOfClass:[NSNumber class]]) {
                    
                    if (strcmp([value objCType], @encode(double)) == 0) {
                        
                        NSNumberFormatter *formatter = [NSNumberFormatter new];
                        formatter.maximumFractionDigits = 5;
                        text = [formatter stringFromNumber:value];
                    }
                    else {
                        text = [(NSNumber *)value stringValue];
                    }
                    cell.textField.editable = YES;
                    [cell.textField setTarget:self];
                    [cell.textField setAction:@selector(onEditRow:)];
                }
                else if ([value isKindOfClass:[NSDictionary class]]) {
                    text = [NSString stringWithFormat:@"%lu items", (unsigned long)[value count]];
                    /*
                    NSMutableString *str = [NSMutableString new];
                    [str appendString:@"{"];
                    NSEnumerator *enumerator = [value keyEnumerator];
                    id key;
                        
                    while ((key = [enumerator nextObject])) {
                        
                        // check for different types
                        id objValue = [value valueForKey:key];
                        if ([objValue isKindOfClass:[NSNumber class]]) {
                            
                            if (strcmp([objValue objCType], @encode(double)) == 0) {
                            
                                NSNumberFormatter *formatter = [NSNumberFormatter new];
                                formatter.maximumFractionDigits = 5;
                                objValue = [formatter stringFromNumber:objValue];
                            }
                        }
                        NSString *combineStr = [NSString stringWithFormat:@"%@ : %@", key, objValue];
                        [str appendString:combineStr];
                        [str appendString:@", "];
                    }
                    // minus the last ", "
                    [str setString:[str substringWithRange: NSMakeRange(0, ([str length] - 2))]];
                    [str appendString:@"}"];
                    text = str;
                    */
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
    if (row != -1) {
        DBTable *table = nil;
        NSString *str = [sender stringValue];  //sender NSTextField
        id selectedItem = [self.outlineView itemAtRow:row]; // array key, dbtable
        id parent = [self.outlineView parentForItem:selectedItem];
        NSLog(@"string change %@, row : %@", str, selectedItem);
        
        if ([parent isKindOfClass:[DBTable class]] ) {
            // one level below the table
            id value = nil;
            NSArray *array = (NSArray *)selectedItem;
            NSString *key = array[0];
            table = array[1];
            value = [table.detailsDict objectForKey:key];
            value = [self convertToValueTypeFromString:str];
            
            NSMutableDictionary *mutableDict = ((DBTable *)table).detailsDict;
            [mutableDict setObject:value forKey:key];
            table.mStatus = EDITED;
            updated = YES;
        }
        else {
        
            if ([parent isKindOfClass:[NSArray class]]) {
                
                id value = nil;
                // two levels below the table
                NSArray *array = (NSArray *)parent;
                NSString *key = array[0];
                table = array[1];
                value = [table.detailsDict objectForKey:key];
                if ([value isKindOfClass:[NSMutableDictionary class]]) {
                    
                    if ([selectedItem isKindOfClass:[NSDictionary class]]) {
                    
                        NSArray *allKeys = [(NSDictionary *)selectedItem allKeys];
                        id newValue = [self convertToValueTypeFromString:str];
                        NSMutableDictionary *mutableDict = [[NSMutableDictionary alloc]initWithDictionary:value];
                        [mutableDict setValue:newValue forKey:allKeys[0]];
                        [table.detailsDict setObject:mutableDict forKey:key];
                        table.mStatus = EDITED;
                        updated = YES;
                    }
                }
            }
            else if ([parent isKindOfClass:[NSDictionary class]]) {
                // change to selected item
                
                NSString *firstLKey = nil;
                
                NSArray *keys = [((NSDictionary *)parent) allKeys];
                //NSArray *values = [((NSDictionary *)parent) allKeys];
                
                NSNumber *numberIndex = nil;
                NSRange range = NSMakeRange(0, [itemStr length]);
                NSString *string = [keys[0] substringWithRange:range];
                if ([string isEqualToString:itemStr]) {
                    NSNumberFormatter *numberFormat = [NSNumberFormatter new];
                    NSString *numberStr = [keys[0] substringFromIndex:([itemStr length] + 1)]; //skip space
                    numberIndex = [numberFormat numberFromString:numberStr];
                    
                    id grandParent = [self.outlineView parentForItem:parent];
                    if ([grandParent isKindOfClass:[NSArray class]]) {
                        
                        NSArray *array = (NSArray *)grandParent;
                        NSString *key = array[0];
                        table = array[1];
                        id nextValue = [table.detailsDict objectForKey:key];
                        if ([nextValue isKindOfClass:[NSArray class]] ) {
                            NSArray *entries = (NSArray *)nextValue;
                            if ([entries count] > (numberIndex.intValue - 1)) {
                                    
                                NSMutableArray *mutableArray = [[NSMutableArray alloc]initWithArray:(NSArray *)entries];
                                
                                id nextValue = [mutableArray objectAtIndex:(numberIndex.intValue - 1)];
                                if ([nextValue isKindOfClass:[NSDictionary class]]) {
                                    NSArray *allKeys = [(NSDictionary *)selectedItem allKeys];
                                    id newValue = [self convertToValueTypeFromString:str];
                                    NSMutableDictionary *mutableDict = [[NSMutableDictionary alloc]initWithDictionary:nextValue];
                                    [mutableDict setValue:newValue forKey:allKeys[0]];
                                    [mutableArray setObject:mutableDict atIndexedSubscript:(numberIndex.intValue - 1)];
                                    
                                    [table.detailsDict setObject:mutableArray forKey:key];
                                    updated = YES;
                                }
                            }
                        }
                    }
                }
            }
        }
        
        if (updated) {
            
            [self.outlineView collapseItem:table];
            [self.outlineView beginUpdates];
            if (table != nil) {
                [self.outlineView reloadItem:table];
            }
            [self.outlineView endUpdates];
        }
    }
}

//TODO: fix for multiple levels
- (IBAction)onEditColumn:(id)sender
{
    id value;
    NSInteger row = [self.outlineView rowForView:sender];
    
    
    if (row != -1) {
        NSString *str = [sender stringValue];
        id selectedItem = [self.outlineView itemAtRow:row]; // array key, dbtable
        NSLog(@"string change %@, row : %@", str, selectedItem);
        
        if ([selectedItem isKindOfClass:[NSArray class]]) {
            
            id table = ((NSArray *)selectedItem)[1];
            if ([table isKindOfClass:[DBTable class]]) {
                
                NSMutableDictionary *mutableDict = ((DBTable *)table).detailsDict;
                value = [mutableDict objectForKey:((NSArray *)selectedItem)[0]];
                [mutableDict removeObjectForKey:((NSArray *)selectedItem)[0]];
                [mutableDict setObject:value forKey:str];
                ((DBTable *)table).mStatus = EDITED;
            }
        }
    }
}



#pragma mark - NSOutlineView delegate

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
    
    //self.mCopyBtn.enabled = NO;
    //self.mDeleteBtn.enabled = NO;
    
    NSOutlineView *outlineView = notification.object;
    id selectedItem = [outlineView itemAtRow:[outlineView selectedRow]];
    id parent = [outlineView parentForItem:selectedItem];
    if (parent == nil) {
        // table was selected
        if ([selectedItem isKindOfClass:[DBTable class]] ) {
                NSLog(@"Selected Table name:%@", ((DBTable *)selectedItem).name);
            
            self.mAddBtn.enabled = NO;  //add key,value
            self.addDateBtn.enabled = NO;
        }
    }
    else if ([parent isKindOfClass:[DBTable class]] ) {
        // one level from the table
        NSArray *array = (NSArray *)selectedItem;
        NSString *key = array[0];
        DBTable *table = array[1];
        id value = [table.detailsDict objectForKey:key];
        if (value != nil) {
            NSLog(@"Selected Table:%@, key:%@, value:%@", ((DBTable *)parent).name, key, value);
        }
        self.mAddBtn.enabled = YES;
        self.addDateBtn.enabled = NO;
        //self.mDeleteBtn.enabled = YES;
        
    }
    else if ([parent isKindOfClass:[NSArray class]] ) {
        // parent is an array table, parent key (string)
        NSArray *entry = (NSArray *)parent;
        NSString *key = entry[0];
        DBTable *table = entry[1];
        NSLog(@"Selected Table:%@, parent key:%@, value:%@", ((DBTable *)table).name, key, selectedItem);
        
        // since I can't paste a dictionary {key : value}, I need to check the value
        if ([entry[0] isKindOfClass:[NSString class]] ) {
            
            id value = [table.detailsDict objectForKey:entry[0]];
            if ([value isKindOfClass:[NSArray class]] ) {
                
                self.mAddBtn.enabled = NO;
                self.addDateBtn.enabled = NO;
                //self.mCopyBtn.enabled = YES;
            }
            else if ([value isKindOfClass:[NSDictionary class]] ) {
                
                //self.mCopyBtn.enabled = NO;
                self.mAddBtn.enabled = YES;
                self.addDateBtn.enabled = NO;
            }
            //self.mDeleteBtn.enabled = YES;
        }
        
    }
    else if ([parent isKindOfClass:[NSDictionary class]] ) {
        // second level, parent is a dictionary key, value
        DBTable *table = nil;
        NSDictionary *entry = (NSDictionary *)parent;
        NSArray *keys = [entry allKeys];
        id nextParent = [outlineView parentForItem:parent];
        NSMutableArray *parrentArray = [NSMutableArray new];
        while (![nextParent isKindOfClass:[DBTable class]]) {
            
            id theParent = [self.outlineView parentForItem:nextParent];
            if ([theParent isKindOfClass:[DBTable class]] ) {
                
                table = (DBTable *)theParent;
            }
            else {
                [parrentArray addObject:theParent];
            }
            nextParent = theParent;
        }
        
        NSLog(@"Selected Table:%@, parent %@, selected item:%@", (table != nil ? table.name : @"nil"), keys[0], selectedItem);
        self.mAddBtn.enabled = YES;
        self.addDateBtn.enabled = NO;
        //self.mDeleteBtn.enabled = YES;
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
    id parent = [self.outlineView parentForItem:selectedItem];
    
    if ([parent isKindOfClass:[DBTable class]] ) {
        // one level from the table
        NSArray *array = (NSArray *)selectedItem;
        NSString *key = array[0];
        DBTable *table = array[1];
        id value = [table.detailsDict objectForKey:key];
        if (value != nil) {
            NSLog(@"Selected Table:%@, key:%@, value:%@", ((DBTable *)parent).name, key, value);
        }
        self.mAddBtn.enabled = YES;
        //self.mDeleteBtn.enabled = YES;
        
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
}


- (IBAction)addnewTableBtnPressed:(id)sender {
    
    NSMutableDictionary *mutableDict = [NSMutableDictionary new];
    [mutableDict setObject:newKey forKey:newValue];
    
    DBTable *dbTable = [[DBTable alloc]initWithName:newDocument andDetails:mutableDict];
    [dbTable setIndex:[mDatabaseTables count]]; //before
    NSArray<NSString *> *keys = [mutableDict allKeys];
    
    [mDatabaseTables addObject:dbTable];
    [mArrayOfKeysArray addObject:keys];
    
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:[mDatabaseTables count] - 1]; //after
    
    [self.outlineView beginUpdates];
    
    [self.outlineView insertItemsAtIndexes:indexSet
                        inParent:nil
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
        
        DBTable *dbTable = nil;
        BOOL entryAdded = NO;
        
        id selectedItem = [self.outlineView itemAtRow:[self.outlineView selectedRow]];
        id parent = [self.outlineView parentForItem:selectedItem];
        // level 1
        if ([selectedItem isKindOfClass:[NSArray class]]) {
            NSArray *entries = (NSArray *)selectedItem;
                
            if ([entries[1] isKindOfClass:[DBTable class]]) {
                    
                dbTable = (DBTable *)entries[1];
                if ([entries[0] isKindOfClass:[NSString class]]) {
                    //id value = [dbTable.detailsDict objectForKey:entries[0]];
                    CGImageRef cgRef = [image CGImageForProposedRect:NULL
                            context:nil hints:nil];
                    NSBitmapImageRep *newRep = [[NSBitmapImageRep alloc] initWithCGImage:cgRef];
                    [newRep setSize:[image size]];   // if you want the same resolution
                    NSNumber *number = [NSNumber numberWithInt:1];
                    NSDictionary *dict = @{NSImageCompressionFactor : number};
                    NSData *jpegData = [newRep representationUsingType:NSBitmapImageFileTypeJPEG properties:dict];
                    CBLBlob *blob = [[CBLBlob alloc] initWithContentType:@"image/jpeg" data:jpegData];
                    DBTable *dbTable = (DBTable *)parent;
                    [dbTable.detailsDict setObject:blob forKey:entries[0]];
                    entryAdded = YES;
                }
            }
        }
        if (entryAdded) {
            [self.outlineView collapseItem:dbTable];
            [dbTable setMStatus:EDITED];
            // reload table
        
            [self.outlineView beginUpdates];
            [self.outlineView reloadItem:dbTable];
            [self.outlineView endUpdates];
            self.mAddBtn.enabled = NO;
        }
    }
}


// based on what is selected, add a new {key, value} at that level
- (IBAction)addBtnPressed:(id)sender {
    
    // get the selection
    DBTable *dbTable = nil;
    BOOL entryAdded = NO;
    
    id selectedItem = [self.outlineView itemAtRow:[self.outlineView selectedRow]];
    id parent = [self.outlineView parentForItem:selectedItem];
    
    // level 1  [key, table]
    if ([selectedItem isKindOfClass:[NSArray class]]) {
        NSArray *entries = (NSArray *)selectedItem;
        
        if ([entries[1] isKindOfClass:[DBTable class]]) {
            
            dbTable = (DBTable *)entries[1];
            if ([self isIntrinsicTypes:entries[0]]) {
                id value = [dbTable.detailsDict objectForKey:entries[0]];
                if ([self isIntrinsicTypes:value]) {
                    
                    DBTable *dbTable = (DBTable *)parent;
                
                    [dbTable.detailsDict setObject:newValue forKey:newKey];
                    entryAdded = YES;
                }
            }
        }
    }
    else if ([selectedItem isKindOfClass:[NSDictionary class]] ) {
        // item to add is a dictionary {key : value}
        //{item %d : dictionary]
        id parent = [self.outlineView parentForItem:selectedItem];
        
        // adding a dictionary and parent is a dictionary
        if ([parent isKindOfClass:[NSDictionary class]]) {
            // make the dictionary mutable and add the new key
            NSMutableDictionary *mutableParentDict = [[NSMutableDictionary alloc]initWithDictionary:parent];
            NSArray *parentKeys = [mutableParentDict allKeys];
            
            id value = [mutableParentDict objectForKey:parentKeys[0]];
            if ([value isKindOfClass:[NSDictionary class]]) {
                
                NSMutableDictionary *mutableDict = [[NSMutableDictionary alloc]initWithDictionary:value];
                [mutableDict setObject:newKey forKey:newValue];
                [mutableParentDict setObject:mutableDict forKey:parentKeys[0]];
            }
            
            id nextParent = [self.outlineView parentForItem:parent];
            if ([nextParent isKindOfClass:[NSArray class]] ) {
                
                // next level of the parent is an array
                // extract the number from the fabricated string key
                NSNumber *numberIndex = nil;
                NSRange range = NSMakeRange(0, [itemStr length]);
                NSString *string = [parentKeys[0] substringWithRange:range];
                if ([string isEqualToString:itemStr]) {
                    NSNumberFormatter *numberFormat = [NSNumberFormatter new];
                    NSString *numberStr = [parentKeys[0] substringFromIndex:([itemStr length] + 1)]; //skip space
                    numberIndex = [numberFormat numberFromString:numberStr];
                }
                // [NSString, DBTable]
                NSString *dictKey = ((NSArray *)nextParent)[0];
                dbTable = ((NSArray *)nextParent)[1];
                id nextValue = [dbTable.detailsDict objectForKey:dictKey];
                if ([nextValue isKindOfClass:[NSArray class]] ) {
                    NSArray *entries = (NSArray *)nextValue;
                    if ([entries count] > (numberIndex.intValue - 1)) {
                            
                        NSMutableArray *mutableArray = [[NSMutableArray alloc]initWithArray:(NSArray *)entries];
                        [mutableArray setObject:[mutableParentDict objectForKey:parentKeys[0]] atIndexedSubscript:(numberIndex.intValue - 1)];
                        [dbTable.detailsDict setObject:mutableArray forKey:dictKey];
                        entryAdded = YES;
                    }
                }
            }
        }
        else if ([parent isKindOfClass:[NSArray class]]) {
            //[NSString, DBTable]
            NSArray *entries = (NSArray *)parent;
            NSString *keyEntry = entries[0];
            DBTable *tableEntry = entries[1];
            id nextParent = [self.outlineView parentForItem:parent];
            if (nextParent == tableEntry) { // one level down
                
                id value = [tableEntry.detailsDict objectForKey:keyEntry];
                if ([value isKindOfClass:[NSDictionary class]]) {
                    
                    NSMutableDictionary *mutableDict = [[NSMutableDictionary alloc]initWithDictionary:value];
                    [mutableDict setObject:newKey forKey:newValue];
                    [tableEntry.detailsDict setObject:mutableDict forKey:keyEntry];
                    entryAdded = YES;
                }
            }
        }
    }
    if (entryAdded) {
        [self.outlineView collapseItem:dbTable];
        [dbTable setMStatus:EDITED];
        // reload table
    
        [self.outlineView beginUpdates];
        [self.outlineView reloadItem:dbTable];
        [self.outlineView endUpdates];
        self.mAddBtn.enabled = NO;
    }
}


// TODO: fix for multiple levels works for the 1st level
- (IBAction)deleteBtnPressed:(id)sender {
    
    id selectedItem = [self.outlineView itemAtRow:[self.outlineView selectedRow]];
    id parent = [self.outlineView parentForItem:selectedItem];
    if (parent == nil) {
        // table was selected
        if ([selectedItem isKindOfClass:[DBTable class]] ) {
            
            NSInteger index = [((DBTable *)selectedItem) getIndex];
            
            [mDeleteTables addObject:(DBTable *)selectedItem];
        
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
    }
    else {
        
        if ([parent isKindOfClass:[DBTable class]] ) {
            // one level from the table
            NSInteger index = [self.outlineView selectedRow];
            NSArray *array = (NSArray *)selectedItem;
            NSString *key = array[0];
            DBTable *table = array[1];
            
            [table.detailsDict removeObjectForKey:key];
            table.mStatus = EDITED;
                
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:index - 1];
            [self.outlineView beginUpdates];
            [self.outlineView removeItemsAtIndexes:indexSet inParent:parent withAnimation:NSTableViewAnimationEffectNone];
            [self.outlineView endUpdates];
        }
    }
}

- (IBAction)pasteBtnPressed:(id)sender {
    
    //self.mCopyBtn.enabled = NO;
    if ([copyTable isKindOfClass:[DBTable class]]) {
        // check to see if this works if table is expanded
        
        DBTable *newTable = (DBTable *)copyTable;
        newTable.mStatus = NEW;
        NSArray<NSString *> *keys = [newTable.detailsDict allKeys];
    
        [copyTable setIndex:[mDatabaseTables count]]; //before
        [mDatabaseTables addObject:copyTable];
        [mArrayOfKeysArray addObject:keys];
        
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:[mDatabaseTables count] - 1]; //after
        
        [self.outlineView beginUpdates];
        
        [self.outlineView insertItemsAtIndexes:indexSet
                            inParent:nil
                       withAnimation:NSTableViewAnimationEffectNone];
        
        
        [self.outlineView endUpdates];
    }
    else {
        //array
        BOOL tableUpdated = NO;
        id tableValue = nil;
        if ([copyTable isKindOfClass:[NSArray class]]) {
            
            NSArray *dictKeyAndTable = nil;  //first level key and table
            NSArray *itemsArray = (NSArray *)copyTable;
            NSInteger length = [itemsArray count];
            id itemToPaste = itemsArray[0];
            id itemTable = itemsArray[length - 1]; // last entry in the array
            
            if ([itemTable isKindOfClass:[NSArray class]]) {
                
                dictKeyAndTable = (NSArray *)itemTable;
                NSString *dictKey = dictKeyAndTable[0];
                tableValue = dictKeyAndTable[1];
                if ([tableValue isKindOfClass:[DBTable class]]) {
                    
                    id value = nil;
                    id valueEntry = [((DBTable *)tableValue).detailsDict objectForKey:dictKey];
                        
                    if ([valueEntry isKindOfClass:[NSArray class]]) {
                        
                        NSMutableArray *mutableArray = [[NSMutableArray alloc]initWithArray:(NSArray *)valueEntry];
                        if ([itemToPaste isKindOfClass:[NSDictionary class]]) {
                            // we want the value
                            NSArray *keys = [((NSDictionary *)itemToPaste) allKeys];
                            value = [((NSDictionary *)itemToPaste) objectForKey:keys[0]];
                        }
                        if (value != nil) {
                            [mutableArray addObject:value];
                            [((DBTable *)tableValue).detailsDict setObject:mutableArray forKey:dictKey];
                            tableUpdated = YES;
                        }
                    }
                }
            }
            
            if (tableUpdated) {
                [self.outlineView collapseItem:itemTable];
                
                if (((DBTable *)tableValue).mStatus == NOCHANGE) {
                    
                    ((DBTable *)tableValue).mStatus = EDITED;
                }
                // reload table
                // find the table in the array
                
                [self.outlineView beginUpdates];
                [self.outlineView reloadItem:itemTable];
                [self.outlineView endUpdates];
            }
        }
    }
}

// table == level 0, 1st sub key is level 1, 2nd sub key is level 2, 3rd sub key is level 3
- (IBAction)copyBtnPressed:(id)sender {
    
    id selectedItem = [self.outlineView itemAtRow:[self.outlineView selectedRow]];
    id parent = [self.outlineView parentForItem:selectedItem];
    if (parent == nil) {
        // table was selected
        if ([selectedItem isKindOfClass:[DBTable class]] ) {
                NSLog(@"Selected Table name:%@", ((DBTable *)selectedItem).name);
            copyTable = [[DBTable alloc]initWithTableCopy:selectedItem];
            //self.mPasteBtn.enabled = YES;
        }
    }
    else {
        
        // add the selected item
        // no first level, key and table
        // iterate until you find the table
        id nextParent;
        
        NSMutableArray *parentChildArray = [NSMutableArray new];
        [parentChildArray addObject:selectedItem];
        if ([parent isKindOfClass:[NSArray class]] ) { // 2nd level item selected
        
            [parentChildArray addObject:parent];
            copyTable = parentChildArray;
            //self.mPasteBtn.enabled = YES;
        }
        else if ([parent isKindOfClass:[NSDictionary class]] ) {
        
            NSDictionary *parentDict = (NSDictionary *)parent;
            NSArray<NSString *> *keys = [parentDict allKeys];
            NSRange range = NSMakeRange(0, [itemStr length]);
            NSString *string = [keys[0] substringWithRange:range];
            if ([string isEqualToString:itemStr]) {
                NSNumberFormatter *numberFormat = [NSNumberFormatter new];
                NSString *numberStr = [keys[0] substringFromIndex:([itemStr length] + 1)]; //skip space
                NSNumber *numberIndex = [numberFormat numberFromString:numberStr];
                [parentChildArray addObject:numberIndex];
            }
            while (YES) {
                
                nextParent = [self.outlineView parentForItem:parent];
                if ([nextParent isKindOfClass:[DBTable class]]) {
                    
                    break;
                }
                [parentChildArray addObject:nextParent];
                parent = nextParent;
            }
            copyTable = parentChildArray;
            //self.mPasteBtn.enabled = YES;
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
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm.ss.SSSZ";
    return [dateFormatter dateFromString:dateStr];
}

- (void)updateAfterSaving:(DBTable *)table {
    
    [self.outlineView collapseItem:table];
    // reload table

    [self.outlineView beginUpdates];
    [self.outlineView reloadItem:table];
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
    id parent = [self.outlineView parentForItem:selectedItem];
    
    id value = nil;
    if ([parent isKindOfClass:[DBTable class]] ) {
        // one level from the table
        NSArray *array = (NSArray *)selectedItem;
        NSString *key = array[0];
        DBTable *table = array[1];
        value = [table.detailsDict objectForKey:key];
    }
    else if ([selectedItem isKindOfClass:[NSDictionary class]] ) {
        
        NSArray *allValues = [(NSDictionary *)selectedItem allValues];
        value = allValues[0];
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
    
    
}

- (BOOL)validateMenuItem:(NSMenuItem *)item {
    
    id selectedItem = [self.outlineView itemAtRow:[self.outlineView selectedRow]];
    id parent = [self.outlineView parentForItem:selectedItem];
    
    id value = nil;
    id selectedValue = nil;
    
    if ([parent isKindOfClass:[DBTable class]] ) {
        // one level below the table
        NSArray *array = (NSArray *)selectedItem;
        NSString *key = array[0];
        DBTable *table = array[1];
        value = [table.detailsDict objectForKey:key];
    }
    else if ([parent isKindOfClass:[NSArray class]]) {
        
        // two levels below the table
        NSArray *array = (NSArray *)parent;
        NSString *key = array[0];
        DBTable *table = array[1];
        value = [table.detailsDict objectForKey:key];
    }
    else if ([parent isKindOfClass:[NSDictionary class]]) {
        
        // three levels below the table
        // level 3: dictionary item {key : value}, parent fake key, value = dictionary
        NSDictionary *dict = (NSDictionary *)parent;
        NSArray *keys = [dict allKeys];
    }
    
    if ([selectedItem isKindOfClass:[NSDictionary class]] ) {
        
        NSArray *allValues = [(NSDictionary *)selectedItem allValues];
        selectedValue = allValues[0];
    }
    
    if ([item action] == @selector(copyBtnPressed:)) {
        
        // table was selected
        if ([selectedItem isKindOfClass:[DBTable class]] ) {
            
            return YES;
        }
        else if ([selectedItem isKindOfClass:[NSDictionary class]] ) {
            //
            if ([value isKindOfClass:[NSArray class]] ) {
                // copy an array item
                return YES;
            }
        }
    }
    if ([item action] == @selector(pasteBtnPressed:)) {
        
        if (copyTable != nil) {
         
            return YES;
        }
    }
    
    if ([item action] == @selector(deleteBtnPressed:)) {
        
        if ([selectedItem isKindOfClass:[DBTable class]] ) {
            
            return YES;
        }
    }
    
    
    if ([item action] == @selector(viewImageMenuItemSelected:)) {
            
        if ([selectedValue isKindOfClass:[CBLBlob class]] ) {
            
            return YES;
        }
    }
    
    if ([item action] == @selector(viewDateMenuItemSelected:)) {
        
        if ([selectedValue isKindOfClass:[NSNumber class]] ) {
            
            return YES;
        }
        if ([value isKindOfClass:[NSNumber class]] ) {
            
            return YES;
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




@end


