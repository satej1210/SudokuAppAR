//
//  ViewController.m
//  SudokuAppAR
//
//  Created by Satej Mhatre on 12/24/15.
//  Copyright © 2015 Satej Mhatre. All rights reserved.
//

#import "ViewController.h"
@interface ViewController ()
{
    CvVideoCamera* videoCamera;
}
@property (nonatomic, retain) CvVideoCamera* videoCamera;
@end

@implementation ViewController
using namespace cv;
using namespace std;
@synthesize imageView, videoCamera;
RNG rng(12345);
int thresh = 100;
bool FindIntersection(vector<Vec2f> line1, vector<Vec2f>line2, Point2f &r)
{
    return true;
}
- (void)processImage:(Mat&)image;
{
    Mat image_copy;
    /*Mat r, s;
     cvtColor(image,r,COLOR_BGR2GRAY);
     adaptiveThreshold(r,r,255,1,1,11,15);
     vector<vector<cv::Point> > contours, big;
     
     
     vector<Vec4i> hierarchy;
     findContours(r, contours, hierarchy, RETR_LIST, CHAIN_APPROX_SIMPLE);
     r.copyTo(s);
     int size_max=0;
     vector<vector<cv::Point> > contours_poly( contours.size() );
     
     for( int i = 0; i < contours.size(); i++ )
     
     {
     int size = contourArea(contours[i]);
     if (size>100) {
     float peri = arcLength(contours[i], true);
     approxPolyDP( Mat(contours[i]), contours_poly[i], 0.02*peri, true );
     if (size>size_max && contours_poly[i].size()==4) {
     big = contours_poly;
     size_max=size;
     }
     }
     }
     
     contours_poly=big;
     for (int i=0; i<contours_poly.size(); ++i) {
     cv::Point one = cv::Point(big[i%4][0].x,big[i%4][0].y);
     cv::Point two = cv::Point(big[(i+1)%4][0].x,big[(i+1)%4][1].y);
     line(s, one, two, Scalar(255,255,255), 2);
     }
     
     for(int i=0; i<contours.size(); ++i)
     {
     //approxPolyDP(Mat(contours[i]), approx[i], 3, true);
     }
     approx=big;
     for (int i=0; i<approx.size(); ++i) {
     cv::Point one = cv::Point(big[i%4][0].x,big[i%4][1].y);
     cv::Point two = cv::Point(big[(i+1)%4][0].x,big[(i+1)%4][1].y);
     line(s, one, two, Scalar(255,0,0));
     }
     *//* Do some OpenCV stuff with the image
        Mat src_gray;
        Mat canny_output;
        
        cvtColor( image, src_gray, CV_BGR2GRAY );
        blur( src_gray, src_gray, cv::Size(3,3) );
        
        /// Detect edges using canny
        Canny( src_gray, canny_output, thresh, thresh*2, 3 );
        /// Find contours
        findContours( canny_output, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE, cv::Point(0, 0) );
        
        /// Draw contours
        Mat drawing = Mat::zeros( canny_output.size(), CV_8UC3 );
        for( int i = 0; i< contours.size(); i++ )
        {
        Scalar color = Scalar( rng.uniform(0, 255), rng.uniform(0,255), rng.uniform(0,255) );
        drawContours(drawing, contours, i, color, 2, 8, hierarchy, 0, cv::Point() );
        cv::Point l = cv::Point(contours[i][0].x, contours[i][0].y);
        circle(src_gray, l ,1,CV_RGB(255,0,0),3);
        }*/
    
    cvtColor(image, image_copy,COLOR_BGR2GRAY);
    //cv::threshold(image, image_copy, 50, 255, CV_THRESH_BINARY);
    // invert image
    Canny(image_copy, image_copy, 50, 200, 3);
    vector<Vec2f> lines, contours;
    vector<Vec4i> hierarchy;
    cv::threshold(image_copy, image_copy, 128, 255, CV_THRESH_BINARY);
    //findContours(image_copy, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE);
    HoughLines(image_copy, lines, 1, CV_PI/180, 125, 0, 0 );
    Mat drawing = Mat::zeros( image_copy.size(), CV_8UC3 );
    for( int i = 0; i < lines.size(); i++ )
    {
        float rho = lines[i][0], theta = lines[i][1];
        if( (theta>CV_PI/180*80 && theta<CV_PI/180*100)||theta>CV_PI/180*170 || theta<CV_PI/180*10)
        {
            cv::Point pt1, pt2;
            double a = cos(theta), b = sin(theta);
            double x0 = a*rho, y0 = b*rho;
            pt1.x = cvRound(x0 + 1000*(-b));
            pt1.y = cvRound(y0 + 1000*(a));
            pt2.x = cvRound(x0 - 1000*(-b));
            pt2.y = cvRound(y0 - 1000*(a));
            circle(image_copy, pt1, 100, Scalar(255,255,255,0));
            line( image_copy, pt1, pt2, Scalar(255,0,0), 3, CV_AA);
        }
        //Scalar color = Scalar( rng.uniform(0, 255), rng.uniform(0,255), rng.uniform(0,255) );
        //drawContours( drawing, contours, i, color, 2, 8, hierarchy, 0, cv::Point() );
    }
    //Convert BGR to BGRA (three channel to four c#include <opencv2/opencv.hpp>hannel)
    Mat bgr;
    cvtColor(image_copy, bgr, COLOR_GRAY2BGR);
    cvtColor(bgr, image, COLOR_BGR2BGRA);
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.videoCamera = [[CvVideoCamera alloc] initWithParentView:imageView];
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset352x288;
    self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    self.videoCamera.defaultFPS = 30;
    self.videoCamera.delegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)startProcessing:(UIButton *)sender {
    [self.videoCamera start];
}
@end
