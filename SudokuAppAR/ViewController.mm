//
//  ViewController.m
//  SudokuAppAR
//
//  Created by Satej Mhatre on 12/24/15.
//  Copyright © 2015 Satej Mhatre. All rights reserved.
//

#import "ViewController.h"
#include "SudokuSolver.h"
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
float Samples = 5;
float confidence = 0;
int isSolved = 0;
int DetectedFrames = 100;
int DetectedFrameCount=0;

bool compareYX(const cv::Point& left, const cv::Point& right) {
    return (left.y < right.y) || ((left.y == right.y) && (left.x < right.x));
}

-(cv::Point)sectionFormula: (cv::Point)P1 Point2: (cv::Point)P2 Division:(cv::Point)MN
{
    return cv::Point(((MN.x*P2.x + MN.y*P1.x)/(MN.x+MN.y)),(MN.x*P2.y + MN.y*P1.y)/(MN.x+MN.y));
}
vector<NSString*> SampleDigits;

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
    //cvtColor(res, res2, COLOR_GRAY2BGR);
    return res;
}
int mode (int x[],int n)
{
    int y[5]={0};//Sets all arrays equal to 0
    int i,j,k,m,cnt,max=0,no_mode=0,mode_cnt=0;
    double num;
    
    for(k=0; k<n; k++)//Loop to count an array from left to right
    {
        cnt=0;
        num=x[k];//Num will equal the value of array x[k]
        
        for(i=k; i<n; i++)//Nested loop to search for a value equal to x[k]
        {
            if(num==x[i])
                cnt++;//if a number is found that is equal to x[k] count will go up by one
            
        }
        y[k]=cnt;//The array y[k] is initialized the value of whatever count is after the nested loop
        if(cnt>=2)//If cnt is greater or equal to two then there must be atleast one mode, so no_mode goes up by one
        {
            no_mode++;
        }
    }
    
    if(no_mode==0)//after the for loops have excuted and still no_mode hasn't been incremented, there mustn't be a mode
    {
        //Print there in no mode and return control to main
        //cout<<"This data set has no modes\n"<<endl;
        confidence =0;
        return 0;
    }
    for(j=0; j<n; j++)
        //A loop to find the highest number in the array
    {
        if(y[j]>max)
            max=y[j];
    }
    for(m=0; m<n; m++)//This loop finds how many modes there are in the data set
    {
        //If the max is equal to y[m] then that is a mode and mode_cnt is incremeted by one
        if(max==y[m])
            mode_cnt++;
    }
    //cout<<"This data set has "<<mode_cnt<<" mode(s)"<<endl;//Prints out how many modes there are
    
    for(m=0; m<n; m++)
    {
        if(max==y[m])//If max is equal to y[m] then the same sub set of array x[] is the actual mode
        {
            
            //cout<<"The value "<<x[m]<<" appeared "<<y[m]<<" times in the data set\n"<<endl;
        }
    }
    confidence += y[0];
    return x[0];
}

-(NSString*) bestGuessCalc
{
    NSString* bestGuess = @"";
    int arr[5];
    
    for (int i = 0; i < SampleDigits[0].length ; ++i)
    {
        
        for (int j = 0; j < SampleDigits.size(); ++j)
        {
            arr[j] = [[SampleDigits[j] substringWithRange:NSMakeRange(i, 1)] intValue];
            
        }
        bestGuess = [bestGuess stringByAppendingString:[NSString stringWithFormat:@"%d", mode(arr, 5)]];
        
        
    }
    SampleDigits.clear();
    return bestGuess;
}

- (void)processImage:(Mat&)image
{
    Mat img = image, thr, mask , kerx, kery, dx, dy, ret, close, closex, closey;
    
    cv::Rect rec;
    
    Mat org = img.clone();
    
    
    cv::String a;
    vector<cv::Point> arrangedPoints, AllArrangedPoints, cen;
    resize(img, img, cv::Size(320,240));
    mask = [self MaskContour: img];
    GaussianBlur(img, img, cv::Size(3,3), 0);
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
    
    //image = mask;
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
        if (rec.height/rec.width > 3 && rec.area() > 300) {
            drawContours(close, contours, i, Scalar(255,255,255), -1);
        }
        else{
            drawContours(close, contours, i, 0, -1);
        }
    }
    
    
    morphologyEx(close, close, MORPH_OPEN, NULL, cv::Point(-1,-1), 2);
    //GaussianBlur(close, close, cv::Size(7,7), 0);
    normalize(close, close, 0,255, NORM_MINMAX);
    cv::Mat temp1;
    GaussianBlur(close, temp1, cv::Size(7,7), 0);
    cv::addWeighted(close, 1.5, temp1, -0.5, 0, close);
    morphologyEx(close, close, MORPH_CLOSE, NULL, cv::Point(-1,-1), 4);
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
        if (rec.width/rec.height > 3 && rec.area() > 100) {
            drawContours(close, contours, i,Scalar(255,255,255),-1);
        }
        else{
            drawContours(close, contours, i, 0, -1);
        }
    }
    morphologyEx(close, close, MORPH_OPEN, NULL, cv::Point(-1,-1), 2);
    //GaussianBlur(close, close, cv::Size(7,7), 0);
    normalize(close, close, 0,255, NORM_MINMAX);
    GaussianBlur(close, temp1, cv::Size(7,7), 0);
    cv::addWeighted(close, 1.5, temp1, -0.5, 0, close);
    morphologyEx(close, close, MORPH_CLOSE, NULL, cv::Point(-1,-1), 4);
    close.copyTo(closey);
    bitwise_and(closex,closey, res);
    morphologyEx(res, res, MORPH_OPEN
                 , NULL, cv::Point(-1,-1), 1);
    
    
    findContours(res, contours, hierarchy, CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE);
    
    
    for (int i=0; i<contours.size(); ++i) {
        {  cv::Moments m = moments(contours[i]);
            cv::Point P = cv::Point(int(m.m10/m.m00), int(m.m01/m.m00));
            circle(org, cv::Point(P.x*2, P.y*2), 4, Scalar(255,255,0), -1);
            cen.push_back(P);
        }
    }
    morphologyEx(res, res, MORPH_OPEN, NULL, cv::Point(-1,-1), 4);
    image = org
    ;
    //image ;
    std::sort(cen.begin(), cen.end(), compareYX);
    if(cen.size()>0)
    cout << cen[0].x << " " << cen[0].y <<endl;
    
    
    NSString* a1, *puzzle=@"";
    if(cen.size()==16)
        
    {
        for(int i=0; i<10; ++i)
        {
            for (int j = 0; j < 10; ++j) {
                arrangedPoints.push_back(cv::Point(15+j*27.67,37+i*27.67));
            }
        }
        if (isSolved) {
            if (DetectedFrameCount < DetectedFrames) {
                NSString *completedPuz = [NSString stringWithCString:getStringCompleted() encoding:NSASCIIStringEncoding];
                NSString *puz = [[textField text] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                int lol=0;
                for(int i=0; i < 81; ++i)
                {
                    if (i%9==0&&i!=0) {
                        lol++;
                    }
                    if (![[puz substringWithRange:NSMakeRange(i, 1)]isEqualToString:[completedPuz substringWithRange:NSMakeRange(i, 1)]]) {
                        
                        
                        putText(img, [[completedPuz substringWithRange:NSMakeRange(i, 1)] UTF8String] , cv::Point(arrangedPoints[i+lol].x+10, arrangedPoints[i+lol].y+20), FONT_HERSHEY_DUPLEX, 0.5, Scalar(0,0,255));
                        
                    }
                    
                }
                DetectedFrameCount++;
            }
            else DetectedFrameCount = 0;
        }
        else
        {
            if (cen[0].x > 15-tolerance && cen[0].x < 15+tolerance && cen[0].y > 37-tolerance && cen[0].y < 37+tolerance
                //&& cen[3].x > 264-tolerance && cen[03].x < 264+tolerance && cen[03].y > 37-tolerance && cen[03].y < 37+tolerance
                //&& cen[012].x > 15-tolerance && cen[012].x < 15+tolerance && cen[012].y > 286-tolerance && cen[012].y < 286+tolerance
                //&& cen[015].x > 264-tolerance && cen[015].x < 264+tolerance && cen[015].y > 286-tolerance && cen[015].y < 286+tolerance
                ) {
                
                for(int i=0; i<10; ++i)
                {
                    for (int j = 0; j < 10; ++j) {

                            circle(img, cv::Point(15+j*27.67,37+i*27.67), 4, Scalar(255,255,0), -1);
                        
                        
                        
                    }
                }
                
                
                
                if(!isSolved){
                    
                    //                for(int i=0; i<AllArrangedPoints.size(); ++i)
                    //                {
                    //                    a.operator=(i+65);
                    //                    putText(img, a, AllArrangedPoints[i], FONT_HERSHEY_PLAIN, 1, Scalar(255,255,255));
                    //                    circle(img, AllArrangedPoints[i], 2, Scalar(255,0,0), -1);
                    //
                    //                }
                    image = img;
                    G8Tesseract *tesseract = [[G8Tesseract alloc] initWithLanguage:@"eng"];
                    cv::Mat tmp;
                    cv::GaussianBlur(org, tmp, cv::Size(5,5), 5);
                    cv::addWeighted(org, 1.5, tmp, -0.5, 0, org);
                    
                    tesseract.charWhitelist = @"0123456789";
                    [tesseract setImage:[[UIImage imageWithCVMat:[self NormalizeImage:org]] g8_blackAndWhite]];
                    
                    for(int i=0; i < 90; ++i)
                    {
                        
                        
                        tesseract.rect = CGRectMake(CGFloat(arrangedPoints[i].x+7), CGFloat(arrangedPoints[i].y+5), 13.67, 20.67);
                        [tesseract recognize];
                        a1 = [tesseract recognizedText];
                        a1 = [a1 stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                        a1 = [a1 stringByReplacingOccurrencesOfString:@" " withString:@""];
                        if ((i+1)%10==0 && i!=0 && i!=90) {
                            puzzle=[puzzle stringByAppendingString:@""];
                            
                            continue;
                        }
                        if ([a1 length]==0) {
                            puzzle=[puzzle stringByAppendingString:@"0"];
                        }
                        else puzzle=[puzzle stringByAppendingString:[a1 substringWithRange:NSMakeRange(0, 1)]];
                        
                        
                        
                    }
                    
                    if (SampleCount == Samples) {
                        SampleCount = 0;
                        puzzle = [self bestGuessCalc];
                        NSString *newPuzzleWithBreaks=@"";
                        for(int i=0; i<81; ++i)
                        {
                            newPuzzleWithBreaks=[newPuzzleWithBreaks stringByAppendingString:[puzzle substringWithRange:NSMakeRange(i, 1) ]];
                            if ((i+1)%9==0&&i!=0) {
                                newPuzzleWithBreaks=[newPuzzleWithBreaks stringByAppendingString:@"\n"];
                            }
                            
                        }
                        dispatch_async(dispatch_get_main_queue(), ^{
                            
                            [self.textField setText:newPuzzleWithBreaks];
                            [self.lab setText:[NSString stringWithFormat:@"Confidence:%.2f", (float)(confidence / (Samples*81) * 100)]];
                            if ((float)(confidence / (Samples*81) * 100) > 97) {
                                [self solve:NULL];
                            }
                            confidence = 0;
                        });
                    }
                    else {
                        SampleCount++;
                        SampleDigits.push_back(puzzle);
                        
                    }
                    
                    
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        [self.detectedGrid setImage:[UIImage imageWithCGImage:CGImageCreateWithImageInRect([[UIImage imageWithCVMat:org] CGImage], CGRectMake(CGFloat(arrangedPoints[53].x+7), CGFloat(arrangedPoints[53].y+5), 13.67, 20.67)) ]];
                        
                        
                    });
                    
                    
                    
                    
                    
                }
                else
                {
                    
                    
                }
            }
            
            else
            {
                a="Put Top Left Corner Here";
                putText(img, a, cv::Point(15,37), FONT_HERSHEY_PLAIN, 1, Scalar(255,255,255));
                circle(img, cv::Point(15,37), 4, Scalar(255,255,0), -1);
                
                a = "Put Corner Here";
                putText(img, a, cv::Point(150,67), FONT_HERSHEY_PLAIN, 1, Scalar(255,255,255));
                circle(img, cv::Point(264,37), 4, Scalar(255,255,0), -1);
                
                a = "Blah";
                putText(img, a, cv::Point(15,310), FONT_HERSHEY_PLAIN, 1, Scalar(255,255,255));
                circle(img, cv::Point(15,286), 4, Scalar(255,255,0), -1);
                
                a="And Bottom Right Corner Here";
                putText(img, a, cv::Point(25,264), FONT_HERSHEY_PLAIN, 1, Scalar(255,255,255));
                circle(img, cv::Point(264,286), 4, Scalar(255,255,0), -1);
            }
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
    //    const char *puz = "390002006050086000200000003030700000001060800000001090400000007000430050800600032";//[[[textField text] stringByReplacingOccurrencesOfString:@"\n" withString:@""] UTF8String];
    //    GetPuz(puz);
    //    theMain();
    self.textField.delegate = self;
    self.videoCamera = [[CvVideoCamera alloc] initWithParentView:imageView];
    
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset1920x1080;
    self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    self.videoCamera.defaultFPS = 30;
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    self.videoCamera.delegate = self;

    //[self.videoCamera start];

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

- (IBAction)startProcessing:(id)sender {
    
   
    
    
    [self.videoCamera start];
    [self ToggleDrawer:NULL];
    
    frames = 0;
    tolerance = 2;
    toleranceC=0;
    SampleCount=0;
    Samples = 5;
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


//-(void)key
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
