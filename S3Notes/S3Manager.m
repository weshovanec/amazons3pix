//
//  S3Manager.m
//  S3Notes
//
//  Created by Wesley Hovanec on 5/18/15.
//  Copyright (c) 2015 Wesley Hovanec. All rights reserved.
//

#import "S3Manager.h"

@implementation S3Manager

static S3Manager *sharedManager = nil;

+(S3Manager *)defaultManager {
    if (sharedManager == nil) {
        sharedManager = [[S3Manager alloc] init];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        sharedManager.path = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"s3photos"];
        BOOL isDir = YES;
        if (![[NSFileManager defaultManager] fileExistsAtPath:sharedManager.path isDirectory:&isDir]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:sharedManager.path withIntermediateDirectories:NO attributes:nil error:nil];
        }
        
    }
    return sharedManager;
}

-(void)refreshBucketObjects {
    listObjectsRequest = [AWSS3ListObjectsRequest new];
    listObjectsRequest.bucket = BUCKET_NAME;
    [[[AWSS3 defaultS3] listObjects:listObjectsRequest] continueWithBlock:^id(BFTask *task) {
        if (task.error) {
            NSLog(@"Could not list objects. %@", task.error.localizedDescription);
        }
        else {
            AWSS3ListObjectsOutput *output = task.result;
            self.bucketItems = output.contents;
            NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:self.path];
            for (NSURL *url in enumerator) {
                for (AWSS3Object *object in self.bucketItems) {
                    if ([object.key isEqualToString:(NSString *)url]) {
                        break;
                    }
                    else if (object == [self.bucketItems lastObject]) {
                        [[NSFileManager defaultManager] removeItemAtPath:[self.path stringByAppendingPathComponent:(NSString *)url] error:nil];
                    }
                }
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:@"bucketObjectsRefreshed" object:nil];
        }
        return nil;
    }];
}

-(void)retrieveImageDataForImageNamed:(NSString *)name {
    NSString *tempPath = [self.path stringByAppendingPathComponent:name];
    if ([[NSFileManager defaultManager] fileExistsAtPath:tempPath]) {
        self.image = [UIImage imageWithContentsOfFile:tempPath];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"imageDownloaded" object:nil];
    }
    else {
        NSString *downloadingFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"downloadedImage.png"];
        NSURL *downloadingFileURL = [NSURL fileURLWithPath:downloadingFilePath];
        AWSS3TransferManagerDownloadRequest *downloadRequest = [AWSS3TransferManagerDownloadRequest new];
        downloadRequest.bucket = BUCKET_NAME;
        downloadRequest.key = name;
        downloadRequest.downloadingFileURL = downloadingFileURL;
        [[[AWSS3TransferManager defaultS3TransferManager] download:downloadRequest] continueWithBlock:^id(BFTask *task) {
            if (task.error) {
                NSLog(@"Could not download. %@", task.error);
            }
            else {
                NSData *imageData = [NSData dataWithContentsOfURL:downloadRequest.downloadingFileURL];
                [[NSFileManager defaultManager] createFileAtPath:tempPath contents:imageData attributes:nil];
                self.image = [UIImage imageWithData:imageData];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"imageDownloaded" object:nil];
            }
            return nil;
        }];
    }
}

-(void)deleteImageWithName:(NSString *)name {
    AWSS3DeleteObjectRequest *deleteRequest = [AWSS3DeleteObjectRequest new];
    deleteRequest.bucket = BUCKET_NAME;
    deleteRequest.key = name;
    [[[AWSS3 defaultS3] deleteObject:deleteRequest] continueWithBlock:^id(BFTask *task) {
        if (task.error) {
            NSLog(@"Could not delete object. %@", task.error);
        }
        else {
            AWSS3DeleteObjectOutput *output = task.result;
            if (output != nil) {
                NSString *tempPath = [self.path stringByAppendingPathComponent:name];
                [[NSFileManager defaultManager] removeItemAtPath:tempPath error:nil];
                [self refreshBucketObjects];
            }
        }
        return nil;
    }];
}

-(void)saveImageData:(NSData *)imageData withName:(NSString *)name {
    NSURL *temp = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
    NSURL *imageDataURL = [temp URLByAppendingPathComponent:@"image"];
    [imageData writeToURL:imageDataURL atomically:YES];
    AWSS3TransferManagerUploadRequest *uploadRequest = [AWSS3TransferManagerUploadRequest new];
    uploadRequest.bucket = BUCKET_NAME;
    uploadRequest.key = name;
    uploadRequest.contentType = @"image/png";
    uploadRequest.body = imageDataURL;
    [[[AWSS3TransferManager defaultS3TransferManager] upload:uploadRequest] continueWithBlock:^id(BFTask *task) {
        NSString *tempPath = [self.path stringByAppendingPathComponent:name];
        [[NSFileManager defaultManager] createFileAtPath:tempPath contents:imageData attributes:nil];
        [self refreshBucketObjects];
        return nil;
    }];
}

@end
