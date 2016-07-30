//
//  ARView.h
//  ARSample
//
//  Created by hirauchi.shinichi on 2016/07/30.
//  Copyright © 2016年 SAPPOROWORKS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreMotion/CoreMotion.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

@interface ARView : UIView
{
    // デバイスの位置情報
    float           _roll;
    float           _pitch;
    float           _yaw;
    CMAcceleration  _gravity;
    float           _heading;

    // OpenGL
    CADisplayLink*  _displayLink;
    EAGLContext*    _context;
    GLint           _backingWidth;
    GLint           _backingHeight;
    GLuint          _defaultFramebuffer;
    GLuint          _colorRenderbuffer;
}

// プロパティ
@property (nonatomic) float roll;
@property (nonatomic) float pitch;
@property (nonatomic) float yaw;
@property (nonatomic) CMAcceleration gravity;
@property (nonatomic) float heading;

// アニメーション
- (void)startAnimation;
- (void)stopAnimation;

@end

