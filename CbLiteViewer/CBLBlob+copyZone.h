//
//  CBLBlob+copyZone.h
//  vesselSummaryDemo
//
//  Created by Mike Anderson on 6/8/19.
//  Copyright © 2019 Mike Anderson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CouchbaseLite/CouchbaseLite.h>



@interface CBLBlob (copyZone)

-(id) copyWithZone:(struct _NSZone *)zone;

@end

