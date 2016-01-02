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

bool compareYX(const cv::Point& left, const cv::Point& right) {
    return (left.y < right.y) || ((left.y == right.y) && (left.x < right.x));
}

-(cv::Point)sectionFormula: (cv::Point)P1 Point2: (cv::Point)P2 Division:(cv::Point)MN
{
    return cv::Point(((MN.x*P2.x + MN.y*P1.x)/(MN.x+MN.y)),(MN.x*P2.y + MN.y*P1.y)/(MN.x+MN.y));
}

vector<vector<cv::Point>> previousPoints;
vector<cv::Point> averageCalc(vector<cv::Point> cen)
{
    vector<cv::Point> avg;
    float sumx = 0, sumy = 0;
    for (int i = 0; i < 16; ++i) {
        sumx = cen[i].x;
        sumy = cen[i].y;
        
        
        for (int j = 0; j < frames; ++j) {
            
            sumx += previousPoints[j][i].x;
            sumy +=previousPoints[j][i].y;
        }
        avg.push_back(cv::Point(sumx/(previousPoints.size()), sumy/(previousPoints.size())));
    }
    return avg;
}
float distFormula(cv::Point P1, cv::Point P2)
{
    return sqrt(pow(P1.x-P2.x,2)+pow(P1.y-P2.y,2));
}
int frames = 0;int tolerance = 5;
int toleranceC=0;
- (void)processImage:(Mat&)image
{
    Mat img = image, gray, mask, ker, c;
    Mat org = image.clone();
    GaussianBlur(img, img, cv::Size(7,7), 0);
    cvtColor(img, gray , CV_BGR2GRAY);
    mask = Mat::zeros(img.rows, img.cols, CV_8U);
    ker = getStructuringElement(MORPH_ELLIPSE, cv::Size(11,11));
    morphologyEx(gray, c, MORPH_CLOSE, ker);
    
    Mat thr;
    
    
    
    Mat div ;
    divide(gray, c, div);
    normalize(div, div, 0,255, NORM_MINMAX);
    Mat res;
    div.convertTo(res, CV_8U);
    Mat res2, res3;
    cvtColor(res, res2, COLOR_GRAY2BGR);
    //image = res;
    
    adaptiveThreshold(res, thr, 255, 0, 1, 19, 2);
    vector<vector<cv::Point>> lines, contours;
    vector<Vec4i> hierarchy;
    findContours(thr, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE);
    
    int largest_area=0;
    int largest_contour_index=0;
    for (int i = 0; i< contours.size(); i++){
        double a = contourArea(contours[i], false);  //  Find the area of contour
        if (a>largest_area){
            largest_area = a;
            largest_contour_index = i;                //Store the index of largest contour
        }
    }
    
    drawContours(mask, contours, largest_contour_index, 0, 2);
    drawContours(mask, contours, largest_contour_index, Scalar(255, 255, 255), -1);
    
    //bitwise_not(mask, mask);
    bitwise_and(res, mask, res);
    //bitwise_or(res, mask, mask);
    //image=res;
    
    //image=res;
    //drawContours(mask, <#InputArrayOfArrays contours#>, <#int contourIdx#>, <#const Scalar &color#>)
    
    //Mat crop(image.rows, image.cols, CV_8UC3);
    //crop.setTo(Scalar(0,255,0));
    Mat kerx, kery;
    kerx=getStructuringElement(MORPH_RECT, cv::Size(2,10));
    
    Mat dx, dy;
    Sobel(res, dx, CV_16S, 1, 0);
    
    convertScaleAbs(dx, dx);
    
    normalize(dx, dx, 0,255, NORM_MINMAX);
    
    Mat ret, close;
    
    ret = threshold(dx, close, 0, 255, THRESH_BINARY+THRESH_OTSU);
    //ret = threshold(close, close, 0, 255, );
    morphologyEx(close, close, MORPH_CLOSE, kerx, cv::Point(-1,-1), 1);
    
    findContours(close, contours, hierarchy, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_SIMPLE);
    cv::Rect rec;
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
    
    Mat closex, closey;
    close.copyTo(closex);
    kery=getStructuringElement(MORPH_RECT, cv::Size(10,2));
    Sobel(res, dy, CV_16S, 0, 2);
    convertScaleAbs(dy, dy);
    normalize(dy, dy, 0,255, NORM_MINMAX);
    ret = threshold(dy, close, 0, 255, THRESH_BINARY+THRESH_OTSU);
    //ret = threshold(close, close, 0, 255, );
    //threshold(dy, close, 0, 255, THRESH_OTSU);
    morphologyEx(close, close, MORPH_CLOSE, kery);
    findContours(close, contours, hierarchy, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_SIMPLE);
    //cv::Rect rec;
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
    //res2.copyTo(res2, mask);
    //image = res;
    cv::String a;
    findContours(res, contours, hierarchy, CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE);
    
    vector<cv::Point> cen;
    for (int i=0; i<contours.size(); ++i) {
        //if (i != contours.size()-1) {
        {  cv::Moments m = moments(contours[i]);
            cv::Point P = cv::Point(int(m.m10/m.m00), int(m.m01/m.m00));
            
            //circle(img, points[i], 4, Scalar(2*i,3*i,5*i), -1);
            cen.push_back(P);
            
        }
    }
    //image = img;
    
    //cout << cen.size() << endl;
    vector<cv::Point> arrangedPoints;
    std::sort(cen.begin(), cen.end(), compareYX);
    
    //image=mask;
    
    vector<cv::Point> points;
    
    if(cen.size()==16)
        
    {
        //        int smallestIndex=0;
        //        float smallestDist;
        //        for (int i= 0; i < 16; i++) {
        //            smallestDist=distFormula(arrangedPoints[i], cen[i]);
        //            for (int j = 0; j<16; j++) {
        //                if (smallestDist < distFormula(arrangedPoints[i], cen[j])) {
        //                    smallestIndex = j;
        //                }
        //            }
        //            cen2.push_back(cen[smallestIndex]);
        //        }
        //        for (int i=0; i < cen2.size(); ++i) {
        //            a.operator=(i+65);
        //            circle(img, cen2[i], 4, Scalar(255,255,0), -1);
        //            putText(img, a, cen2[i], FONT_HERSHEY_PLAIN, 1, Scalar(255,255,255));
        //        }
        //        cen=cen2;
        //std::sort(cen.begin(), cen.end(), SortbyYaxis);
        
        if (cen[0].x > 15-tolerance && cen[0].x < 15+tolerance && cen[0].y > 37-tolerance && cen[0].y < 37+tolerance) {
            
            
            for(int i=0; i<10; ++i)
            {
                for (int j = 0; j < 10; ++j) {
                    arrangedPoints.push_back(cv::Point(15+j*27.67,37+i*27.67));
                    circle(img, cv::Point(15+j*27.67,37+i*27.67), 4, Scalar(255,255,0), -1);
                    
                }
            }
            
                
                
                
                //
                //            for(int i=0; i < 11; ++i)
                //            {
                //                points.push_back(arrangedPoints[i]);
                //
                //
                //                points.push_back([self sectionFormula:arrangedPoints[i] Point2:arrangedPoints[i+1] Division:cv::Point(1,2)]);
                //
                //                points.push_back([self sectionFormula:arrangedPoints[i] Point2:arrangedPoints[i+1] Division:cv::Point(2,1)]);
                //
                //
                //
                //                if ((i+2)%4==0) {
                //                    i++;
                //                    //points.push_back(arrangedPoints[++i]);
                //                    points.push_back([self sectionFormula:arrangedPoints[i-3] Point2:arrangedPoints[i+1] Division:cv::Point(1,2)]);
                //                    for (int j = 1; j< 10; ++j) {
                //                        //points.push_back(cv::Point(arrangedPoints[i-3].x+83*j, arrangedPoints[i-3].y+83));
                //                    }
                //                    for (int j = 0; j< 10; ++j) {
                //                        //points.push_back(cv::Point(arrangedPoints[i-3].x+83*j, arrangedPoints[i-3].y+166));
                //                    }
                //
                //
                //
                //
                //}
                [self.lab setText:@"Wo"];
                
                
                //}
                
                
                for(int i=0; i<points.size(); ++i)
                {
                    a.operator=(i+65);
                    putText(img, a, points[i], FONT_HERSHEY_PLAIN, 1, Scalar(255,255,255));
                    circle(img, points[i], 2, Scalar(255,0,0), -1);
                    
                }
                image = img;
                G8Tesseract *tesseract = [[G8Tesseract alloc] initWithLanguage:@"eng"];
                
                
                tesseract.charWhitelist = @"0123456789";
            cvtColor(org, org , CV_BGR2GRAY);
            ker = getStructuringElement(MORPH_ELLIPSE, cv::Size(15,15));
            morphologyEx(gray, c, MORPH_CLOSE, ker);
            divide(org, c, div);
            normalize(div, div, 0,255, NORM_MINMAX);
            div.convertTo(org, CV_8U);
            [tesseract setImage:[[UIImage imageWithCVMat:org] g8_blackAndWhite]];
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
                    //i++;
                    continue;
                }
                if ([a1 length]==0) {
                    puzzle=[puzzle stringByAppendingString:@"0"];
                }
                else puzzle=[puzzle stringByAppendingString:[a1 substringWithRange:NSMakeRange(0, 1)]];
                
                
                
            }
            
            
                NSLog(@"%@...%lu", puzzle, (unsigned long)[puzzle length]);
//                for (int i = 0 ; i < arrangedPoints.size(); ++i) {
//                    
//                    if ((i+1)%10 != 0) {
//                        
//                    }
//                    else ++i;
//                }
//                
            
                dispatch_async(dispatch_get_main_queue(), ^{
                    // Update UI here
                    
                    //lab.text = @"Woo";
                    
                    [self.detectedGrid setImage:[UIImage imageWithCGImage:CGImageCreateWithImageInRect([[UIImage imageWithCVMat:org] CGImage], CGRectMake(CGFloat(arrangedPoints[8].x+5), CGFloat(arrangedPoints[8].y+5), 18.67, 18.67))] ];
                    
                    [self.lab setText:@"asd"];
                });
                
                
                //[self.videoCamera stop];
                //[self.videoCamera start];
                
                
                cout << "Woo";
            
            
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
            //cout<<"reset";
            previousPoints.clear();
            toleranceC=0;
            frames = 0;
        }
        else
        {
            toleranceC++;
        }
    }
    arrangedPoints.clear();
    /*Mat image_copy = image;
     
     cv::Rect bounding_rect;
     //Canny(image_copy, image_copy, 50, 200, 3);
     Mat src = image_copy; //Load source image
     Mat t
     //drawContours( dst, contours,largest_contour_index, color, CV_FILLED, 8, hierarchy ); // Draw the largest contour using previously stored index.
     //rectangle(src, bounding_rect,  Scalar(0,255,0),1, 8,0);
     
     cvtColor(image, image_copy,COLOR_BGR2GRAY);
     //cv::threshold(image, image_copy, 50, 255, CV_THRESH_BINARY);
     // invert image
     Canny(image_copy, image_copy, 50, 200, 3);
     vector<Vec2f> lines, contours;
     vector<Vec4i> hierarchy;
     cv::threshold(image_copy, image_copy, 128, 255, CV_THRESH_BINARY);
     //findContours(image_copy, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE);
     HoughLines(image_copy, lines, 1, CV_PI/180, 130, 0, 0 );
     vector<Vec4i> lines1;
     std::vector<int> labels;
     int numberOfLines = cv::partition(lines1, labels, isEqual);
     NSLog(@"%d", numberOfLines);
     Mat drawing = Mat::zeros( image_copy.size(), CV_8UC3 );
     image_copy=image;
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
     line( image_copy, pt1, pt2, Scalar(255,0,0), 1, CV_AA);
     }
     //Scalar color = Scalar( rng.uniform(0, 255), rng.uniform(0,255), rng.uniform(0,255) );
     //drawContours( drawing, contours, i, color, 2, 8, hierarchy, 0, cv::Point() );
     }*/
    //Convert BGR to BGRA (three channel to four c#include <opencv2/opencv.hpp>hannel)
    //Mat bgr;
    //cvtColor(image_copy, bgr, COLOR_GRAY2BGR);
    //cvtColor(bgr, image, COLOR_BGR2BGRA);*/
    
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
    
    //detectedGrid.image  = imageU;
}

- (IBAction)solve:(id)sender {
    
}
@end
