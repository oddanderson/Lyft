//
//  LFLocation.h
//  Lyft
//
//  Created by Todd Anderson on 7/7/15.
//  Copyright (c) 2015 toddanderson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Realm/Realm.h>
@class PMKPromise;

@interface LFLocation : RLMObject

@property CGFloat longitude;
@property CGFloat latitude;
@property NSDate *timestamp;
@property CGFloat speed;
@property NSString *address;

- (PMKPromise *)displayAddress;

@end
