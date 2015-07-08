//
//  LFTrip.h
//  Lyft
//
//  Created by Todd Anderson on 7/7/15.
//  Copyright (c) 2015 toddanderson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Realm/Realm.h>
@class LFLocation;

@interface LFTrip : RLMObject

@property LFLocation *startLocation;
@property LFLocation *endLocation;

@end

@interface LFTrip (Creation)

+ (void)getTripsFromDisk;

@end
