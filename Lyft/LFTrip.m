//
//  LFTrip.m
//  Lyft
//
//  Created by Todd Anderson on 7/7/15.
//  Copyright (c) 2015 toddanderson. All rights reserved.
//

#import "LFTrip.h"
#import "LFLocation.h"
#import <PromiseKit/PromiseKit.h>
#import <CoreLocation/CoreLocation.h>

#define kMinimumSpeedThreshold 4.4704 //10mph = 4.4704 meters/sec
#define kMaximumSpeedForStoppage 0.25 // .25 meters per second is small enough to say stopped
#define kSecondsRequiredForStoppage 60 //60 seconds of stillness = user stopped moving

static CLGeocoder *Geocoder;

@implementation LFTrip

+ (void)initialize {
    Geocoder = [[CLGeocoder alloc] init];
}

- (NSDate *)endTime {
    return self.endLocation.timestamp;
}

- (NSString *)tripDuration {
    NSTimeInterval diff = [self.endLocation.timestamp timeIntervalSinceDate:self.startLocation.timestamp];
    NSInteger total = diff;
    NSInteger hours = total / 3600;
    NSInteger minutes = (total / 60) % 60;
    NSInteger seconds = total % 60;
    if (hours > 0) {
        return [NSString stringWithFormat:@"%ld hr, %ld min, %ld sec", (long)hours, (long)minutes, (long)seconds];
    } else {
        return [NSString stringWithFormat:@"%ld min, %ld sec", (long)minutes, (long)seconds];
    }
}

@end

@implementation LFTrip (Creation)

+ (void)getTripsFromDisk {
    dispatch_queue_t q = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_async(q, ^{
        @autoreleasepool {
            NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
            NSString *customRealmPath = [documentsDirectory stringByAppendingPathComponent:@"locations.realm"];
            
            RLMRealm *locRealm = [RLMRealm realmWithPath:customRealmPath];
            RLMResults *results = [[LFLocation allObjectsInRealm:locRealm] sortedResultsUsingProperty:@"timestamp" ascending:YES];
            
            LFTrip *currentTrip;
            NSMutableArray *newTrips = [NSMutableArray array];
            NSMutableArray *stillLocations;
            NSMutableArray *locationsToDelete = [NSMutableArray array];
            NSMutableArray *locationsQueuedForDeletion = [NSMutableArray array];
            [locRealm beginWriteTransaction];
            for (LFLocation *location in results) {
                [locationsToDelete addObject:location];
                if (!currentTrip && location.speed > kMinimumSpeedThreshold) {
                    currentTrip = [LFTrip new];
                    currentTrip.startLocation = [[LFLocation alloc] initWithValue:location];
                    stillLocations = [NSMutableArray array];
                    
                } else if (currentTrip) {
                    if (location.speed > kMaximumSpeedForStoppage) {
                        [stillLocations removeAllObjects];
                    } else {
                        [stillLocations addObject:location];
                        BOOL hasStopped = [self userHasStopped:stillLocations];
                        if (hasStopped) {
                            currentTrip.endLocation = [[LFLocation alloc] initWithValue:location];
                            currentTrip.timestamp = currentTrip.endLocation.timestamp;
                            [newTrips addObject:currentTrip];
                            currentTrip = nil;
                            [locationsQueuedForDeletion addObjectsFromArray:locationsToDelete];
                            [locationsToDelete removeAllObjects];
                        }
                    }
                }
            }
            [locRealm deleteObjects:locationsQueuedForDeletion];
            [locRealm commitWriteTransaction];
            RLMRealm *realm = [RLMRealm defaultRealm];
            [realm beginWriteTransaction];
            [realm addObjects:newTrips];
            [realm commitWriteTransaction];
        }
    });
}

+ (BOOL)userHasStopped:(NSMutableArray *)locations {
    LFLocation *firstStoppage = [locations firstObject];
    LFLocation *lastStoppage = [locations lastObject];
    NSTimeInterval diff = [lastStoppage.timestamp timeIntervalSinceDate:firstStoppage.timestamp];
    return (diff > kSecondsRequiredForStoppage);
}

@end
