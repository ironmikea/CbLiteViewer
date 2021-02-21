//
//  AddViewDateViewer.h
//  CbLiteViewer
//
//  Created by Mike Anderson on 12/26/20.
//

#import <Cocoa/Cocoa.h>

#import "AddViewDateViewerDelegate.h"


@interface AddViewDateViewer : NSViewController <NSDatePickerCellDelegate>

@property (weak) IBOutlet NSDatePicker *mDateTimePicker;
@property (weak) IBOutlet NSTextField *mTimestampLabel;

@property (weak) IBOutlet NSButton *mSaveAsTimeStampBtn;
@property (weak) IBOutlet NSButton *mSaveBtn;
@property (weak) IBOutlet NSButton *mCloseBtn;

- (IBAction)datePickerAction:(id)sender;
- (IBAction)saveBtnPressed:(id)sender;
- (IBAction)closeBtnPressed:(id)sender;
@property (nonatomic) id <AddViewDateViewerDelegate> delegate;

@property (nonatomic) id mValueToDisplay;
@property (nonatomic) BOOL mReadOnly;

@end

