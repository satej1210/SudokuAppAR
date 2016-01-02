//
//  ViewController.m
//  SudokuAppAR
//
//  Created by Satej Mhatre on 12/24/15.
//  Copyright © 2015 Satej Mhatre. All rights reserved.
//

#import "ViewController.h"

using namespace cv;
using namespace std;

@interface ViewController ()
{
    CvVideoCamera* videoCamera;
}

@property (nonatomic, retain) CvVideoCamera* videoCamera;

@end

@implementation ViewController

@synthesize imageView, videoCamera, detectedGrid, lab;
int frames = 0;
int tolerance = 5;
int toleranceC=0;


bool compareYX(const cv::Point& left, const cv::Point& right) {
    return (left.y < right.y) || ((left.y == right.y) && (left.x < right.x));
}

-(cv::Point)sectionFormula: (cv::Point)P1 Point2: (cv::Point)P2 Division:(cv::Point)MN
{
    return cv::Point(((MN.x*P2.x + MN.y*P1.x)/(MN.x+MN.y)),(MN.x*P2.y + MN.y*P1.y)/(MN.x+MN.y));
}
NSArray *SampleDigits = [[NSArray alloc] init];

float distFormula(cv::Point P1, cv::Point P2)
{
    return sqrt(pow(P1.x-P2.x,2)+pow(P1.y-P2.y,2));
}
-(Mat)MaskContour: (Mat&)img
{
    return Mat::zeros(img.rows, img.cols, CV_8U);;
}
-(Mat)NormalizeImage: (Mat&)img
{
    Mat gray, c, ker, div, res, res2;
    cvtColor(img, gray , CV_BGR2GRAY);
    ker = getStructuringElement(MORPH_ELLIPSE, cv::Size(11,11));
    morphologyEx(gray, c, MORPH_CLOSE, ker);
    divide(gray, c, div);
    normalize(div, div, 0,255, NORM_MINMAX);
    div.convertTo(res, CV_8U);
    cvtColor(res, res2, COLOR_GRAY2BGR);
    return res;
}

- (void)processImage:(Mat&)image
{
    Mat img = image,  org = image.clone(), thr, mask = [self MaskContour: img], kerx, kery, dx, dy, ret, close, closex, closey;
    cv::Rect rec;
    cv::String a;
    vector<cv::Point> arrangedPoints, AllArrangedPoints, cen;

    GaussianBlur(img, img, cv::Size(7,7), 0);
    Mat res = [self NormalizeImage:img];
    
    adaptiveThreshold(res, thr, 255, 0, 1, 19, 2);
    vector<vector<cv::Point>> lines, contours;
    vector<Vec4i> hierarchy;
    findContours(thr, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE);
    
    int largest_area=0;
    int largest_contour_index=0;
    for (int i = 0; i< contours.size(); i++){
        double a = contourArea(contours[i], false);
        if (a>largest_area){
            largest_area = a;
            largest_contour_index = i;
        }
    }

    
    drawContours(mask, contours, largest_contour_index, 0, 2);
    drawContours(mask, contours, largest_contour_index, Scalar(255, 255, 255), -1);
    
    bitwise_and(res, mask, res);
    
 
    kerx=getStructuringElement(MORPH_RECT, cv::Size(2,10));
    
    
    Sobel(res, dx, CV_16S, 1, 0);
    
    convertScaleAbs(dx, dx);
    
    normalize(dx, dx, 0,255, NORM_MINMAX);

    
    ret = threshold(dx, close, 0, 255, THRESH_BINARY+THRESH_OTSU);

    morphologyEx(close, close, MORPH_CLOSE, kerx, cv::Point(-1,-1), 1);
    
    findContours(close, contours, hierarchy, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_SIMPLE);
    
    for(int i=0; i<contours.size(); ++i)
    {
        rec = boundingRect(contours[i]);
        if (rec.height/rec.width > 3) {
            drawContours(close, contours, i, Scalar(255,255,255), -1);
        }
        else{
            drawContours(close, contours, i, 0, -1);
        }
    }
    
    
    morphologyEx(close, close, MORPH_DILATE, NULL, cv::Point(-1,-1), 2);
    

    close.copyTo(closex);
    kery=getStructuringElement(MORPH_RECT, cv::Size(10,2));
    Sobel(res, dy, CV_16S, 0, 2);
    convertScaleAbs(dy, dy);
    normalize(dy, dy, 0,255, NORM_MINMAX);
    ret = threshold(dy, close, 0, 255, THRESH_BINARY+THRESH_OTSU);
    
    morphologyEx(close, close, MORPH_CLOSE, kery);
    findContours(close, contours, hierarchy, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_SIMPLE);

    for(int i=0; i<contours.size(); ++i)
    {
        rec = boundingRect(contours[i]);
        if (rec.width/rec.height > 3) {
            drawContours(close, contours, i,Scalar(255,255,255),-1);
        }
        else{
            drawContours(close, contours, i, 0, -1);
        }
    }
    morphologyEx(close, close, MORPH_CLOSE, NULL, cv::Point(-1,-1), 2);
    close.copyTo(closey);
    bitwise_and(closex,closey, res);
    morphologyEx(res, res, MORPH_OPEN
                 , NULL, cv::Point(-1,-1), 1);

    
    findContours(res, contours, hierarchy, CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE);
    
    
    for (int i=0; i<contours.size(); ++i) {
        {  cv::Moments m = moments(contours[i]);
            cv::Point P = cv::Point(int(m.m10/m.m00), int(m.m01/m.m00));
            cen.push_back(P);
        }
    }

    
   
    std::sort(cen.begin(), cen.end(), compareYX);
    

    
    
    
    if(cen.size()==16)
        
    {
        if (cen[0].x > 15-tolerance && cen[0].x < 15+tolerance && cen[0].y > 37-tolerance && cen[0].y < 37+tolerance) {
            
            
            for(int i=0; i<10; ++i)
            {
                for (int j = 0; j < 10; ++j) {
                    arrangedPoints.push_back(cv::Point(15+j*27.67,37+i*27.67));
                    circle(img, cv::Point(15+j*27.67,37+i*27.67), 4, Scalar(255,255,0), -1);
                    
                }
            }
                
                
                for(int i=0; i<AllArrangedPoints.size(); ++i)
                {
                    a.operator=(i+65);
                    putText(img, a, AllArrangedPoints[i], FONT_HERSHEY_PLAIN, 1, Scalar(255,255,255));
                    circle(img, AllArrangedPoints[i], 2, Scalar(255,0,0), -1);
                    
                }
                image = img;
                G8Tesseract *tesseract = [[G8Tesseract alloc] initWithLanguage:@"eng"];
                
                
                tesseract.charWhitelist = @"0123456789";
            [tesseract setImage:[[UIImage imageWithCVMat:[self NormalizeImage:org]] g8_blackAndWhite]];
            NSString* a1, *puzzle=@"";
            for(int i=0; i < 90; ++i)
            {
                
                tesseract.rect = CGRectMake(CGFloat(arrangedPoints[i].x+5), CGFloat(arrangedPoints[i].y+5), 18.67, 18.67);
                [tesseract recognize];
                a1 = [tesseract recognizedText];
                a1 = [a1 stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                a1 = [a1 stringByReplacingOccurrencesOfString:@" " withString:@""];
                if ((i+1)%10==0 && i!=0 && i!=90) {
                    puzzle=[puzzle stringByAppendingString:@"\n"];

                    continue;
                }
                if ([a1 length]==0) {
                    puzzle=[puzzle stringByAppendingString:@"0"];
                }
                else puzzle=[puzzle stringByAppendingString:[a1 substringWithRange:NSMakeRange(0, 1)]];
                
                
                
            }
            
            
                NSLog(@"%@...%lu", puzzle, (unsigned long)[puzzle length]);

            
                dispatch_async(dispatch_get_main_queue(), ^{

                    [self.detectedGrid setImage:[UIImage imageWithCGImage:CGImageCreateWithImageInRect([[UIImage imageWithCVMat:org] CGImage], CGRectMake(CGFloat(arrangedPoints[8].x+5), CGFloat(arrangedPoints[8].y+5), 18.67, 18.67))] ];
                    
                    [self.lab setText:@"asd"];
                });

                
                

            
            
        }
        else
        {
            a="Put Top Left Corner Here";
            putText(img, a, cv::Point(15,37), FONT_HERSHEY_PLAIN, 1, Scalar(255,255,255));
            circle(img, cv::Point(15,37), 4, Scalar(255,255,0), -1);
            a = "Put Corner Here";
            putText(img, a, cv::Point(15,286), FONT_HERSHEY_PLAIN, 1, Scalar(255,255,255));
            circle(img, cv::Point(15,286), 4, Scalar(255,255,0), -1);
            a = "Blah";
            putText(img, a, cv::Point(264,37), FONT_HERSHEY_PLAIN, 1, Scalar(255,255,255));
            circle(img, cv::Point(264,37), 4, Scalar(255,255,0), -1);
            a="And Bottom Right Corner Here";
            putText(img, a, cv::Point(25,286), FONT_HERSHEY_PLAIN, 1, Scalar(255,255,255));
            circle(img, cv::Point(264,286), 4, Scalar(255,255,0), -1);
        }
    }
    else
    {
        if (toleranceC == tolerance) {


            toleranceC=0;
            frames = 0;
        }
        else
        {
            toleranceC++;
        }
    }
    arrangedPoints.clear();
    
}
- (void)viewDidLoad {
    [super viewDidLoad];
    

    self.videoCamera = [[CvVideoCamera alloc] initWithParentView:imageView];
    
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset352x288;
    self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    self.videoCamera.defaultFPS = 30;
    self.videoCamera.delegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];

}

- (IBAction)startProcessing:(UIButton *)sender {
    [self.videoCamera start];
    

}

- (IBAction)solve:(id)sender {
    
}
@end
