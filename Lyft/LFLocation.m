//
//  LFLocation.m
//  Lyft
//
//  Created by Todd Anderson on 7/7/15.
//  Copyright (c) 2015 toddanderson. All rights reserved.
//

#import "LFLocation.h"
#import <PromiseKit/PromiseKit.h>
#import <CoreLocation/CoreLocation.h>

@implementation LFLocation

static CLGeocoder *Geocoder;
static NSMutableArray *CurrentRequests;
static id queue;

+ (void)initialize {
    Geocoder = [[CLGeocoder alloc] init];
    CurrentRequests = [NSMutableArray array];
    queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
}

+ (NSDictionary *)defaultPropertyValues {
    return @{@"address" : @""};
}

+ (NSArray *)indexedProperties {
    return @[@"timestamp"];
}

- (PMKPromise *)displayAddress {
    if (self.address.length) {
        return [PMKPromise promiseWithValue:self.address];
    }
    CLLocation *location = [[CLLocation alloc] initWithLatitude:self.latitude longitude:self.longitude];
    return [Geocoder reverseGeocode:location].then(^id(CLPlacemark *first, NSArray *allPlacements) {
        RLMRealm *realm = [RLMRealm defaultRealm];
        [realm beginWriteTransaction];
        self.address = first.name;
        [realm commitWriteTransaction];
        return first.name;
    });
}

@end
