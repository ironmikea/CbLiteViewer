//
//  ImageFileViewer.h
//  CbLiteViewer
//
//  Created by Mike Anderson on 12/22/20.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class CBLBlob;

@interface ImageFileViewer : NSViewController

@property (weak) IBOutlet NSImageView *imageView;

@property (strong) CBLBlob* imageToDisplay;
- (IBAction)closeBtnPressed:(id)sender;


@end

NS_ASSUME_NONNULL_END
