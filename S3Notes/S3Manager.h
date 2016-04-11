//
//  S3Manager.h
//  S3Notes
//
//  Created by Wesley Hovanec on 5/18/15.
//  Copyright (c) 2015 Wesley Hovanec. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AWSS3/AWSS3.h>

#define BUCKET_NAME @"wesho"

@interface S3Manager : NSObject
{
    AWSS3TransferManager *transferManager;
    AWSS3ListObjectsRequest *listObjectsRequest;
}

@property (nonatomic, strong) NSArray *bucketItems;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSString *path;

-(void)refreshBucketObjects;
-(void)retrieveImageDataForImageNamed:(NSString *)name;
-(void)deleteImageWithName:(NSString *)name;
-(void)saveImageData:(NSData *)imageData withName:(NSString *)name;

+(S3Manager *)defaultManager;

@end
