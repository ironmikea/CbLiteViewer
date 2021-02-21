//
//  newTripFilterViewControllerDelegate.h
//  vesselSummaryDemo
//
//  Created by user on 4/11/19.
//  Copyright © 2019 Mike Anderson. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@protocol AddViewDateViewerDelegate <NSObject>

- (void)didUpdateDate:(nullable id)dateField;

@end
