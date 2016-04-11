//
//  SecondViewController.m
//  S3Notes
//
//  Created by Wesley Hovanec on 5/18/15.
//  Copyright (c) 2015 Wesley Hovanec. All rights reserved.
//

#import "SecondViewController.h"

@interface SecondViewController ()

@end

@implementation SecondViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.manager = [S3Manager defaultManager];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadImage) name:@"imageDownloaded" object:nil];
    if (self.imageView.image == nil) {
        [self loadImage];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)loadImage {
    [self.imageView performSelectorOnMainThread:@selector(setImage:) withObject:self.manager.image waitUntilDone:YES];
}

@end
