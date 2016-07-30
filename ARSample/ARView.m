//
//  ARView.m
//  ARSample
//
//  Created by hirauchi.shinichi on 2016/07/31.
//  Copyright © 2016年 SAPPOROWORKS. All rights reserved.
//

#import "ARView.h"
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>


@implementation ARView

EAGLContext *context;
GLuint framebuffer;
GLuint colorRenderbuffer;
GLint  backingWidth;
GLint  backingHeight;
CADisplayLink* displayLink;

+ (Class)layerClass
{
    // レイヤ（描画先）としてCAEAGLLayerを使用する
    return [CAEAGLLayer class];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }

    // 初期化

    // レイヤー設定
    CAEAGLLayer *layer = (CAEAGLLayer*)self.layer;
    // カメラの表示が見えるようにするため透明にする
    layer.opaque = NO;
    // 描画の設定
    layer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithBool:NO],kEAGLDrawablePropertyRetainedBacking, //描画後にレンダバッファを破棄
                                kEAGLColorFormatRGBA8,kEAGLDrawablePropertyColorFormat,// カラーレンダバッファは8bit（デフォルト値）
                                nil];
    // コンテキストの作成
    context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
    [EAGLContext setCurrentContext:context];


    // フレームバッファの生成
    glGenFramebuffersOES(1, &framebuffer);
    // レンダラーバッファの生成
    glGenRenderbuffersOES(1, &colorRenderbuffer);
    // フレームバッファのバインド
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, framebuffer);
    // レンダラーバッファのバインド
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
    // レンダーバッファに、描画可能なオブジェクトのストレージをバインド
    [context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(CAEAGLLayer*)self.layer];
    //フレームバッファにレンダーバッファをカラーバッファとしてアタッチ
    glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, colorRenderbuffer);
    // ビューポートのためにサイズを取得する
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);

    return self;
}


- (void)drawView:(id)sender
{
    // 現在のコンテキストを作成する
    if([EAGLContext currentContext] != context){
        [EAGLContext setCurrentContext:context];
    }

    // OpenGLの設定をする
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, framebuffer);
    glViewport(0, 0, backingWidth, backingHeight);
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
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, framebuffer);
    [context presentRenderbuffer:GL_RENDERBUFFER_OES];

    // OpenGLの状態を無効化する
    glDisableClientState(GL_VERTEX_ARRAY);
    glDisableClientState(GL_COLOR_ARRAY);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
}

#pragma mark Public Method

- (void)startAnimation
{
    // ディスプレイリンクを有効化する
    displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(drawView:)];
    [displayLink setFrameInterval:1];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)stopAnimation
{
    // ディスプレイリンクを無効化する
    [displayLink invalidate], displayLink = nil;
}


@end
