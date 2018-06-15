//
//  OpenCV.h
//  OpenCVSample_iOS
//
//  Created by Dylan Fiedler on 2018/15/4
//  Copyright (c) 2018 Dylan Fiedler. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OpenCV : NSObject

//show mask on imageview
+ (nonnull UIImage *)getMaskedImage:(nonnull UIImage *)image;
//Track ball using color parameters using OpenCV
+ (nonnull UIImage *)trackBallWithColor:(nonnull UIImage *)image:(NSString *)color;

@end
