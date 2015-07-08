//
//  LFTrip.m
//  Lyft
//
//  Created by Todd Anderson on 7/7/15.
//  Copyright (c) 2015 toddanderson. All rights reserved.
//

#import "LFTrip.h"
#import "LFLocation.h"

#define kMinimumSpeedThreshold 4.4704 //10mph = 4.4704 meters/sec
#define kMaximumSpeedForStoppage 0.25 // .25 meters per second is small enough to say stopped
#define kSecondsRequiredForStoppage 60 //60 seconds of stillness = user stopped moving

@implementation LFTrip

@end

@implementation LFTrip (Creation)

+ (void)getTripsFromDisk {
    @autoreleasepool {
        NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        NSString *customRealmPath = [documentsDirectory stringByAppendingPathComponent:@"locations.realm"];
        RLMRealm *locationsRealm = [RLMRealm realmWithPath:customRealmPath];
        RLMResults *results = [[LFLocation allObjectsInRealm:locationsRealm] sortedResultsUsingProperty:@"timestamp" ascending:YES];
        
        RLMRealm *tripRealm = [RLMRealm defaultRealm];
        
        LFTrip *currentTrip;
        NSMutableArray *newTrips = [NSMutableArray array];
        NSMutableArray *stillLocations;
        
        for (LFLocation *location in results) {
            if (currentTrip) {
                if (location.speed > kMaximumSpeedForStoppage) {
                    [stillLocations removeAllObjects];
                } else {
                    [stillLocations addObject:location];
                    BOOL hasStopped = [self userHasStopped:stillLocations];
                    if (hasStopped) {
                        currentTrip.endLocation = [[LFLocation alloc] initWithValue:location];
                        [newTrips addObject:currentTrip];
                        currentTrip = nil;
                    }
                }
                
            } else if (location.speed > kMinimumSpeedThreshold) {
                currentTrip = [LFTrip new];
                currentTrip.startLocation = [[LFLocation alloc] initWithValue:location];
                stillLocations = [NSMutableArray array];
            }
        }
        [tripRealm beginWriteTransaction];
        [tripRealm addObjects:newTrips];
        [tripRealm commitWriteTransaction];
        
        [locationsRealm beginWriteTransaction];
        [locationsRealm deleteObjects:results];
        [locationsRealm commitWriteTransaction];
    }
}

+ (BOOL)userHasStopped:(NSMutableArray *)locations {
    LFLocation *firstStoppage = [locations firstObject];
    LFLocation *lastStoppage = [locations lastObject];
    NSTimeInterval diff = [lastStoppage.timestamp timeIntervalSinceDate:firstStoppage.timestamp];
    return (diff > kSecondsRequiredForStoppage);
}

@end
