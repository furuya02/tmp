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
float ratio;

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

    // 画面の縦横比率
    ratio = [UIScreen mainScreen].bounds.size.height / [UIScreen mainScreen].bounds.size.width;

    [self setTexture:@"mesoko.png"];


    return self;
}


// パラメータにテクスチャ画像のファイル名を指定する。
-(void)setTexture:(NSString *)texturename {
    // テクスチャ画像ファイルをロード
    UIImage *teximage = [UIImage imageNamed:texturename];

    CGImageRef textureImage = teximage.CGImage;
    // サイズを取得
    NSInteger texWidth = CGImageGetWidth(textureImage);
    NSInteger texHeight = CGImageGetHeight(textureImage);
    // テクスチャデータのメモリを確保（使わなくなったら解放を忘れずに！）
    GLubyte *textureData = (GLubyte *)malloc(texWidth * texHeight * 4);
    // テクスチャ画像のコンテキストを作成
    CGContextRef textureContext = CGBitmapContextCreate(
                                                        textureData,
                                                        texWidth,
                                                        texHeight,
                                                        8, texWidth * 4,
                                                        CGImageGetColorSpace(textureImage),
                                                        kCGImageAlphaPremultipliedLast);
    CGContextDrawImage(textureContext, CGRectMake(0.0, 0.0, (float)texWidth, (float)texHeight), textureImage);
    CGContextRelease(textureContext);

    // ここまでがロード処理
    //これからテクスチャの初期化処理

    GLuint texid;

    glGenTextures(1, &texid);

    glBindTexture(GL_TEXTURE_2D, texid);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, texWidth, texHeight, 0, GL_RGBA,GL_UNSIGNED_BYTE, textureData);

    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
}

- (void)drawView:(id)sender
{
    // コンテキストを作成
    if ([EAGLContext currentContext] != context) {
        [EAGLContext setCurrentContext:context];
    }
    // OpenGLの設定
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, framebuffer);
    glViewport(0, 0, backingWidth, backingHeight);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    // カラーバッファのクリア
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT);

    // 射影変換の設定
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrthof(-1.0f, 1.0f, -ratio, ratio, 0, 10.0f);

    // モデルビューの設定
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();

    // OpenGLの状態を有効化
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_COLOR_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);

    // 加速度による回転
    glRotatef(_gravity.z * -90, 1, 0, 0);
    glRotatef(_gravity.x * 90, 0, 0, 1);
    // コンパスによる回転
    float heading = _heading;
    switch(self.orientation) {
        case UIDeviceOrientationPortrait:            // Device oriented vertically, home button on the bottom
            break;
        case UIDeviceOrientationPortraitUpsideDown:  // Device oriented vertically, home button on the top
            heading -= 180;
            break;
        case UIDeviceOrientationLandscapeLeft:       // Device oriented horizontally, home button on the right
            heading -= 270;
            break;
        case UIDeviceOrientationLandscapeRight:      // Device oriented horizontally, home button on the left
            heading -= 90;
            break;
    }
    glRotatef(heading , 0, 1, 0);

    // マーカーの描画
//    [self marker:0 :3]; // 0度の方向で、距離3
//    [self marker:30 :2]; // 30度の方向で、距離2
    //[self mesoko:-80 :2];
    [self rectangle:0 :3];
    //[self mesoko:0 :3];
//    [self flore:0 :3];// 真下


    // バッファを描画する
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, framebuffer);
    [context presentRenderbuffer:GL_RENDERBUFFER_OES];

    // OpenGLの状態を無効化する
    glDisableClientState(GL_VERTEX_ARRAY);
    glDisableClientState(GL_COLOR_ARRAY);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
}


- (void) mesoko:(float)angle :(float)distance
{
    // 現在の行列を保存する
    glPushMatrix();


//    [self setTexture:@"mesoko.png"];

    // オブジェクトの位置を決定する
    glRotatef(-angle, 0, 1, 0);
    glTranslatef(0, 0, -distance);

    // 頂点座標を登録
    GLfloat left = -0.5f;
    GLfloat right = 0.5f;
    GLfloat top = -3.0f;
    GLfloat bottom = -1.0f;
    GLfloat squareVertices[] = {
        left, bottom,
        right, bottom,
        left, top,
        right, top,
    };
    glVertexPointer(2, GL_FLOAT, 0, squareVertices);

    // 頂点色を設定(半透明の白色)
    const GLubyte squareColors[] = {
        255, 255, 255, 255,
        255, 255, 255, 255,
        255, 255, 255, 255,
        255, 255, 255, 255,
    };

    // テクスチャ座標配列を定義（追加）
    const GLfloat squareCoords[] = {
        0.0f, 0.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f,
    };

    // 色配列の定義を削除
    glColorPointer(4, GL_UNSIGNED_BYTE, 0, squareColors);
    glEnableClientState(GL_COLOR_ARRAY);

    // テクスチャ座標配列を定義（追加）
    glTexCoordPointer(2, GL_FLOAT, 0, squareCoords);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);

    // テクスチャを有効化（追加）
    glEnable(GL_TEXTURE_2D);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);


    // 以前の行列に戻す
    glPopMatrix();
}

- (void) rectangle:(float)angle :(float)distance
{
    // 白い四角を真北に表示
    // 現在の行列を保存する
    glPushMatrix();

    // オブジェクトの位置を決定する
    glRotatef(-angle, 0, 1, 0);
    glTranslatef(0, 0, -distance);

    // 頂点座標を登録
    GLfloat left = -0.5f;
    GLfloat right = 0.5f;
    GLfloat top = -0.5f;
    GLfloat bottom = 0.5f;
    GLfloat squareVertices[] = {
        left, bottom,
        right, bottom,
        left, top,
        right, top,
    };
    glVertexPointer(2, GL_FLOAT, 0, squareVertices);

    // 頂点色を設定(半透明の白色)
    const GLubyte squareColors[] = {
        255, 255, 255, 155,
        255, 255, 255, 155,
        255, 255, 255, 155,
        255, 255, 255, 155,
    };
    glColorPointer(4, GL_UNSIGNED_BYTE, 0, squareColors);
    glEnableClientState(GL_COLOR_ARRAY);
    // 描画する
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

    // 以前の行列に戻す
    glPopMatrix();
}



- (void) marker:(float)angle :(float)distance
{
    // 白い四角を真北に表示
    // 現在の行列を保存する
    glPushMatrix();

    // オブジェクトの位置を決定する
    glRotatef(-angle, 0, 1, 0);
    glTranslatef(0, 0, -distance);

    // 頂点座標を登録
    GLfloat left = -0.5f;
    GLfloat right = 0.5f;
    GLfloat top = -0.5f;
    GLfloat bottom = 0.5f;
    GLfloat squareVertices[] = {
        left, bottom,
        right, bottom,
        left, top,
        right, top,
    };
    glVertexPointer(2, GL_FLOAT, 0, squareVertices);

    // 頂点色を設定(半透明の白色)
    const GLubyte squareColors[] = {
        255, 255, 255, 155,
        255, 255, 255, 155,
        255, 255, 255, 155,
        255, 255, 255, 155,
    };
    glColorPointer(4, GL_UNSIGNED_BYTE, 0, squareColors);
    glEnableClientState(GL_COLOR_ARRAY);
    // 描画する
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

    // 以前の行列に戻す
    glPopMatrix();
}



- (void) flore:(float)angle :(float)distance
{

    // 白い四角を真下に表示
    // 現在の行列を保存する
    glPushMatrix();

    // オブジェクトの位置を決定する
    glRotatef(-90, 1, 0, 0); //真下に向ける
    glTranslatef(0, 0, -distance);

    // 頂点座標を登録
    GLfloat left = -3.5f;
    GLfloat right = 3.5f;
    GLfloat top = -3.5f;
    GLfloat bottom = 3.5f;
    GLfloat squareVertices[] = {
        left, bottom,
        right, bottom,
        left, top,
        right, top,
    };
    glVertexPointer(2, GL_FLOAT, 0, squareVertices);

    // 頂点色を設定(半透明の白色)
    const GLubyte squareColors[] = {
        255, 255, 255, 100,
        255, 255, 255, 100,
        255, 255, 255, 100,
        255, 255, 255, 100,
    };
    glColorPointer(4, GL_UNSIGNED_BYTE, 0, squareColors);
    // 描画する
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

    // 以前の行列に戻す
    glPopMatrix();
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
