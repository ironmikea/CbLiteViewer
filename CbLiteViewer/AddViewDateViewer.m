//
//  AddViewDateViewer.m
//  CbLiteViewer
//
//  Created by Mike Anderson on 12/26/20.
//

#import "AddViewDateViewer.h"

@interface AddViewDateViewer ()

@end

@implementation AddViewDateViewer

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    if (self.mReadOnly == YES) {
        
        self.mSaveBtn.hidden = YES;
    }
    if (self.mValueToDisplay != nil) {
        
        if ([self.mValueToDisplay isKindOfClass:[NSDate class]]) {
            
            self.mDateTimePicker.dateValue = self.mValueToDisplay;
            self.mTimestampLabel.stringValue =
                [NSString stringWithFormat:@"%.3f", [self.mValueToDisplay timeIntervalSince1970]];
            [self.mSaveAsTimeStampBtn setState:NSControlStateValueOff];
            
        }
        else if ([self.mValueToDisplay isKindOfClass:[NSNumber class]]) {
            
            NSString *dateFormat = @"MM-dd-yy hh:mm aa";
            self.mDateTimePicker.dateValue =
                [self utcTimestampToLocalTime:((NSNumber *)self.mValueToDisplay).doubleValue withFormat:dateFormat];
            self.mTimestampLabel.stringValue =
                [NSString stringWithFormat:@"%.3f", ((NSNumber *)self.mValueToDisplay).doubleValue];
        }
    }
    else {
        
        NSDate *date = [[NSDate alloc]init];
        self.mDateTimePicker.dateValue = date;
        NSTimeInterval timestamp = [date timeIntervalSince1970];
        self.mTimestampLabel.stringValue = [NSString stringWithFormat:@"%.3f", timestamp];
    }
}

- (IBAction)saveBtnPressed:(id)sender {
    
    id value = self.mDateTimePicker.dateValue;
    if (self.mSaveAsTimeStampBtn.state == NSControlStateValueOn) {
        
        value = [NSNumber numberWithDouble:[value timeIntervalSince1970]];
    }
    [self.delegate didUpdateDate:value];
    [self.view.window close];
}

- (IBAction)datePickerAction:(id)sender {
    
    NSDatePicker *datePicker = (NSDatePicker *)sender;
    NSDate *date = datePicker.dateValue;
    self.mTimestampLabel.stringValue = [NSString stringWithFormat:@"%.3f", [date timeIntervalSince1970]];
}
- (IBAction)closeBtnPressed:(id)sender {
    
    [self.view.window close];
}


- (NSDate*)utcTimestampToLocalTime:(NSTimeInterval)seconds withFormat:(NSString *)format
{
    
    NSDate* dateInUTC = [NSDate dateWithTimeIntervalSince1970:seconds];
    NSInteger offsetSeconds = [[NSTimeZone systemTimeZone] secondsFromGMT];
    
    if (![[NSTimeZone systemTimeZone] isDaylightSavingTimeForDate:dateInUTC]) {
        NSTimeInterval daylightOffset = [NSTimeZone systemTimeZone].daylightSavingTimeOffset;
        offsetSeconds -= daylightOffset;
    }
    
    // format it and send
    NSDateFormatter *localDateFormatter = [[NSDateFormatter alloc] init];
    [localDateFormatter setDateFormat:format];
    [localDateFormatter setTimeZone :[NSTimeZone timeZoneForSecondsFromGMT:offsetSeconds]];

    // formatted string
    NSString *localDate = [localDateFormatter stringFromDate: dateInUTC];
    return [localDateFormatter dateFromString:localDate];;
}


- (void)datePickerCell:(NSDatePickerCell *)datePickerCell
validateProposedDateValue:(NSDate * _Nonnull *)proposedDateValue
          timeInterval:(NSTimeInterval *)proposedTimeInterval {
    
    self.mTimestampLabel.stringValue =
        [NSString stringWithFormat:@"%f.5", [*proposedDateValue timeIntervalSince1970]];
}

@end
