//
//  ARView.m
//  ARSample
//
//  Created by hirauchi.shinichi on 2016/07/30.
//  Copyright © 2016年 SAPPOROWORKS. All rights reserved.
//

#import "ARView.h"


@implementation ARView

// Property
@synthesize roll = _roll;
@synthesize pitch = _pitch;
@synthesize yaw = _yaw;
@synthesize gravity = _gravity;
@synthesize heading = _heading;

//--------------------------------------------------------------//
#pragma mark -- Initialize --
//--------------------------------------------------------------//

+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

//- (void)_init
//{
//    // レイヤーの設定をする
//    CAEAGLLayer*    eaglLayer;
//    eaglLayer = (CAEAGLLayer*)self.layer;
//    eaglLayer.opaque = NO;
//    eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
//                                    [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking,
//                                    kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat,
//                                    nil];
//
//    // OpenGLコンテキストを作成する
//    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
//    [EAGLContext setCurrentContext:_context];
//
//    // フレームバッファを作成する
//    glGenFramebuffersOES(1, &_defaultFramebuffer);
//    glGenRenderbuffersOES(1, &_colorRenderbuffer);
//
//    glBindFramebufferOES(GL_FRAMEBUFFER_OES, _defaultFramebuffer);
//    glBindRenderbufferOES(GL_RENDERBUFFER_OES, _colorRenderbuffer);
//    [_context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(CAEAGLLayer*)self.layer];
//    glFramebufferRenderbufferOES(
//                                 GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, _colorRenderbuffer);
//
//    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &_backingWidth);
//    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &_backingHeight);
//}
//
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }

    // 初期化
    // レイヤーの設定をする
    CAEAGLLayer*    eaglLayer;
    eaglLayer = (CAEAGLLayer*)self.layer;
    eaglLayer.opaque = NO;
    eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking,
                                    kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat,
                                    nil];

    // OpenGLコンテキストを作成する
    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
    [EAGLContext setCurrentContext:_context];

    // フレームバッファを作成する
    glGenFramebuffersOES(1, &_defaultFramebuffer);
    glGenRenderbuffersOES(1, &_colorRenderbuffer);

    glBindFramebufferOES(GL_FRAMEBUFFER_OES, _defaultFramebuffer);
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, _colorRenderbuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(CAEAGLLayer*)self.layer];
    glFramebufferRenderbufferOES(
                                 GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, _colorRenderbuffer);

    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &_backingWidth);
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &_backingHeight);

    return self;
}

//- (id)initWithCoder:(NSCoder*)decoder
//{
//    self = [super initWithCoder:decoder];
//    if (!self) {
//        return nil;
//    }
//
//    // 初期化
//    [self _init];
//
//    return self;
//}

#pragma mark Drawing

- (void)drawView:(id)sender
{
    // 現在のコンテキストを作成する
    if([EAGLContext currentContext] != _context){
        [EAGLContext setCurrentContext:_context];
    }

    // OpenGLの設定をする
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, _defaultFramebuffer);
    glViewport(0, 0, _backingWidth, _backingHeight);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    // カラーバッファをクリアする
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT);

    // 射影変換の設定をする
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrthof(-1.0f, 1.0f, -1.5f, 1.5f, 0, 10.0f);

    // モデルビューの設定をする
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();

    // OpenGLの状態を有効化する
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_COLOR_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);

    // 加速度による回転を行う
    glRotatef(_gravity.z * -90.0f, 1.0f, 0, 0);

    // 電子コンパスによる回転を行う
    glRotatef(_heading, 0, 1.0f, 0);

    // ポリゴンを作成する
    int i;
    for (i = 0; i < 16; i++) {
        // 現在の行列を保存する
        glPushMatrix();

        // オブジェクトの位置を決定する
        glRotatef(360.0f / 16 * i, 0, 1.0f, 0);
        glTranslatef(0, 0, -2.0f);

        // ポリゴンの頂点を設定する
        GLfloat vleft, vright, vtop, vbottom;
        vleft = -0.2f;
        vright = 0.2f;
        vtop = -0.2f;
        vbottom = 0.2f;
        GLfloat squareVertices[] = {
            vleft, vbottom,
            vright, vbottom,
            vleft, vtop,
            vright, vtop,
        };
        glVertexPointer(2, GL_FLOAT, 0, squareVertices);

        // ポリゴンの色を設定する
        const GLubyte squareColors[] = {
            16 * i, 255 - (16 * i), 255, 255,
            16 * i, 255 - (16 * i), 255, 255,
            16 * i, 255 - (16 * i), 255, 255,
            16 * i, 255 - (16 * i), 255, 255,
        };
        glColorPointer(4, GL_UNSIGNED_BYTE, 0, squareColors);

        // ポリゴンを描画する
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

        // 以前の行列に戻す
        glPopMatrix();
    }

    // バッファを描画する
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, _defaultFramebuffer);
    [_context presentRenderbuffer:GL_RENDERBUFFER_OES];

    // OpenGLの状態を無効化する
    glDisableClientState(GL_VERTEX_ARRAY);
    glDisableClientState(GL_COLOR_ARRAY);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
}

//--------------------------------------------------------------//
#pragma mark -- Animation --
//--------------------------------------------------------------//

- (void)startAnimation
{
    // ディスプレイリンクを有効化する
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(drawView:)];
    [_displayLink setFrameInterval:1];
    [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)stopAnimation
{
    // ディスプレイリンクを無効化する
    [_displayLink invalidate], _displayLink = nil;
}

@end
