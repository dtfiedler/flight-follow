// Put OpenCV include files at the top. Otherwise an error happens.
#import <vector>
#import <opencv2/opencv.hpp>
#import <opencv2/imgproc.hpp>
#import <opencv2/highgui/highgui.hpp>
#import <Foundation/Foundation.h>
#import "OpenCV.h"

// ***********************************************************
//  THIS CODE WAS ADAPTED FROM ORIGINAL CODE CREATED BY Hiroki Ishiura
//  Created by  on 2015/08/12.
//  Copyright (c) 2015年 Hiroki Ishiura. All rights reserved.

/// Converts an UIImage to Mat.
/// Orientation of UIImage will be lost.
static void UIImageToMat(UIImage *image, cv::Mat &mat) {
	
	// Create a pixel buffer.
	NSInteger width = CGImageGetWidth(image.CGImage);
	NSInteger height = CGImageGetHeight(image.CGImage);
	CGImageRef imageRef = image.CGImage;
	cv::Mat mat8uc4 = cv::Mat((int)height, (int)width, CV_8UC4);
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef contextRef = CGBitmapContextCreate(mat8uc4.data, mat8uc4.cols, mat8uc4.rows, 8, mat8uc4.step, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault);
	CGContextDrawImage(contextRef, CGRectMake(0, 0, width, height), imageRef);
	CGContextRelease(contextRef);
	CGColorSpaceRelease(colorSpace);
	
	// Draw all pixels to the buffer.
	cv::Mat mat8uc3 = cv::Mat((int)width, (int)height, CV_8UC3);
	cv::cvtColor(mat8uc4, mat8uc3, CV_RGBA2BGR);
	
	mat = mat8uc3;
}

/// Converts a Mat to UIImage.
static UIImage *MatToUIImage(cv::Mat &mat) {
	
	// Create a pixel buffer.
	assert(mat.elemSize() == 1 || mat.elemSize() == 3);
	cv::Mat matrgb;
	if (mat.elemSize() == 1) {
		cv::cvtColor(mat, matrgb, CV_GRAY2RGB);
	} else if (mat.elemSize() == 3) {
		cv::cvtColor(mat, matrgb, CV_BGR2RGB);
	}
	
	// Change a image format.
	NSData *data = [NSData dataWithBytes:matrgb.data length:(matrgb.elemSize() * matrgb.total())];
	CGColorSpaceRef colorSpace;
	if (matrgb.elemSize() == 1) {
		colorSpace = CGColorSpaceCreateDeviceGray();
	} else {
		colorSpace = CGColorSpaceCreateDeviceRGB();
	}
	CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
	CGImageRef imageRef = CGImageCreate(matrgb.cols, matrgb.rows, 8, 8 * matrgb.elemSize(), matrgb.step.p[0], colorSpace, kCGImageAlphaNone|kCGBitmapByteOrderDefault, provider, NULL, false, kCGRenderingIntentDefault);
	UIImage *image = [UIImage imageWithCGImage:imageRef];
	CGImageRelease(imageRef);
	CGDataProviderRelease(provider);
	CGColorSpaceRelease(colorSpace);
	
	return image;
}

/// Restore the orientation to image.
static UIImage *RestoreUIImageOrientation(UIImage *processed, UIImage *original) {
	if (processed.imageOrientation == original.imageOrientation) {
		return processed;
	}
	return [UIImage imageWithCGImage:processed.CGImage scale:1.0 orientation:original.imageOrientation];
}

// END OF ADAPTED CODE
// ***********************************************************


//  Created by  on 2018/15/4.
//  Copyright (c) 2018 Dylan Fiedler. All rights reserved.

#pragma mark -
@implementation OpenCV

std::vector<cv::Point> path;

//returns hte mask of the current frames to show as subview
+ (nonnull UIImage *)getMaskedImage:(nonnull UIImage *)image {
    //deteremine the hue of the color ball you want to track
    cv::Mat originalImage;
    cv::Mat hsvImage;
    cv::Mat threshImage;
    
    //convert image to mat
    UIImageToMat(image, originalImage);
    
    /// Convert Original Image to HSV Threshold Image
    cv::cvtColor(originalImage, hsvImage, CV_BGR2HSV);
    //find ball in color range proivded, right now hard coded to be white
    cv::inRange(hsvImage, cv::Scalar(0, 0, 240), cv::Scalar(255, 15, 255), threshImage);
    //Blur
    cv::GaussianBlur(threshImage, threshImage, cv::Size(3, 3), 0);
    // Dilate
    cv::dilate(threshImage, threshImage, 0);
    // Erode
    cv::erode(threshImage, threshImage, 0);
    //return our masked image
    UIImage *maskedImage = MatToUIImage(threshImage);
    return RestoreUIImageOrientation(maskedImage, image);
}
    

//track the ball based on its color and return to view controller
+ (nonnull UIImage *)trackBallWithColor:(nonnull UIImage *)image:(NSString *)color {
    
    //deteremine the hue of the color ball you want to track
    //we use the HSV to identify where the ball is based on the upport and lower range
    cv::Mat imgOriginal;
    cv::Mat hsvImg;
    cv::Mat threshImg;
    
    //convert image to mat
    UIImageToMat(image, imgOriginal);
    
    //our list of circlees identified based on mask
    std::vector<cv::Vec3f> v3fCircles;

    int sensitivity = 15;
    // Adjust Saturation and Value depending on the lighting condition of the environment as well as the surface of the object.
    cv::cvtColor(imgOriginal, hsvImg, CV_BGR2HSV);      // Convert Original Image to HSV Thresh Image

    //find ball in color range proivded
    cv::inRange(hsvImg, cv::Scalar(0, 0, 255-sensitivity), cv::Scalar(255, sensitivity, 255), threshImg);
    cv::GaussianBlur(threshImg, threshImg, cv::Size(3, 3), 0);   //Blur Effect
    cv::dilate(threshImg, threshImg, 0);        // Dilate Filter Effect
    cv::erode(threshImg, threshImg, 0);         // Erode Filter Effect
    
    try {
        // fill circles vector with all circles in processed image
        cv::HoughCircles(threshImg,v3fCircles,CV_HOUGH_GRADIENT,2,threshImg.rows / 4,100,50,10,800);
        std::cout << v3fCircles.size();
    } catch (...) {
        std::cout << "Unable to find circles";
    }
    
    int i = 0;
    cv::Point center;
    //if not already tracking a circle
    if (v3fCircles.size() > 0){
        int x_position = v3fCircles[i][0];
        int y_position = v3fCircles[i][1];

        // get the center point of the ball
        center = cv::Point((int)v3fCircles[i][0], (int)v3fCircles[i][1]);
        
        // locate the center and draw a green circle
        cv::circle(imgOriginal, center,3, cv::Scalar(0, 255, 0), CV_FILLED);
        
        // draw red circle around object detected
        cv::circle(imgOriginal,            // draw on original image
                   cv::Point((int)v3fCircles[i][0], (int)v3fCircles[i][1]),  // center point of circle
                   (int)v3fCircles[i][2],           // radius of circle in pixels
                   cv::Scalar(0, 0, 255),           // draw circle red
                   3);                // thickness of outline
    
        //add previous center to path
        path.insert(path.begin(), center);
        if (path.size() > 15){
            path.erase(path.end() - 1);
        }
        //draw path on image, only do last 15 locations
        for (int z = 1; z < path.size(); z++){
            cv::line(imgOriginal, path.at(z-1), path.at(z),cv::Scalar(0, 0, 255),3);
        }
    }

    UIImage *outputImage = MatToUIImage(imgOriginal);
    return RestoreUIImageOrientation(outputImage, image);
}

@end
