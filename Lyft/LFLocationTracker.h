//
//  LFLocationTracker.h
//  Lyft
//
//  Created by Todd Anderson on 7/7/15.
//  Copyright (c) 2015 toddanderson. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LFLocationTracker : NSObject

+ (instancetype)sharedTracker;

- (void)startTracking;
- (void)stopTracking;

@end
