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

@interface ViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) RLMResults *array;
@property (nonatomic, strong) RLMNotificationToken *notification;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.array = [LFTrip allObjects]; //sortedResultsUsingProperty:@"date" ascending:YES];
    __weak typeof(self) weakSelf = self;
    self.notification = [RLMRealm.defaultRealm addNotificationBlock:^(NSString *note, RLMRealm *realm) {
        [weakSelf.tableView reloadData];
    }];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.array.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Hey"];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:@"Hey"];
    }
    
    LFTrip *trip = self.array[indexPath.row];
    trip.startLocation.displayAddress.then(^(NSString *address) {
        cell.textLabel.text = address;
    });
    trip.endLocation.displayAddress.then(^(NSString *address) {
        cell.detailTextLabel.text = address;
    });
    
    return cell;
}

@end
