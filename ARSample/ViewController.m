//
//  ViewController.m
//  ARSample
//
//  Created by hirauchi.shinichi on 2016/07/29.
//  Copyright © 2016年 SAPPOROWORKS. All rights reserved.
//

#import "ViewController.h"
#import "ARView.h"
#import <CoreMotion/CoreMotion.h>
#import "CoreLocation/CoreLocation.h"

@interface ViewController ()<UIImagePickerControllerDelegate,CLLocationManagerDelegate>
//@interface ViewController ()<UIImagePickerControllerDelegate>

@property (nonatomic)CLLocationManager* locationManager;
@property(nonatomic, strong) CMMotionManager *motionManager;
@property(nonatomic, strong) ARView *arView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidLayoutSubviews
{
    // デバイスの回転の検出
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(didChangedOrientation:)
               name:UIDeviceOrientationDidChangeNotification object:nil];

    // カメラ
    UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypeCamera;
    if ([UIImagePickerController isSourceTypeAvailable:sourceType]) {
        UIImagePickerController *cameraPicker = [[UIImagePickerController alloc] init];
        cameraPicker.sourceType = sourceType;
        cameraPicker.delegate = self;
        cameraPicker.showsCameraControls = NO;

        // スクリーンサイズに調整
        CGSize screenSize = [[UIScreen mainScreen] bounds].size;
        float heightRatio = 4.0f / 3.0f;
        float cameraHeight = screenSize.width * heightRatio;
        float scale = screenSize.height / cameraHeight;
        cameraPicker.cameraViewTransform = CGAffineTransformMakeTranslation(0, (screenSize.height - cameraHeight) / 2.0);
        cameraPicker.cameraViewTransform = CGAffineTransformScale(cameraPicker.cameraViewTransform, scale, scale);


        // ARビュー作成
        self.arView = [[ARView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        //self.arViewBak.backgroundColor = [UIColor redColor];
        cameraPicker.cameraOverlayView = self.arView;
        // カメラの表示
        [self presentViewController:cameraPicker animated:NO completion:nil];

        // OpenGL開示
        [self.arView startAnimation];
    }

    // コンパスが使用可能かどうかチェックする
    if ([CLLocationManager headingAvailable]) {
        // CLLocationManagerを作る
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;

        // コンパスの使用を開始する
        [_locationManager startUpdatingHeading];
    }

    // ジャイロ情報
    _motionManager = [[CMMotionManager alloc] init];
    if (_motionManager.deviceMotionAvailable) {
        // 更新の間隔を設定する
        _motionManager.deviceMotionUpdateInterval = 0.1f;
        [_motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue]
                                            withHandler: ^ (CMDeviceMotion* motion, NSError* error) {
                                                // ARのビューにジャイロ情報を送る
                                                self.arView.gravity = motion.gravity;
                                            }
         ];

    }
}

#pragma mark - Notification

- (void)didChangedOrientation:(NSNotification *)notification
{
    self.arView.orientation = [[notification object] orientation];
}

#pragma mark - LocationManager Delegate
// 方向の取得
-(void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
    // ARのビューに現在の方向を送る
    self.arView.heading = newHeading.trueHeading;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
