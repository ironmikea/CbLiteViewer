//
//
//  CBLBlob+copyZone.m
//  vesselSummaryDemo
//
//  Created by Mike Anderson on 6/8/19.
//  Copyright © 2019 Mike Anderson. All rights reserved.
//

#import <Quartz/Quartz.h>

#import "CBLBlob+copyZone.h"


@implementation CBLBlob (copyZone)

- (id)copyWithZone:(struct _NSZone *)zone {
    
    NSImage *image = [NSImage imageNamed:@"image-not-available.png"];
    CGImageRef cgRef = [image CGImageForProposedRect:NULL context:nil hints:nil];
    NSBitmapImageRep *newRep = [[NSBitmapImageRep alloc] initWithCGImage:cgRef];
    [newRep setSize:[image size]];   // if you want the same resolution
    NSNumber *number = [NSNumber numberWithInt:1];
    NSDictionary *dict = @{NSImageCompressionFactor : number};
    NSData *jpegData = [newRep representationUsingType:NSBitmapImageFileTypeJPEG properties:dict];
    return [[CBLBlob alloc] initWithContentType:@"image/jpeg" data:jpegData];
    
    //return [[self class] allocWithZone:zone];
}



@end
