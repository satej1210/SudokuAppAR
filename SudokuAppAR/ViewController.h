//
//  ViewController.h
//  SudokuAppAR
//
//  Created by Satej Mhatre on 12/24/15.
//  Copyright © 2015 Satej Mhatre. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <opencv2/opencv.hpp>
#import <opencv2/videoio/cap_ios.h>
@interface ViewController : UIViewController<CvVideoCameraDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

- (IBAction)startProcessing:(UIButton *)sender;

@end

