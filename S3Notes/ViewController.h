//
//  ViewController.h
//  S3Notes
//
//  Created by Wesley Hovanec on 5/18/15.
//  Copyright (c) 2015 Wesley Hovanec. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "S3Manager.h"
#import "SecondViewController.h"


@interface ViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UINavigationControllerDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, strong) S3Manager *manager;
@property (nonatomic, strong) NSArray *bucketItems;
@property (nonatomic, strong) SecondViewController *imageViewController;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutletCollection(UIBarButtonItem) NSArray *navButtons;


@end

