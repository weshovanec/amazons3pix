//
//  ViewController.m
//  S3Notes
//
//  Created by Wesley Hovanec on 5/18/15.
//  Copyright (c) 2015 Wesley Hovanec. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItems = [self.navButtons sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"tag" ascending:YES]]];
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(refresh) name:@"bucketObjectsRefreshed" object:nil];
    self.manager = [S3Manager defaultManager];
    [self.manager refreshBucketObjects];
}

-(void)viewWillAppear:(BOOL)animated {
    [self.manager refreshBucketObjects];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)refresh {
    self.bucketItems = self.manager.bucketItems;
    [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
}

- (IBAction)edit:(id)sender {
    [self.tableView setEditing:![self.tableView isEditing]];
    if ([self.tableView isEditing]) {
        [sender setTitle:@"Done"];
    }
    else {
        [sender setTitle:@"Edit"];
    }
}

- (IBAction)add:(id)sender {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIActionSheet *photoActionSheet = [[UIActionSheet alloc] initWithTitle:@"Add Photo" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Take Photo", @"Select from Gallery", nil];
        [photoActionSheet showInView:self.view];
    }
    else {
        UIActionSheet *photoActionSheet = [[UIActionSheet alloc] initWithTitle:@"Add Photo" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Select from Gallery", nil];
        [photoActionSheet showInView:self.view];
    }
}

#pragma mark ActionSheetDelegate

-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    imagePicker.allowsEditing = YES;
    if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Take Photo"]) {
        imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    }
    else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Select from Gallery"]) {
        imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    [self presentViewController:imagePicker animated:YES completion:nil];
}

#pragma mark ImagePickerControllerDelegate

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIAlertController *nameAlert = [UIAlertController alertControllerWithTitle:@"Photo Selected" message:@"Please name the selected photo" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [picker dismissViewControllerAnimated:YES completion:nil];
        if (self.bucketItems.count == 0) {
            [self.manager saveImageData:UIImagePNGRepresentation([info objectForKey:UIImagePickerControllerEditedImage]) withName:[[nameAlert.textFields objectAtIndex:0] text]];
        }
        for (AWSS3Object *object in self.bucketItems) {
            if ([object.key isEqualToString:[[nameAlert.textFields objectAtIndex:0] text]]) {
                UIAlertController *usedNameAlert = [UIAlertController alertControllerWithTitle:@"Name Already Used" message:@"Please choose an unused name." preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil];
                [usedNameAlert addAction:cancelAction];
                [self presentViewController:usedNameAlert animated:YES completion:nil];
                break;
            }
            else if ([self.bucketItems indexOfObject:object] == self.bucketItems.count - 1) {
                [self.manager saveImageData:UIImagePNGRepresentation([info objectForKey:UIImagePickerControllerEditedImage]) withName:[[nameAlert.textFields objectAtIndex:0] text]];
            }
        }
    }];
    [nameAlert addTextFieldWithConfigurationHandler:nil];
    [nameAlert addAction:okAction];
    [picker presentViewController:nameAlert animated:YES completion:nil];
}

#pragma mark TableViewDataSource

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.bucketItems.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if(!cell){
        cell =
        [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    cell.textLabel.text = [NSString stringWithFormat:@"%@", [[self.bucketItems objectAtIndex:indexPath.row] key]];
    return cell;
}

#pragma mark TableViewDelegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.manager retrieveImageDataForImageNamed:[[self.bucketItems objectAtIndex:indexPath.row] key]];
    [self performSegueWithIdentifier:@"picSegue" sender:self];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.manager deleteImageWithName:[[self.bucketItems objectAtIndex:indexPath.row] key]];
    }
}

@end
