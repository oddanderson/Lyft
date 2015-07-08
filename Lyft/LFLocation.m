//
//  LFLocation.m
//  Lyft
//
//  Created by Todd Anderson on 7/7/15.
//  Copyright (c) 2015 toddanderson. All rights reserved.
//

#import "LFLocation.h"

@implementation LFLocation

static NSDateFormatter *Formatter;

+ (void)initialize {
    Formatter = [NSDateFormatter new];
    [Formatter setDateStyle:NSDateFormatterNoStyle];
    [Formatter setTimeStyle:NSDateFormatterShortStyle];
}

+ (NSDictionary *)defaultPropertyValues {
    return @{@"address" : @""};
}

+ (NSArray *)indexedProperties {
    return @[@"timestamp"];
}

- (NSString *)displayTime {
    return [Formatter stringFromDate:self.timestamp];
}

@end
