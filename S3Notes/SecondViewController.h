//
//  SecondViewController.h
//  S3Notes
//
//  Created by Wesley Hovanec on 5/18/15.
//  Copyright (c) 2015 Wesley Hovanec. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "S3Manager.h"

@interface SecondViewController : UIViewController

@property (nonatomic, strong) S3Manager *manager;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end
