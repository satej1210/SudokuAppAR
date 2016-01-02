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
@interface ViewController : UIViewController<CvVideoCameraDelegate>

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, strong, retain) IBOutlet UIImageView *detectedGrid;
@property (nonatomic, strong) IBOutlet UILabel *lab;

- (IBAction)startProcessing:(UIButton *)sender;
- (IBAction)solve:(id)sender;
-(void)processImage:(cv::Mat&)image;
@end

