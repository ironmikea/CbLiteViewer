//
//  ImageFileViewer.m
//  CbLiteViewer
//
//  Created by Mike Anderson on 12/22/20.
//

#import "ImageFileViewer.h"

#import <CouchbaseLite/CouchbaseLite.h>

@interface ImageFileViewer ()

@end

@implementation ImageFileViewer

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    if (self.imageToDisplay != nil) {
        
        self.imageView.image = [[NSImage alloc]initWithData:self.imageToDisplay.content];
    }
}

- (IBAction)closeBtnPressed:(id)sender {
    
    [self.view.window close];
}


@end
