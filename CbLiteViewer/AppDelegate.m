//
//  AppDelegate.m
//  CbLiteViewer
//
//  Created by Mike Anderson on 12/1/20.
//

#import "AppDelegate.h"
#import <CouchbaseLite/CouchbaseLite.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    
    NSLog(@"Does this fire???");
}

- (BOOL) applicationShouldOpenUntitledFile:(NSApplication *)sender {
    return NO;
}

- (IBAction) showAppBrowser: (id)sender {
    
}

- (IBAction) orderFrontStandardAboutPanel:(id)sender {
    
    //TODO: integrate the cblite library
    //NSString* cblVers = [NSString stringWithFormat: @"Couchbase Lite %@", CBLVersion()];
    NSString* cblVers = [NSString stringWithFormat: @"Couchbase Lite %.1f", 2.5];
    [NSApp orderFrontStandardAboutPanelWithOptions: @{@"Version": cblVers}];
}



@end
