//
//  Document.h
//  CbLiteViewer
//
//  Created by Mike Anderson on 12/1/20.
//

#import <Cocoa/Cocoa.h>

@interface Document : NSDocument

- (IBAction)saveDocument:(id)sender;
- (IBAction)closeDocument:(id)sender;
- (IBAction)revertToSaved:(id)sender;
- (IBAction)saveAsDocument:(id)sender;

- (void)checkForTempDatabase;

@end

