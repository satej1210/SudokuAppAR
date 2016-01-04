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
    int y[SampleDigitsCount]={0};//Sets all arrays equal to 0
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
    int arr[1];
    
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
        for (int i = 0; i < 4; ++i) {
            if (points[i].x < sectionsMax[j].x
                && points[i].y < sectionsMax[j].y
                && points[i].x > sectionsMin[j].x
                && points[i].y > sectionsMin[j].y
                ) {
                thePoint.x = points[i].x;
                thePoint.y = points[i].y;
            }
        }
        newCen.push_back(thePoint);
    }
    return newCen;
    
}
Mat warp(Mat inputMat,Mat startM) {
    int resultWidth = 1000;
    int resultHeight = 1000;
    
    Mat outputMat = Mat(resultWidth, resultHeight, CV_8UC4);
    
    
    
    cv::Point ocvPOut1 =  cv::Point(0, 0);
    cv::Point ocvPOut2 =  cv::Point(0, resultHeight);
    cv::Point ocvPOut3 =  cv::Point(resultWidth, resultHeight);
    cv::Point ocvPOut4 =  cv::Point(resultWidth, 0);
    vector<cv::Point> dest(4);
    dest.push_back(ocvPOut1);
    dest.push_back(ocvPOut2);
    dest.push_back(ocvPOut3);
    dest.push_back(ocvPOut4);
    Mat endM = Mat(dest);
    
    Mat perspectiveTransform = getPerspectiveTransform(startM, endM);
    
    warpPerspective(inputMat,
                    outputMat,
                    perspectiveTransform,
                    cv::Size(resultWidth, resultHeight),
                    INTER_CUBIC);
    
    return outputMat;
}
- (void)processImage:(Mat&)image
{
    Mat img = image,  org = image.clone(), thr, mask , kerx, kery, dx, dy, ret, close, closex, closey;
    cv::Rect rec;
    cv::String a;
    vector<cv::Point> arrangedPoints, AllArrangedPoints, cen;
    resize(img, img, cv::Size(270, 480));
    mask = [self MaskContour: img];
    GaussianBlur(img, img, cv::Size(1,1), 0);
    Mat res = [self NormalizeImage:img];
    //image = org;
    
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
    if ([[UIDevice currentDevice] orientation] == 1 || [[UIDevice currentDevice] orientation] == 5) {
        
        
        if (largest_area > 30000) {
            
            
            //bitwise_and(res, mask, res);
            vector<cv::Point>approx;
            vector<RotatedRect> rotatedRect;
            if (contours.size() > 0) {
                rec = boundingRect(contours[largest_contour_index]);
                
                approxPolyDP(Mat(contours[largest_contour_index]), approx,
                             arcLength(Mat(contours[largest_contour_index]), true)*0.02, true);
                
                if (approx.size() == 4 &&
                    fabs(contourArea(Mat(approx))) > 1000 &&
                    isContourConvex(Mat(approx)) && largest_area < 70000)
                {
                    double maxCosine = 0;
                    
                    for( int j = 2; j < 5; j++ )
                    {
                        double cosine = fabs(angle(approx[j%4], approx[j-2], approx[j-1]));
                        maxCosine = MAX(maxCosine, cosine);
                    }
                    
                    if( maxCosine < 0.3  )
                    {
                        vector<cv::Point> corners;
                        goodFeaturesToTrack(mask, corners, 4, 0.01, 30);
                        
                        
                        //cout << "Square found";
                        if (largest_area < 40000) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                
                                
                                [self.lab setText:[NSString stringWithFormat:@"Go Closer"]];
                                
                            });
                        }
                        else if (largest_area > 55000 && !isSolved)
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
                            //std::sort(cen.begin(), cen.end(), compareYX);
                            newCen = sortThisMyWay(cen);
                            
                            
                            //cout << cen.size() << " ";
                            for (int i = 0; i < newCen.size(); ++i) {
                                a = "(";
                                a += to_string((newCen[i].x));
                                a += ",";
                                a += to_string((newCen[i].y));
                                a += ");";
                                
                                
                                //putText(image,a, cv::Point((newCen[i].x+2)*2.66667, (newCen[i].y+2)*2.66667), FONT_HERSHEY_PLAIN, 4, Scalar(255,255,255));
                                cout << newCen[i] << " ";
                            }
                            cout << endl;
                            NSString* a1, *puzzle=@"";
                            if(cen.size()==4)
                                
                            {
                                
                                for(int i=0; i<1; ++i)
                                {
                                    // for (int k = 0; k < 3; ++k) {
                                    arrangedPoints.push_back(newCen[i]);
                                    for (int j = 1; j < 9; ++j) {
                                        arrangedPoints.push_back([self sectionFormula:newCen[i] Point2:newCen[i+1] Division:cv::Point(j, 9-j)]);
                                    }
                                    arrangedPoints.push_back(newCen[i+1]);
                                    for (int l = 0; l < 8; ++l) {
                                        cv::Point temp1 = [self sectionFormula:newCen[i] Point2:newCen[i+2] Division:cv::Point(1+l,8-l)];
                                        arrangedPoints.push_back(temp1);
                                        cv::Point temp2 = [self sectionFormula:newCen[i+1] Point2:newCen[i+3] Division:cv::Point(1+l,8-l)];
                                        for (int j=1; j < 9; ++j) {
                                            arrangedPoints.push_back([self sectionFormula:temp1 Point2:temp2 Division:cv::Point(j, 9-j)]);
                                        }
                                        arrangedPoints.push_back(temp2);
                                        

                                    }
                                    arrangedPoints.push_back(newCen[i+2]);
                                    for (int j = 1; j < 9; ++j) {
                                        arrangedPoints.push_back([self sectionFormula:newCen[i+2] Point2:newCen[i+3] Division:cv::Point(j, 9-j)]);
                                    }
                                    arrangedPoints.push_back(newCen[i+2]);
                                    //arrangedPoints.push_back(cv::Point(15+j*27.67,37+i*27.67));
                                    //}
                                }
                                for (int i=0; i < arrangedPoints.size(); ++i) {
                                    arrangedPoints[i] = cv::Point((arrangedPoints[i].x+2)*2.66667, (arrangedPoints[i].y+2)*2.66667);
                                }
                                
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    
                                    [self.detectedGrid setImage:[UIImage imageWithCGImage:CGImageCreateWithImageInRect([[UIImage imageWithCVMat:image] CGImage], CGRectMake(CGFloat(arrangedPoints[7].x+10), CGFloat(arrangedPoints[7].y+10), 50, 45)) ]];
                                    
                                    
                                });
                                
                                if (isSolved) {
                                    //if (DetectedFrameCount < DetectedFrames) {
                                        NSString *completedPuz = [NSString stringWithCString:getStringCompleted() encoding:NSASCIIStringEncoding];
                                        NSString *puz = [[textField text] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                                        int lol=0;
                                        for(int i=0; i < 81; ++i)
                                        {
                                            if (i%9==0&&i!=0) {
                                                lol++;
                                            }
                                            if (![[puz substringWithRange:NSMakeRange(i, 1)]isEqualToString:[completedPuz substringWithRange:NSMakeRange(i, 1)]]) {
                                                
                                                
                                                putText(image, [[completedPuz substringWithRange:NSMakeRange(i, 1)] UTF8String] , cv::Point(arrangedPoints[i+lol].x+10, arrangedPoints[i+lol].y+50), FONT_HERSHEY_DUPLEX, 1.8, Scalar(0,0,255));
                                                
                                            }
                                            
                                        }
                                        DetectedFrameCount++;
                                    
                                   // else DetectedFrameCount = 0;
                                }
                                else
                                {
                                    //if (cen[0].x > 15-tolerance && cen[0].x < 15+tolerance && cen[0].y > 37-tolerance && cen[0].y < 37+tolerance
                                        //&& cen[3].x > 264-tolerance && cen[03].x < 264+tolerance && cen[03].y > 37-tolerance && cen[03].y < 37+tolerance
                                        //&& cen[012].x > 15-tolerance && cen[012].x < 15+tolerance && cen[012].y > 286-tolerance && cen[012].y < 286+tolerance
                                        //&& cen[015].x > 264-tolerance && cen[015].x < 264+tolerance && cen[015].y > 286-tolerance && cen[015].y < 286+tolerance
                                   //     )
                                    {
                                        
                                       

                                        
                                        
                                        for (int i=0; i < arrangedPoints.size(); ++i) {
                                            circle(image, arrangedPoints[i], 10, Scalar(255,1+(i*60), 0), -1);
                                        }
                                        if(!isSolved){
                                          
                                            
                                            //                for(int i=0; i<AllArrangedPoints.size(); ++i)
                                            //                {
                                            //                    a.operator=(i+65);
                                            //                    putText(img, a, AllArrangedPoints[i], FONT_HERSHEY_PLAIN, 1, Scalar(255,255,255));
                                            //                    circle(img, AllArrangedPoints[i], 2, Scalar(255,0,0), -1);
                                            //
                                            //                }
                                            //image = img;
                                            
                                            if (SampleCount == Samples) {
                                                SampleCount = 0;
                                                G8Tesseract *tesseract = [[G8Tesseract alloc] initWithLanguage:@"eng"];
                                                cv::Mat tmp;
                                                cv::GaussianBlur(org, tmp, cv::Size(5,5), 5);
                                                cv::addWeighted(org, 1.5, tmp, -0.5, 0, org);
                                                
                                                tesseract.charWhitelist = @" 0123456789";
                                                [tesseract setImage:[[UIImage imageWithCVMat:[self NormalizeImage:image]] g8_blackAndWhite]];
                                                
                                                for(int i=0; i < 90; ++i)
                                                {
                                                    
                                                    if((i+1)%10!=0 || i==0){
                                                        tesseract.rect = CGRectMake(CGFloat(arrangedPoints[i].x+10), CGFloat(arrangedPoints[i].y+10), 40, 40);
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
                                                    
                                                    
                                                }

                                                //puzzle = [self bestGuessCalc];
                                                cout<<puzzle;
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
                                                    if (1)//(float)(confidence / (Samples*81) * 100)) {
                                                    {
                                                        [self solve:NULL];
                                                    }
                                                    confidence = 0;
                                                });
                                            }
                                            else {
                                                SampleCount++;
                                                SampleDigits.push_back(puzzle);
                                                
                                            }
                                            
                                            
                                            
                                            
                                            
                                            
                                            
                                            
                                            
                                        }
                                        else
                                        {
                                            
                                            
                                        }
                                    }
                                    
//                                    else
//                                    {
//                                        a="Put Top Left Corner Here";
//                                        putText(img, a, cv::Point(15,37), FONT_HERSHEY_PLAIN, 1, Scalar(255,255,255));
//                                        circle(img, cv::Point(15,37), 4, Scalar(255,255,0), -1);
//                                        
//                                        a = "Put Corner Here";
//                                        putText(img, a, cv::Point(150,67), FONT_HERSHEY_PLAIN, 1, Scalar(255,255,255));
//                                        circle(img, cv::Point(264,37), 4, Scalar(255,255,0), -1);
//                                        
//                                        a = "Blah";
//                                        putText(img, a, cv::Point(15,310), FONT_HERSHEY_PLAIN, 1, Scalar(255,255,255));
//                                        circle(img, cv::Point(15,286), 4, Scalar(255,255,0), -1);
//                                        
//                                        a="And Bottom Right Corner Here";
//                                        putText(img, a, cv::Point(25,264), FONT_HERSHEY_PLAIN, 1, Scalar(255,255,255));
//                                        circle(img, cv::Point(264,286), 4, Scalar(255,255,0), -1);
//                                    }
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
                            
                            dispatch_async(dispatch_get_main_queue(), ^{
                                
                                
                                [self.lab setText:[NSString stringWithFormat:@"Just Right. Hold Still."]];
                                
                            });
                            
                            
                        }
                        
                    }
                    //cout << rec.x << " - " << rec.y << " " << "w" << rec.width << " h" << rec.height << " " << largest_area << " " << endl;
                    //image = warp(image, );
                    /*circle(image, cv::Point((rec.tl().x+2)*2.66667, (rec.tl().y+2)*2.66667), 10, Scalar(255,255,0), -1);
                     
                     circle(image, cv::Point((rec.x+rec.width)*2.66667, (rec.y+2)*2.66667), 10, Scalar(255,255,0), -1);
                     circle(image, cv::Point((rec.x+2)*2.66667, (rec.y+rec.height)*2.66667), 10, Scalar(255,255,0), -1);
                     circle(image, cv::Point((rec.br().x)*2.66667, (rec.br().y)*2.66667), 10, Scalar(255,255,0), -1);*/
                    
                }
                
                
                
                
            }
            
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                
                [self.lab setText:[NSString stringWithFormat:@"Aim at Puzzle."]];
                
            });
        }
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            
            [self.lab setText:[NSString stringWithFormat:@"Aim at Puzzle. And Keep Device Straight"]];
            
        });
    }
    /*
     Debug Data -
     1080x1920:
     Square found58 - 306 w600 h595 342367
     Square found59 - 305 w601 h595 342602
     Square found60 - 305 w601 h594 342503
     Square found60 - 304 w601 h595 342659
     Square found59 - 303 w601 h595 342598
     Square found59 - 304 w600 h595 342598
     Square found59 - 303 w601 h595 343133
     Square found61 - 298 w601 h597 344171
     
     270x480:
     Square found32 - 68 w415 h129 51643
     Square found32 - 68 w414 h129 51559
     Square found34 - 68 w414 h130 51532
     Square found34 - 68 w415 h130 51630
     Square found34 - 68 w414 h130 51614
     Square found37 - 69 w413 h129 51569
     Square found39 - 69 w413 h129 51449
     Square found41 - 69 w414 h130 51487
     Square found40 - 68 w415 h131 51600
     Square found37 - 68 w415 h130 51778
     Square found34 - 68 w416 h130 51893
     
     
     */
    /*
     Nice code to detect lines but too jittery
     
     kerx=getStructuringElement(MORPH_RECT, cv::Size(slider1.value,slider2.value));
     
     
     Sobel(res, dx, CV_16S, 1, 0);
     
     convertScaleAbs(dx, dx);
     
     normalize(dx, dx, 0,255, NORM_MINMAX);
     
     
     ret = threshold(dx, close, 0, 255, THRESH_BINARY+THRESH_OTSU);
     morphologyEx(close, close, MORPH_CLOSE, kerx, cv::Point(-1,-1), 4);
     
     findContours(close, contours, hierarchy, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_SIMPLE);
     
     for(int i=0; i<contours.size(); ++i)
     {
     rec = boundingRect(contours[i]);
     if (rec.height/rec.width > slider3.value) {
     drawContours(close, contours, i, Scalar(255,255,255), -1);
     }
     else{
     drawContours(close, contours, i, 0, -1);
     }
     }
     
     
     morphologyEx(close, close, MORPH_DILATE, NULL, cv::Point(-1,-1), 2);
     
     
     close.copyTo(closex);
     //image = closex;
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
     
     */
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
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset1280x720;
    self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    self.videoCamera.defaultFPS = 30;
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    self.videoCamera.delegate = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
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
    //[self.videoCamera start];
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
