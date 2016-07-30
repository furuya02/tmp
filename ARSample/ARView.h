//
//  ARView.h
//  ARSample
//
//  Created by hirauchi.shinichi on 2016/07/31.
//  Copyright © 2016年 SAPPOROWORKS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h> // CMAccelerationを使用するのであれば

//#import <OpenGLES/EAGL.h>
//#import <OpenGLES/ES1/gl.h>
//#import <OpenGLES/ES1/glext.h>


@interface ARView : UIView

//@property (nonatomic) float roll;
//@property (nonatomic) float pitch;
//@property (nonatomic) float yaw;
@property (nonatomic) CMAcceleration gravity;
@property (nonatomic) float heading;
@property (nonatomic) UIDeviceOrientation orientation;

// アニメーション
- (void)startAnimation;
- (void)stopAnimation;


@end
