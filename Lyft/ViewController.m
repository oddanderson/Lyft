//
//  ViewController.m
//  Lyft
//
//  Created by Todd Anderson on 7/7/15.
//  Copyright (c) 2015 toddanderson. All rights reserved.
//

#import "ViewController.h"
#import <Realm/Realm.h>
#import "LFTrip.h"
#import "LFLocation.h"
#import <CoreLocation/CoreLocation.h>
#import <PromiseKit/PromiseKit.h>
#import "LFLocationTracker.h"

@interface ViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) RLMResults *array;
@property (nonatomic, strong) RLMNotificationToken *notification;
@property (nonatomic) UIBarButtonItem *trackingItem;

@end

static CLGeocoder *Geocoder;

@implementation ViewController

+ (void)initialize {
    Geocoder = [[CLGeocoder alloc] init];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.array = [[LFTrip allObjects] sortedResultsUsingProperty:@"timestamp" ascending:YES];
    __weak typeof(self) weakSelf = self;
    self.notification = [RLMRealm.defaultRealm addNotificationBlock:^(NSString *note, RLMRealm *realm) {
        [weakSelf.tableView reloadData];
    }];
    self.tableView.tableFooterView = [UIView new];
    self.trackingItem = [[UIBarButtonItem alloc] initWithTitle:@"Logging Enabled" style:UIBarButtonItemStylePlain target:self action:@selector(toggleLogging)];
    self.navigationItem.rightBarButtonItem = self.trackingItem;
    [self updateLoggingItem];
}

- (void)toggleLogging {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL loggingDisabled = [defaults boolForKey:@"loggingDisabled"];
    loggingDisabled = !loggingDisabled;
    [defaults setBool:loggingDisabled forKey:@"loggingDisabled"];
    [defaults synchronize];
    if (loggingDisabled) {
        [[LFLocationTracker sharedTracker] stopTracking];
    } else {
        [[LFLocationTracker sharedTracker] startTracking];
    }
    [self updateLoggingItem];
}

- (void)updateLoggingItem {
    BOOL loggingDisabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"loggingDisabled"];
    self.trackingItem.title = loggingDisabled ? @"Logging Disabled" : @"Logging Enabled";
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.array.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *Identifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:Identifier];
    
    LFTrip *trip = self.array[indexPath.row];
    NSString *startAddress = trip.startLocation.address;
    if (!startAddress.length) {
        [self promiseForLocation:trip.startLocation];
    }
    NSString *endAddress = trip.endLocation.address;
    if (!endAddress.length) {
        [self promiseForLocation:trip.endLocation];
    }
    cell.textLabel.text = [NSString stringWithFormat:@"%@ > %@", startAddress, endAddress];
    NSString *detailText = [NSString stringWithFormat:@"%@ - %@ (%@)",
                            trip.startLocation.displayTime,
                            trip.endLocation.displayTime,
                            trip.tripDuration];
    cell.detailTextLabel.text = detailText;
    
    return cell;
}

- (PMKPromise *)promiseForLocation:(LFLocation *)location {
    NSString *uniqueId = location.uniqueId;
    CLLocation *clLocation = [[CLLocation alloc] initWithLatitude:location.latitude longitude:location.longitude];
    return [Geocoder reverseGeocode:clLocation].thenInBackground(^(CLPlacemark *first, NSArray *allPlacements) {
        RLMRealm *realm = [RLMRealm defaultRealm];
        [realm beginWriteTransaction];
        RLMResults *results = [LFLocation objectsWhere:@"uniqueId = %@", uniqueId];
        LFLocation *newLocation = [results firstObject];
        newLocation.address = first.name;
        [realm commitWriteTransaction];
        return first.name;
    });
}

@end
