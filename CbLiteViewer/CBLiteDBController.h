//
//  CBLiteDBController.h
//  CbLiteViewer
//
//  Created by Mike Anderson on 12/9/20.
//

#import <Cocoa/Cocoa.h>

#import "AddViewDateViewerDelegate.h"

typedef NS_ENUM(unsigned char, tableStatus) {
    
    NOCHANGE,
    EDITED,
    NEW
};


@class CBLDatabase;

@interface DBTable : NSObject {
    
    NSInteger mIndex;
}

@property (nonatomic) NSString *name;
@property (nonatomic) NSMutableDictionary *detailsDict;
@property (nonatomic) tableStatus mStatus;

- (id) initWithName:(NSString *)name andDetails:(NSMutableDictionary*)details;
- (NSInteger)getIndex;
- (void)setIndex:(NSInteger)index;

@end

@interface CBLiteDBController : NSWindowController <NSOutlineViewDataSource, NSOutlineViewDelegate,
    AddViewDateViewerDelegate, NSMenuItemValidation>

- (id)initWithTableData: (NSMutableArray<DBTable *> *)databaseTables withKeys:
    (NSMutableArray<NSArray<NSString *>*>*)arrayOfKeysArray andDeleteArray:(NSMutableArray<DBTable *> *)deleteTables;

@property (weak) NSOutlineView* outlineView;

@property (weak) IBOutlet NSButton *mAddBtn; //add key. value
@property (weak) IBOutlet NSButton *addViewDateBtn;
@property (weak) IBOutlet NSButton *addDateBtn;
@property (weak) IBOutlet NSButton *addPhotoBtn;
@property (weak) IBOutlet NSButton *addArrayWDictBtn;
@property (weak) IBOutlet NSButton *addDictBtn;


- (IBAction)copyBtnPressed:(id)sender;
- (IBAction)pasteBtnPressed:(id)sender;
- (IBAction)deleteBtnPressed:(id)sender;
- (IBAction)addBtnPressed:(id)sender;
- (IBAction)addPhotoBtnPressed:(id)sender;
- (IBAction)addnewTableBtnPressed:(id)sender;
- (IBAction)addDateBtnPressed:(id)sender;
- (IBAction)addArrayWDictBtnPressed:(id)sender;
- (IBAction)addDictBtnPressed:(id)sender;

- (IBAction)viewImageMenuItemSelected:(id)sender;
- (IBAction)viewDateMenuItemSelected:(id)sender;


- (void)updateAfterSaving:(DBTable *)table;




@end

