//
//  ViewController.m
//  SudokuAppAR
//
//  Created by Satej Mhatre on 12/24/15.
//  Copyright © 2015 Satej Mhatre. All rights reserved.
//

#import "ViewController.h"
#include "SudokuSolver.h"
#define SampleDigitsCount 5
using namespace cv;
using namespace std;

@interface ViewController ()
{
    CvVideoCamera* videoCamera;
}

@property (nonatomic, retain) CvVideoCamera* videoCamera;
@property (nonatomic, assign) id currentResponder;
@end

@implementation ViewController


@synthesize imageView, videoCamera, detectedGrid, lab, textField, Solved, StartButton, ContainerView;

int frames = 0;
int tolerance = 2;
int toleranceC=0;
int SampleCount=0;
float Samples = SampleDigitsCount;
float confidence = 0;
int isSolved = 0;
int DetectedFrames = 100;
int DetectedFrameCount=0;
vector<NSString*> SampleDigits;
int processingInQueue=0;
int AskToAim = 0;
vector<Mat> SampleImage;
vector<vector<cv::Point>> SamplePoints;

bool compareYX(const cv::Point& left, const cv::Point& right)
{
    return (left.y < right.y) || ((left.y == right.y) && (left.x < right.x));
}

-(cv::Point)sectionFormula: (cv::Point)P1 Point2: (cv::Point)P2 Division:(cv::Point)MN
{
    return cv::Point(((MN.x*P2.x + MN.y*P1.x)/(MN.x+MN.y)),(MN.x*P2.y + MN.y*P1.y)/(MN.x+MN.y));
}


float distFormula(cv::Point P1, cv::Point P2)
{
    return sqrt(pow(P1.x-P2.x,2)+pow(P1.y-P2.y,2));
}


-(Mat)NormalizeImage: (Mat)img
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

int mode (int x[],int n)
{
    int y[SampleDigitsCount]={0};
    int i,j,k,m,cnt,max=0,no_mode=0,mode_cnt=0;
    double num;
    
    for(k=0; k<n; k++)
    {
        cnt=0;
        num=x[k];
        
        for(i=k; i<n; i++)
        {
            if(num==x[i])
                cnt++;
            
        }
        y[k]=cnt;
        if(cnt>=2)
        {
            no_mode++;
        }
    }
    
    if(no_mode==0)
    {
        
        confidence =0;
        return 0;
    }
    for(j=0; j<n; j++)
        
    {
        if(y[j]>max)
            max=y[j];
    }
    for(m=0; m<n; m++)
    {
        
        if(max==y[m])
            mode_cnt++;
    }
    int val=0, times = 0;
    
    for(m=0; m<n; m++)
    {
        if(max==y[m])
        {
            val = x[m];
            times=  y[m];
            //cout<<"The value "<<x[m]<<" appeared "<<y[m]<<" times in the data set\n"<<endl;
        }
    }
    confidence += times;
    return val;
}

-(NSString*) bestGuessCalc
{
    NSString* bestGuess = @"";
    int arr[SampleDigitsCount];
    
    for (int i = 0; i < SampleDigits[0].length ; ++i)
    {
        
        for (int j = 0; j < SampleDigits.size(); ++j)
        {
            arr[j] = [[SampleDigits[j] substringWithRange:NSMakeRange(i, 1)] intValue];
            
        }
        bestGuess = [bestGuess stringByAppendingString:[NSString stringWithFormat:@"%d", mode(arr, SampleDigitsCount)]];
        
        
    }
    SampleDigits.clear();
    return bestGuess;
}

double angle( cv::Point pt1, cv::Point pt2, cv::Point pt0 )
{
    double dx1 = pt1.x - pt0.x;
    double dy1 = pt1.y - pt0.y;
    double dx2 = pt2.x - pt0.x;
    double dy2 = pt2.y - pt0.y;
    return (dx1*dx2 + dy1*dy2)/sqrt((dx1*dx1 + dy1*dy1)*(dx2*dx2 + dy2*dy2) + 1e-10);
}

vector<cv::Point> sortThisMyWay(vector<cv::Point> points)
{
    vector<cv::Point> newCen;
    vector<cv::Point> sectionsMin, sectionsMax;
    sectionsMin.push_back(cv::Point(0,0));
    sectionsMax.push_back(cv::Point(135, 240));
    
    sectionsMin.push_back(cv::Point(135, 0));
    sectionsMax.push_back(cv::Point(270, 240));
    
    sectionsMin.push_back(cv::Point(0,240));
    sectionsMax.push_back(cv::Point(135, 480));
    
    sectionsMin.push_back(cv::Point(135,240));
    sectionsMax.push_back(cv::Point(270, 480));
    
    
    cv::Point thePoint;
    for (int j = 0; j < 4; ++j) {
        for (int i = 0; i < points.size(); ++i) {
            if (points[i].x < sectionsMax[j].x
                && points[i].y < sectionsMax[j].y
                && points[i].x > sectionsMin[j].x
                && points[i].y > sectionsMin[j].y
                ) {
                thePoint.x = points[i].x;
                thePoint.y = points[i].y;
                points.pop_back();
            }
        }
        newCen.push_back(thePoint);
    }
    return newCen;
    
}

-(void)processSampleImages
{
    G8Tesseract *tesseract = [[G8Tesseract alloc] initWithLanguage:@"eng"];
    tesseract.charWhitelist = @" 0123456789";
    cv::Mat tmp;
    NSString* a1, *puzzle=@"";
    for (int j=0; j<SampleDigitsCount; ++j)
    {
        cv::GaussianBlur(SampleImage[j], tmp, cv::Size(5,5), 5);
        cv::addWeighted(SampleImage[j], 1.5, tmp, -0.5, 0, SampleImage[j]);
        [tesseract setImage:[[UIImage imageWithCVMat:[self NormalizeImage:SampleImage[j]]] g8_blackAndWhite]];
        for(int i=0; i < 90; ++i)
        {
            
            if((i+1)%10!=0 || i==0)
            {
                tesseract.rect = CGRectMake(CGFloat(SamplePoints[j][i].x+10), CGFloat(SamplePoints[j][i].y+10), 40, 40);
                [tesseract recognize];
                
                a1 = [tesseract recognizedText];
                a1 = [a1 stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                a1 = [a1 stringByReplacingOccurrencesOfString:@" " withString:@""];
                
                if ((i+1)%10==0 && i!=0 && i!=90)
                {
                    puzzle=[puzzle stringByAppendingString:@""];
                    
                    continue;
                }
                if ([a1 length]==0)
                {
                    puzzle=[puzzle stringByAppendingString:@"0"];
                }
                else
                    puzzle=[puzzle stringByAppendingString:[a1 substringWithRange:NSMakeRange(0, 1)]];
            }
        }
        SampleDigits.push_back(puzzle);
    }
}

- (void)processImage:(Mat&)image
{
    if (processingInQueue) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.lab setText:[NSString stringWithFormat:@"Solving... Please Wait."]];
        });
    }
    
    
    if ([[UIDevice currentDevice] orientation] == 1 ||
        [[UIDevice currentDevice] orientation] == 5)
    {
        Mat img = image,  org = image.clone(), mask, res;
        vector<vector<cv::Point>> contours;
        cv::Rect rec;
        cv::String a;
        vector<cv::Point> arrangedPoints, cen;
        int largest_area=0;
        int largest_contour_index=0;
        
        resize(img, img, cv::Size(270, 480));
        
        GaussianBlur(img, img, cv::Size(1,1), 0);
        
        
        
        {
            mask = Mat::zeros(img.rows, img.cols, CV_8U);
            Mat res = [self NormalizeImage:img], thr;
            adaptiveThreshold(res, thr, 255, 0, 1, 19, 2);
            
            vector<Vec4i> hierarchy;
            findContours(thr, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE);
            for (int i = 0; i< contours.size(); i++)
            {
                double a = contourArea(contours[i], false);
                if (a>largest_area)
                {
                    largest_area = a;
                    largest_contour_index = i;
                }
            }
            drawContours(mask, contours, largest_contour_index, 0, 2);
            drawContours(mask, contours, largest_contour_index, Scalar(255, 255, 255), -1);
        }
        if (largest_area > 30000)
        {
            
            if (contours.size() > 0)
            {
                vector<cv::Point>approx;
                vector<RotatedRect> rotatedRect;
                rec = boundingRect(contours[largest_contour_index]);
                
                approxPolyDP(Mat(contours[largest_contour_index]), approx,
                             arcLength(Mat(contours[largest_contour_index]), true)*0.02, true);
                
                if (approx.size() == 4 &&
                    fabs(contourArea(Mat(approx))) > 1000 &&
                    isContourConvex(Mat(approx)) &&
                    largest_area < 70000)
                {
                    double maxCosine = 0;
                    
                    for( int j = 2; j < 5; j++ )
                    {
                        double cosine = fabs(angle(approx[j%4], approx[j-2], approx[j-1]));
                        maxCosine = MAX(maxCosine, cosine);
                    }
                    
                    if( maxCosine < 0.3 )
                    {
                        vector<cv::Point> corners;
                        goodFeaturesToTrack(mask, corners, 4, 0.01, 30);
                        
                        if (largest_area < 40000) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self.lab setText:[NSString stringWithFormat:@"Go Closer"]];
                            });
                        }
                        else if (largest_area > 55000 &&
                                 !isSolved)
                        {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                
                                
                                [self.lab setText:[NSString stringWithFormat:@"Back Up"]];
                                
                            });
                        }
                        else
                        {
                            for(int i = 0; i < corners.size(); ++i)
                            {
                                cen.push_back(corners[i]);
                            }
                            vector<cv::Point>newCen;
                            cv::Point point;
                            newCen = sortThisMyWay(cen);
                            
                            if(cen.size()==4)
                            {
                                for(int i=0; i<1; ++i)
                                {
                                    arrangedPoints.push_back(newCen[i]);
                                    for (int j = 1; j < 9; ++j)
                                    {
                                        arrangedPoints.push_back([self sectionFormula:newCen[i] Point2:newCen[i+1] Division:cv::Point(j, 9-j)]);
                                    }
                                    arrangedPoints.push_back(newCen[i+1]);
                                    for (int l = 0; l < 8; ++l)
                                    {
                                        cv::Point temp1 = [self sectionFormula:newCen[i] Point2:newCen[i+2] Division:cv::Point(1+l,8-l)];
                                        arrangedPoints.push_back(temp1);
                                        cv::Point temp2 = [self sectionFormula:newCen[i+1] Point2:newCen[i+3] Division:cv::Point(1+l,8-l)];
                                        for (int j=1; j < 9; ++j)
                                        {
                                            arrangedPoints.push_back([self sectionFormula:temp1 Point2:temp2 Division:cv::Point(j, 9-j)]);
                                        }
                                        arrangedPoints.push_back(temp2);
                                        
                                        
                                    }
                                    arrangedPoints.push_back(newCen[i+2]);
                                    for (int j = 1; j < 9; ++j)
                                    {
                                        arrangedPoints.push_back([self sectionFormula:newCen[i+2] Point2:newCen[i+3] Division:cv::Point(j, 9-j)]);
                                    }
                                    arrangedPoints.push_back(newCen[i+3]);
                                }
                                for (int i=0; i < arrangedPoints.size(); ++i)
                                {
                                    arrangedPoints[i] = cv::Point((arrangedPoints[i].x+2)*2.66667, (arrangedPoints[i].y+2)*2.66667);
                                }
                                
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [self.detectedGrid setImage:[UIImage imageWithCGImage:CGImageCreateWithImageInRect([[UIImage imageWithCVMat:image] CGImage], CGRectMake(CGFloat(arrangedPoints[7].x+10), CGFloat(arrangedPoints[7].y+10), 50, 45)) ]];
                                });
                                
                                if (isSolved) {
                                    NSString *completedPuz = [NSString stringWithCString:getStringCompleted() encoding:NSASCIIStringEncoding];
                                    NSString *puz = [[textField text] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                                    int lol=0;
                                    for(int i=0; i < 81; ++i)
                                    {
                                        if (i%9==0&&i!=0)
                                            lol++;
                                        
                                        if (![[puz substringWithRange:NSMakeRange(i, 1)]isEqualToString:[completedPuz substringWithRange:NSMakeRange(i, 1)]])
                                        {
                                            
                                            
                                            putText(image, [[completedPuz substringWithRange:NSMakeRange(i, 1)] UTF8String] , cv::Point(arrangedPoints[i+lol].x+10, arrangedPoints[i+lol].y+50), FONT_HERSHEY_DUPLEX, 1.8, Scalar(0,0,255));
                                            
                                        }
                                        
                                    }
                                    DetectedFrameCount++;
                                }
                                else
                                {
                                    for (int i=0; i < arrangedPoints.size(); ++i)
                                    {
                                        circle(image, arrangedPoints[i], 10, Scalar(255,4+(i*2.5), i), -1);
                                    }
                                    
                                    if (SampleCount == Samples)
                                    {
                                        processingInQueue=1;
                                        
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            SampleCount = 0;
                                            [self processSampleImages];
                                            NSString *puzzle=@"";
                                            puzzle = [self bestGuessCalc];
                                            
                                            NSString *newPuzzleWithBreaks=@"";
                                            for(int i=0; i<81; ++i)
                                            {
                                                newPuzzleWithBreaks=[newPuzzleWithBreaks stringByAppendingString:[puzzle substringWithRange:NSMakeRange(i, 1) ]];
                                                if ((i+1)%9==0&&i!=0)
                                                {
                                                    newPuzzleWithBreaks=[newPuzzleWithBreaks stringByAppendingString:@"\n"];
                                                }
                                                
                                            }
                                            [self.textField setText:newPuzzleWithBreaks];
                                            [self.lab setText:[NSString stringWithFormat:@"Confidence:%.2f", (float)(confidence / (Samples*81) * 100)]];
                                            if (1)//(float)(confidence / (Samples*81) * 100)) {
                                            {
                                                [self solve:NULL];
                                            }
                                            confidence = 0;
                                            processingInQueue=0;
                                            AskToAim=1;
                                            SampleImage.clear();
                                            SamplePoints.clear();
                                        });
                                    }
                                    else if(!processingInQueue) {
                                        SampleCount++;
                                        SampleImage.push_back(image.clone());
                                        SamplePoints.push_back(arrangedPoints);
                                    }
                                }
                            }
                        }
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.lab setText:[NSString stringWithFormat:@"Just Right. Hold Still."]];
                    });
                }
            }
        }
        else if(AskToAim)
        {
            if (isSolved)
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.lab setText:[NSString stringWithFormat:@"Woooooo!!! Solved. Aim at puzzle again."]];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 4 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    AskToAim = 0;
                });
            });
            else
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.lab setText:[NSString stringWithFormat:@"Puzzle Couldn't be solved. Aim at puzzle again."]];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 4 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                        AskToAim = 0;
                    });
                });
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.lab setText:[NSString stringWithFormat:@"Aim at Puzzle."]];
            });
        }
        arrangedPoints.clear();
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.lab setText:[NSString stringWithFormat:@"Aim at Puzzle. And Keep Device Straight"]];
        });
    }
   
}
- (void)viewDidLoad {
    [super viewDidLoad];
    //    const char *puz = "390002006050086000200000003030700000001060800000001090400000007000430050800600032";//[[[textField text] stringByReplacingOccurrencesOfString:@"\n" withString:@""] UTF8String];
    
    self.textField.delegate = self;
    self.videoCamera = [[CvVideoCamera alloc] initWithParentView:imageView];
    
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset1280x720;
    self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    self.videoCamera.defaultFPS = 30;
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    self.videoCamera.delegate = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self.videoCamera start];
    });
    //
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}
bool Reset=NO;

- (IBAction)ToggleView:(UIButton *)sender {
    
    
    
    
    if (ContainerView.hidden == YES) {
        [ContainerView setHidden:NO];
        [UIView animateWithDuration:.5f animations:^{
            
            
            [ContainerView setAlpha:1.0f];
            
        } completion:nil];
    }
    else
    {
        [UIView animateWithDuration:.5f animations:^{
            
            [ContainerView setAlpha:0.0f];
            
        } completion:^(BOOL finished) {
            [ContainerView setHidden:YES];
        }];
        
    }
    
}

- (IBAction)TapToStartVid:(UITapGestureRecognizer *)sender {

}

- (IBAction)startProcessing:(id)sender {
    
    
    
    
    [self.videoCamera start];
    
    
    frames = 0;
    tolerance = 2;
    toleranceC=0;
    SampleCount=0;
    Samples = SampleDigitsCount;
    confidence = 0;
    SampleDigits.clear();
    if(isSolved==1)
    {
        [lab setText:@"Puzzle Reset"];
        isSolved = 0;
        [textField setText:@"000000000\n000000000\n000000000\n000000000\n000000000\n000000000\n000000000\n000000000\n000000000\n"];
    }
    
    DetectedFrameCount = 0;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}


- (IBAction)solve:(id)sender
{
    const char *puz = [[[textField text] stringByReplacingOccurrencesOfString:@"\n" withString:@""] UTF8String];
    GetPuz(puz);
    @try {
        isSolved = theMain();
    }
    
    @catch ( NSException *e ) {
        isSolved=0;
        cout << "\\  OoO  /";
    }
    
    
    if (isSolved) {
        [lab setText:@"Puzzle Solved!"];
    }
    else
    {
        [lab setText:@"Puzzle not solved!"];
    }
    tolerance=20;
}
- (IBAction)ToggleDrawer:(UIButton *)sender {
    if (ContainerView.hidden == YES) {
        ContainerView.hidden = NO;
    }
    else ContainerView.hidden = YES;
}
@end
