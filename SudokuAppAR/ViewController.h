//
//  ViewController.h
//  SudokuAppAR
//
//  Created by Satej Mhatre on 12/24/15.
//  Copyright © 2015 Satej Mhatre. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <opencv2/opencv.hpp>
#import "UIImage+OpenCV.h"
#import "TesseractOCR.framework/Headers/TesseractOCR.h"
#import <opencv2/videoio/cap_ios.h>

@interface ViewController : UIViewController<UITextViewDelegate,CvVideoCameraDelegate, UITextFieldDelegate, UIImagePickerControllerDelegate,  UINavigationControllerDelegate>
{
    UIImagePickerController *ipc;
}
@property (weak, nonatomic) IBOutlet UIButton *ImageViewButton;
@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, strong, retain) IBOutlet UIImageView *detectedGrid;
@property (nonatomic, strong) IBOutlet UILabel *lab;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *HeightConstraint;


@property (weak, nonatomic) IBOutlet UIView *ContainerView;
@property (weak, nonatomic) IBOutlet UIButton* Solved;
@property (weak, nonatomic) IBOutlet UIButton *StartButton;
- (IBAction)ToggleView:(UIButton *)sender;

@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *TapToStart;
- (IBAction)TapToStartVid:(UITapGestureRecognizer *)sender;
- (IBAction)btnGalleryClicked:(id)sender;
- (IBAction)startProcessing:(UIButton *)sender;
- (IBAction)solve:(id)sender;
@property (weak, nonatomic) IBOutlet UITextView *textField;
-(void)processImage:(cv::Mat&)image;
@end

