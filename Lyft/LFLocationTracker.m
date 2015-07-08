//
//  LFLocationTracker.m
//  Lyft
//
//  Created by Todd Anderson on 7/7/15.
//  Copyright (c) 2015 toddanderson. All rights reserved.
//

#import "LFLocationTracker.h"
#import "LFLocation.h"
#import <CoreLocation/CoreLocation.h>
#import <CLLocationManager_blocks/CLLocationManager+blocks.h>

@interface LFLocationTracker ()

@property (nonatomic) CLLocationManager *manager;

@end

@implementation LFLocationTracker

+ (instancetype)sharedTracker {
    static LFLocationTracker *sharedTracker = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedTracker = [[self alloc] init];
    });
    return sharedTracker;
}

- (id)init {
    self = [super init];
    if (self) {
        self.manager = [CLLocationManager updateManagerWithAccuracy:50.0
                                                        locationAge:15.0
                                            authorizationDesciption:CLLocationUpdateAuthorizationDescriptionAlways];
        [self.manager allowDeferredLocationUpdatesUntilTraveled:1600 timeout:CLTimeIntervalMax];
        [self.manager didFinishDeferredUpdatesWithErrorWithBlock:^(CLLocationManager *manager, NSError *error) {
            [manager allowDeferredLocationUpdatesUntilTraveled:1600 timeout:CLTimeIntervalMax];
        }];
        self.manager.pausesLocationUpdatesAutomatically = YES;
        self.manager.activityType = CLActivityTypeAutomotiveNavigation;
    }
    return self;
}

- (void)startTracking {
    [self.manager startUpdatingLocationWithUpdateBlock:^(CLLocationManager *manager, CLLocation *location, NSError *error, BOOL *stopUpdating) {
        if (!location) {
            return;
        }
        LFLocation *data = [LFLocation new];
        CLLocationCoordinate2D coordinate = location.coordinate;
        data.latitude = coordinate.latitude;
        data.longitude = coordinate.longitude;
        data.speed = location.speed;
        data.timestamp = location.timestamp;
        NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        NSString *customRealmPath = [documentsDirectory stringByAppendingPathComponent:@"locations.realm"];

        RLMRealm *realm = [RLMRealm realmWithPath:customRealmPath];
        [realm beginWriteTransaction];
        [realm addObject:data];
        [realm commitWriteTransaction];
    }];
}

- (void)stopTracking {
    [self.manager stopUpdatingLocation];
}

@end
