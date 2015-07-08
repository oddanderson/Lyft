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
@property (nonatomic) IBOutlet UISwitch *loggingSwitch;

@end

static CLGeocoder *Geocoder;

@implementation ViewController

+ (void)initialize {
    Geocoder = [[CLGeocoder alloc] init];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"NavBar"] forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:252/255.0 green:251/255.0 blue:248/255.0 alpha:1]];
    self.array = [[LFTrip allObjects] sortedResultsUsingProperty:@"timestamp" ascending:NO];
    __weak typeof(self) weakSelf = self;
    self.notification = [RLMRealm.defaultRealm addNotificationBlock:^(NSString *note, RLMRealm *realm) {
        [weakSelf.tableView reloadData];
    }];
    self.tableView.tableFooterView = [UIView new];
    [self updateLoggingItem];
}

- (IBAction)toggleLogging:(id)sender {
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
}

- (void)updateLoggingItem {
    BOOL loggingDisabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"loggingDisabled"];
    [self.loggingSwitch setOn:!loggingDisabled];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.array.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *Identifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:Identifier];
    
    LFTrip *trip = self.array[indexPath.row];
    NSString *startAddress = trip.startLocation.address;
    if (!startAddress.length) {
        startAddress = @"calculating";
        [self promiseForLocation:trip.startLocation];
    }
    NSString *endAddress = trip.endLocation.address;
    if (!endAddress.length) {
        endAddress = @"calculating";
        [self promiseForLocation:trip.endLocation];
    }
    UILabel *primeLabel = (id)[cell viewWithTag:2];
    primeLabel.text = [NSString stringWithFormat:@"%@ > %@", startAddress, endAddress];
    NSString *detailText = [NSString stringWithFormat:@"%@ - %@ (%@)",
                            trip.startLocation.displayTime,
                            trip.endLocation.displayTime,
                            trip.tripDuration];
    UILabel *secondLabel = (id)[cell viewWithTag:3];
    secondLabel.font = [UIFont italicSystemFontOfSize:12];
    secondLabel.text = detailText;
    
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
