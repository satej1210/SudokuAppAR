//
//  ViewController.m
//  SudokuAppAR
//
//  Created by Satej Mhatre on 12/24/15.
//  Copyright © 2015 Satej Mhatre. All rights reserved.
//

#import "ViewController.h"
#include "SudokuSolver.h"
#define SampleDigitsCount 8
using namespace cv;
using namespace std;

@interface ViewController ()
{
    CvVideoCamera* videoCamera;
    NSArray *_pickerData;
    
}

@property (nonatomic, retain) CvVideoCamera* videoCamera;
@property (nonatomic, assign) id currentResponder;
@end

@implementation ViewController


@synthesize imageView, videoCamera, detectedGrid, lab, textField, Solved, StartButton, ContainerView,HeightConstraint;
int cellNum=0;
int frames = 0;
int usingVideo=1;
int tolerance = 2;
int cellStep=0;
int toleranceC=0;
int go=0;
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
NSString* globalPuzzle;
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
    
    if (usingVideo) {
        int y[SampleDigitsCount];
        for (int i=0; i < SampleDigitsCount; ++i) {
            y[i] = 0;
        }
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
    else
    {
        return x[0];
    }
    
}

-(NSString*) bestGuessCalc
{
    NSString* bestGuess = @"";
    int SDC;
    if (usingVideo) {
        SDC = SampleDigitsCount;
    }
    else
        SDC = 1;
#define SDCDef SDC
    int arr[SDCDef];
    if(SampleDigits.size()>0){
        for (int i = 0; i < SampleDigits[0].length ; ++i)
        {
            
            for (int j = 0; j < SampleDigits.size(); ++j)
            {
                arr[j] = [[SampleDigits[j] substringWithRange:NSMakeRange(i, 1)] intValue];
                
            }
            bestGuess = [bestGuess stringByAppendingString:[NSString stringWithFormat:@"%d", mode(arr, SDCDef)]];
            
            
        }
        SampleDigits.clear();
    }
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
    vector<cv::Point> sectionsMin, sectionsMax, adjustPoints;
    sectionsMin.push_back(cv::Point(0,0));
    sectionsMax.push_back(cv::Point(135, 240));
    adjustPoints.push_back(cv::Point(2,2));
    
    sectionsMin.push_back(cv::Point(135, 0));
    sectionsMax.push_back(cv::Point(270, 240));
    adjustPoints.push_back(cv::Point(-2,2));
    
    sectionsMin.push_back(cv::Point(0,240));
    sectionsMax.push_back(cv::Point(135, 480));
    adjustPoints.push_back(cv::Point(2,-2));
    
    sectionsMin.push_back(cv::Point(135,240));
    sectionsMax.push_back(cv::Point(270, 480));
    adjustPoints.push_back(cv::Point(-2,-2));
    
    
    cv::Point thePoint;
    for (int j = 0; j < 4; ++j) {
        for (int i = 0; i < points.size(); ++i) {
            if (points[i].x < sectionsMax[j].x
                && points[i].y < sectionsMax[j].y
                && points[i].x > sectionsMin[j].x
                && points[i].y > sectionsMin[j].y
                ) {
                thePoint.x = points[i].x ;//+ adjustPoints[i].x;
                thePoint.y = points[i].y ;//+ adjustPoints[i].y;
                points[i].x = -1;
                points[i].y = -1;
            }
        }
        newCen.push_back(thePoint);
    }
    //cout << newCen << endl;
    return newCen;
    
}

-(void)processSampleImages:(vector<cv::Point>)cen
{
    G8Tesseract *tesseract = [[G8Tesseract alloc] initWithLanguage:@"eng"];
    tesseract.charWhitelist = @" 0123456789";
    cv::Mat tmp;
    NSString* a1, *puzzle=@"";
    int SDC;
    if (usingVideo) {
        SDC = SampleDigitsCount;
    }
    else
        SDC = 1;
    for (int j=0; j<SDC; ++j)
    {
        cv::GaussianBlur(SampleImage[j], tmp, cv::Size(5,5), 5);
        cv::addWeighted(SampleImage[j], 1.5, tmp, -0.5, 0, SampleImage[j]);
        [tesseract setImage:[[UIImage imageWithCVMat:[self NormalizeImage:SampleImage[j]]] g8_blackAndWhite]];
        tesseract.maximumRecognitionTime = 1;
        for(int i=0; i < 90; ++i)
        {
            
            if((i+1)%10!=0 || i==0)
            {
                tesseract.rect = CGRectMake(CGFloat(SamplePoints[j][i].x+20+(cen[3].x-SamplePoints[j][i].x)/81), CGFloat(SamplePoints[j][i].y+15+(cen[3].x-SamplePoints[j][i].y)/81), 30, 40);
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
- (void)progressImageRecognitionForTesseract:(G8Tesseract *)tesseract {
    NSLog(@"progress: %lu", (unsigned long)tesseract.progress);
}
-(vector<vector<cv::Point>>)FindSudokuMask:(cv::Mat&)mask img:(cv::Mat&)img largestIndex:(int&)largest_contour_index largestArea:(int&)largest_area
{
    vector<vector<cv::Point>> contours;
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
    return contours;
}

-(void)SolvedPuzzle: (cv::Mat&)image1 arrangedPts: (vector<cv::Point>) arrangedPoints corners: (vector<cv::Point>)cen

{
    
    vector <cv::Point> arrangedPoints1 = arrangedPoints;
    NSString *completedPuz = [NSString stringWithCString:getStringCompleted() encoding:NSASCIIStringEncoding];
    NSString *puz = [[textField text] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    int lol=0, o=3;
    for(int i=0; i < 81; ++i)
    {
        if (i%9==0&&i!=0)
        {
            lol++;
        }
        
        
        if (![[puz substringWithRange:NSMakeRange(i, 1)]isEqualToString:[completedPuz substringWithRange:NSMakeRange(i, 1)]])
        {
            
            
            putText(image1, [[completedPuz substringWithRange:NSMakeRange(i, 1)] UTF8String] ,
                    cv::Point(arrangedPoints[i+lol].x+12+(cen[o].x-arrangedPoints[i+lol].x)/81, arrangedPoints[i+lol].y+54+(cen[o].y-arrangedPoints[i+lol].y)/81),
                    //cv::Point(38,100),
                    FONT_HERSHEY_DUPLEX, 1.8, Scalar(0,0,255));
            //NSLog(@"%d\n", lol);
            
        }
        
    }
    
}
-(double)MaxCosine:(vector<cv::Point>)approx
{
    double maxCosine = 0;
    for( int j = 2; j < 5; j++ )
    {
        double cosine = fabs(angle(approx[j%4], approx[j-2], approx[j-1]));
        maxCosine = MAX(maxCosine, cosine);
    }
    return maxCosine;
    
}
-(vector<cv::Point>)FindNewCenPoints: (vector<cv::Point>)cen
{
    vector<cv::Point>newCen;
    newCen = sortThisMyWay(cen);
    return newCen;
}
-(cv::Point) computeIntersect:(cv::Vec2f) a b: (cv::Vec2f) b
{
    int x1 = a[0], y1 = a[1], x2 = a[2], y2 = a[3];
    int x3 = b[0], y3 = b[1], x4 = b[2], y4 = b[3];
    
    if (float d = ((float)(x1-x2) * (y3-y4)) - ((y1-y2) * (x3-x4)))
    {
        cv::Point2f pt;
        pt.x = ((x1*y2 - y1*x2) * (x3-x4) - (x1-x2) * (x3*y4 - y3*x4)) / d;
        pt.y = ((x1*y2 - y1*x2) * (y3-y4) - (y1-y2) * (x3*y4 - y3*x4)) / d;
        return pt;
    }
    else
        return cv::Point(-1, -1);
}
-(cv::Point)findNearestIntersection:(cv::Point)point image:(cv::Mat&)img
{
    //    if (point.x>10 && point.y > 10) {
    //
    //        ROI = cv::Rect(point.x-10,point.y-10,100,100);
    //
    //    }
    //    else ROI = cv::Rect(100,100,20,20);
    //    imgPiece = img(ROI);
    
    
    //point = cv::Point((point.x+2)*img.cols/270, (point.y+2)*img.rows/480);
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        //[self.detectedGrid setImage:[UIImage imageWithCVMat:imgPiece]];
        
    });
    return point;
    
}
-(vector<cv::Point>)MakePuzzlePoints:(vector<cv::Point>)newCen image:(cv::Mat&)image
{
    Mat imgPiece = image;
    cv::Rect ROI;
    Canny(imgPiece, imgPiece, 50, 200);
    vector<Vec2f>lines;
    HoughLines(imgPiece, lines, 1, CV_PI/180, 150);
    vector<cv::Point2f>pts;
    cv::Point pt;
    for (int i = 0; i < lines.size(); i++)
    {
        for (int j = i + 1; j < lines.size(); j++)
        {
            pt = [self computeIntersect:lines[i] b:lines[j]];
            if (pt.x >= 0 && pt.y >= 0 && pt.x < image.cols && pt.y < image.rows)
            {
                pts.push_back(pt);
            }
        }
    }
    for( size_t i = 0; i < lines.size(); i++ )
    {
        float rho = lines[i][0], theta = lines[i][1];
        cv::Point pt1, pt2;
        double a = cos(theta), b = sin(theta);
        double x0 = a*rho, y0 = b*rho;
        pt1.x = cvRound(x0 + 1000*(-b));
        pt1.y = cvRound(y0 + 1000*(a));
        pt2.x = cvRound(x0 - 1000*(-b));
        pt2.y = cvRound(y0 - 1000*(a));
        line( image, pt1, pt2, Scalar(0,0,255), 3, CV_AA);
    }
    cout << pts;
    vector<cv::Point>arrangedPoints;
    for(int i=0; i<1; ++i)
    {
        arrangedPoints.push_back(newCen[i]);
        for (int j = 1; j < 9; ++j)
        {
            arrangedPoints.push_back([self findNearestIntersection:[self sectionFormula:newCen[i] Point2:newCen[i+1] Division:cv::Point(j, 9-j)] image:image]);
            
            
            //arrangedPoints.push_back([self sectionFormula:newCen[i] Point2:newCen[i+1] Division:cv::Point(j, 9-j)] );
        }
        arrangedPoints.push_back(newCen[i+1]);
        for (int l = 0; l < 8; ++l)
        {
            cv::Point temp1 = [self sectionFormula:newCen[i] Point2:newCen[i+2] Division:cv::Point(1+l,8-l)];
            arrangedPoints.push_back(temp1);
            cv::Point temp2 = [self sectionFormula:newCen[i+1] Point2:newCen[i+3] Division:cv::Point(1+l,8-l)];
            for (int j=1; j < 9; ++j)
            {
                arrangedPoints.push_back([self findNearestIntersection:[self sectionFormula:temp1 Point2:temp2 Division:cv::Point(j, 9-j)] image:image]);
            }
            arrangedPoints.push_back(temp2);
            
            
        }
        arrangedPoints.push_back(newCen[i+2]);
        for (int j = 1; j < 9; ++j)
        {
            arrangedPoints.push_back([self findNearestIntersection:[self sectionFormula:newCen[i+2] Point2:newCen[i+3] Division:cv::Point(j, 9-j)] image:image]);
        }
        arrangedPoints.push_back(newCen[i+3]);
    }
    for (int i=0; i < arrangedPoints.size(); ++i)
    {
        arrangedPoints[i] = cv::Point((arrangedPoints[i].x+2)*image.cols/270, (arrangedPoints[i].y+2)*image.rows/480);
    }
    return arrangedPoints;
}
-(void) displayDetectedGrid:(Mat)image arrangedPts:(vector<cv::Point>)arrangedPoints corners:(vector<cv::Point>)cen
{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.detectedGrid setImage:[UIImage imageWithCGImage:CGImageCreateWithImageInRect([[UIImage imageWithCVMat:image] CGImage],
                                                                                           CGRectMake(CGFloat(arrangedPoints[cellNum].x+20+(cen[3].x-arrangedPoints[cellNum].x)/81), CGFloat(arrangedPoints[cellNum].y+15+(cen[3].x-arrangedPoints[cellNum].y)/81), 30, 40))]];
        //CGRectMake(CGFloat(arrangedPoints[cellNum].x+5+(arrangedPoints[cellNum+1].x-arrangedPoints[cellNum].x)/9), CGFloat(arrangedPoints[cellNum].y+5+(arrangedPoints[cellNum+1].y-arrangedPoints[cellNum].y)/9), (arrangedPoints[cellNum+1].x-arrangedPoints[cellNum].x-35),(arrangedPoints[cellNum+10].y-10-arrangedPoints[cellNum].y))) ]];
    });
    
}

-(void) SetLabTextOnDispatchQueue:(NSString*)string
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.lab setText:string];
    });
}
-(void) DrawPoints:(Mat&)image pts:(vector<cv::Point>)arrangedPoints
{
    for (int i=0; i < arrangedPoints.size(); ++i)
    {
        circle(image, arrangedPoints[i], 10, Scalar(255,4+(i*2.5), i), -1);
    }
}
-(void) getCornerPoints
{
    
}
- (void)processImage:(Mat&)image
{
    
    
    
    
    if ([[UIDevice currentDevice] orientation] == 1 ||
        [[UIDevice currentDevice] orientation] == 5)
    {
        if (!processingInQueue) {
            
            
            Mat img = image,  org = image.clone(), mask, res;
            int largest_area=0;
            int largest_contour_index=0;
            cv::Rect rec;
            cv::String a;
            vector<vector<cv::Point>> contours;
            vector<cv::Point> arrangedPoints, cen;
            
            contours = [self FindSudokuMask:mask img:img largestIndex:largest_contour_index largestArea:largest_area];
            
            if (largest_area > 30000 && usingVideo && largest_area < 100000 )
            {
                if(go==10){
                    
                    if (contours.size() > 0)
                    {
                        vector<cv::Point>approx;
                        vector<RotatedRect> rotatedRect;
                        rec = boundingRect(contours[largest_contour_index]);
                        
                        approxPolyDP(Mat(contours[largest_contour_index]), approx,
                                     arcLength(Mat(contours[largest_contour_index]), true)*0.02, true);
                        
                        if (approx.size() == 4 &&
                            fabs(contourArea(Mat(approx))) > 1000 &&
                            isContourConvex(Mat(approx)))
                        {
                            double maxCosine = [self MaxCosine:approx];
                            
                            
                            if( maxCosine < 0.3 )
                            {
                                vector<cv::Point> corners;
                                goodFeaturesToTrack(mask, corners, 4, 0.01, 30);
                                
                                if (largest_area < 40000 && usingVideo) {
                                    [self SetLabTextOnDispatchQueue:@"Go Closer"];
                                }
                                
                                else if ((largest_area > 55000 &&
                                          !isSolved) && usingVideo)
                                {
                                    [self SetLabTextOnDispatchQueue:@"Back Up"];
                                }
                                
                                else
                                {
                                    for(int i = 0; i < corners.size(); ++i)
                                    {
                                        cen.push_back(corners[i]);
                                    }
                                    
                                    
                                    if(cen.size()==4)
                                    {
                                        vector<cv::Point>newCen;
                                        cv::Point point;
                                        
                                        newCen = [self FindNewCenPoints:cen];
                                        
                                        arrangedPoints = [self MakePuzzlePoints:newCen image:image];
                                        
                                        [self DrawPoints:image pts:arrangedPoints];
                                        if (processingInQueue&&usingVideo) {
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                [self.lab setText:[NSString stringWithFormat:@"Solving... Please Wait."]];
                                            });
                                        }
                                        else if (!processingInQueue) {
                                            
                                            if(AskToAim)
                                            {
                                                if (isSolved)
                                                {
                                                    [self SetLabTextOnDispatchQueue:@"Woooooo!!! Solved. Aim at puzzle again."];
                                                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                                                        AskToAim = 0;
                                                    });
                                                }
                                                else
                                                {
                                                    [self SetLabTextOnDispatchQueue:@"Puzzle Couldn't be solved. Aim at puzzle again."];
                                                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                                                        AskToAim = 0;
                                                    });
                                                }
                                            }
                                            
                                            if (isSolved) {
                                                [self SolvedPuzzle:image arrangedPts:arrangedPoints corners:newCen];
                                                DetectedFrameCount++;
                                            }
                                            else
                                            {
                                                [self SetLabTextOnDispatchQueue:@"Just Right. Hold Still."];
                                                [self displayDetectedGrid:image arrangedPts:arrangedPoints corners:newCen];
                                                [self DrawPoints:image pts:arrangedPoints];
                                                
                                                if (usingVideo) {
                                                    if ((SampleCount == Samples && !processingInQueue))
                                                    {
                                                        
                                                        processingInQueue=1;
                                                        
                                                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                                            SampleCount = 0;
                                                            [self processSampleImages:newCen];
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
                                                            
                                                            [self solve:NULL];
                                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                                [self.textField setText:newPuzzleWithBreaks];
                                                                //  [self.lab setText:[NSString stringWithFormat:@"Confidence:%.2f", (float)(confidence / (Samples*81) * 100)]];
                                                            });
                                                            
                                                            if (1)//(float)(confidence / (Samples*81) * 100)) {
                                                            {
                                                                
                                                            }
                                                            go=0;
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
                                        else
                                        {
                                            
                                            SampleCount++;
                                            SampleImage.push_back(image.clone());
                                            SamplePoints.push_back(arrangedPoints);
                                            [self processSampleImages:newCen];
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
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                [self.textField setText:newPuzzleWithBreaks];
                                                
                                                cv::Mat l = cvMatFromUIImage(imageView.image);
                                                [self solve:NULL];
                                                if (isSolved) {
                                                    [self SolvedPuzzle:image arrangedPts:arrangedPoints corners:newCen];
                                                    [self displayDetectedGrid:image arrangedPts:arrangedPoints corners:newCen];
                                                    DetectedFrameCount++;
                                                }
                                                
                                            });
                                            
                                            
                                        }
                                    }
                                }
                            }
                            
                        }
                    }
                }
                else{go++;}
            }
            else if(!usingVideo)
            {
                if (largest_area > 30000) {
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
                            double maxCosine = [self MaxCosine:approx];
                            
                            
                            if( maxCosine < 0.3 )
                            {
                                vector<cv::Point> corners;
                                goodFeaturesToTrack(mask, corners, 4, 0.01, 30);
                                
                                
                                
                                for(int i = 0; i < corners.size(); ++i)
                                {
                                    cen.push_back(corners[i]);
                                }
                                vector<cv::Point>newCen;
                                cv::Point point;
                                newCen = sortThisMyWay(cen);
                                
                                if(cen.size()==4)
                                {
                                    arrangedPoints = [self MakePuzzlePoints:newCen image:image];
                                    [self displayDetectedGrid:image arrangedPts:arrangedPoints corners:newCen];
                                    
                                    if (isSolved) {
                                        [self SolvedPuzzle: image arrangedPts:arrangedPoints corners:newCen];
                                        [self.imageView setImage:[UIImage imageWithCVMat:image]];
                                        [self.view layoutIfNeeded];
                                        
                                    }
                                    else{
                                        
                                        
                                        processingInQueue=1;
                                        cv::Mat ip = image.clone();
                                        SampleImage.push_back(ip);
                                        SamplePoints.push_back(arrangedPoints);
                                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                            
                                            [self processSampleImages:newCen];
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
                                            //globalPuzzle = newPuzzleWithBreaks;
                                            
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                [self.textField setText:newPuzzleWithBreaks];
                                                
                                                [self solve:NULL];
                                                
                                                if (isSolved) {
                                                    [lab setText:@"Puzzle Solved!"];
                                                    AudioServicesPlaySystemSound(1352);
                                                    if (!usingVideo) {
                                                        cv::Mat p = cvMatFromUIImage(imageView.image);
                                                        [self processImage:p];
                                                    }
                                                }
                                                //  [self.lab setText:[NSString stringWithFormat:@"Confidence:%.2f", (float)(confidence / (Samples*81) * 100)]];
                                            });
                                            
                                            
                                            confidence = 0;
                                            processingInQueue=0;
                                            AskToAim=1;
                                            SampleImage.clear();
                                            SamplePoints.clear();
                                            
                                            
                                        });
                                    }
                                }
                                
                            }
                        }
                    }
                    
                    
                }
                
            }
            else
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.lab setText:[NSString stringWithFormat:@"Aim at Puzzle."]];
                });
                //                SampleImage.clear();
                //                SampleDigits.clear();
                //                SamplePoints.clear();
            }
            arrangedPoints.clear();
        }
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
    if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera])
    {
        
        self.videoCamera = [[CvVideoCamera alloc] initWithParentView:imageView];
        self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
        self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset1280x720;
        self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
        self.videoCamera.defaultFPS = 30;
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
        [lab setText:@"Aim at cool puzzle or Tap here for overlay view."];
        
        self.videoCamera.delegate = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self.videoCamera start];
        });
    }
    else
    {
        [lab setText:@"Camera not found. Tap here for overlay view."];
        [_ImageViewButton setHidden:NO];
        [self.RTS setOn:NO animated:YES];
        [self.RTS setEnabled:NO];
    }
    [self CellStepper:nil];
    self.textField.delegate = self;
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}
bool Reset=NO;

- (IBAction)ToggleView:(UIButton *)sender {
    
    [self.view layoutIfNeeded];
    
    if (ContainerView.hidden == YES) {
        [ContainerView setHidden:NO];
        HeightConstraint.constant = 210;
        [UIView animateWithDuration:.5f animations:^{
            
            [self.view layoutIfNeeded];
            [ContainerView setAlpha:1.0f];
            
        } completion:nil];
    }
    else
    {
        HeightConstraint.constant = 0;
        [UIView animateWithDuration:.5f animations:^{
            [self.view layoutIfNeeded];
            [ContainerView setAlpha:0.0f];
            
        } completion:^(BOOL finished) {
            [ContainerView setHidden:YES];
        }];
        
    }
    
}

- (IBAction)TapToStartVid:(UITapGestureRecognizer *)sender
{
    [self.view layoutIfNeeded];
    HeightConstraint.constant = 0;
    [UIView animateWithDuration:.5f animations:^{
        [self.view layoutIfNeeded];
        [ContainerView setAlpha:0.0f];
        
    } completion:^(BOOL finished) {
        [ContainerView setHidden:YES];
    }];
}

- (IBAction)startProcessing:(id)sender
{
    
    
    
    if (!usingVideo) {
        [self.videoCamera start];
    }
    
    
    
    frames = 0;
    tolerance = 2;
    toleranceC=0;
    SampleCount=0;
    Samples = SampleDigitsCount;
    confidence = 0;
    SampleDigits.clear();
    SampleImage.clear();
    SamplePoints.clear();
    go=0;
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

- (void)viewDidLayoutSubviews
{
    [_scrollView setContentSize:CGSizeMake(375, 210)];
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
        NSLog(@"%lu", SampleImage.size());
        if (!usingVideo) {
            cv::Mat p = cvMatFromUIImage(imageView.image);
            [self processImage:p];
        }
    }
    else
    {
        [lab setText:@"Puzzle not solved!"];
    }
    tolerance=20;
}
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    
    [picker dismissViewControllerAnimated:YES completion:nil];
    usingVideo = 0;
    [self startProcessing:nil];
    imageView.image = [info objectForKey:UIImagePickerControllerOriginalImage];
    [_ImageViewButton setHidden:YES];
    
    [self.videoCamera stop];
    cv::Mat image = cvMatFromUIImage(imageView.image);
    
    [self processImage:image];
    
    //    SampleDigits.clear();
    //    SampleImage.clear();
    //    SamplePoints.clear();
}
-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)btnGalleryClicked:(id)sender
{
    ipc= [[UIImagePickerController alloc] init];
    ipc.delegate = self;
    ipc.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    
    [self presentViewController:ipc animated:YES completion:nil];
}

- (IBAction)CellStepper:(id)sender {
    
    int step = _RowStep.value - cellNum;
    if (step==1) {
        if (int(cellNum+2) % 10 == 0 ) {
            _RowStep.value+=1;
        }
    }
    else {
        if (int(cellNum-2) % 10 == 0 ) {
            _RowStep.value-=1;
        }
    }
    cellNum = _RowStep.value;
    cellStep = 1;
    NSLog(@"%d, %f \n",int(_RowStep.value)%10, _RowStep.stepValue);
    if (!usingVideo)
    {
        cv::Mat img = cvMatFromUIImage(imageView.image);
        [self processImage:img];
    }
    
}
- (IBAction)RealTimeSwitch:(UISwitch*)sender {
    if (sender.on) {
        usingVideo = 1;
        [_Photos setEnabled:NO];
        [self.imageView setImage:NULL];
        [self.videoCamera start];
    }
    else
    {
        [_Photos setEnabled:YES];
        [self.videoCamera stop];
        usingVideo=0;
    }
}

@end
