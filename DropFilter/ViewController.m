//
//  ViewController.m
//  DropFilter
//
//  Created by Nghia Tran on 4/3/15.
//  Copyright (c) 2015 Fe. All rights reserved.
//

#import "ViewController.h"
#import <GPUImage.h>

@interface ViewController ()

// GPUImage View
@property (weak, nonatomic) IBOutlet GPUImageView *topCameraImageView;

// Still Camera
@property (strong, nonatomic) GPUImageStillCamera *stillCamera;

// Filter
@property (strong, nonatomic) GPUImageGrayscaleFilter *grayscaleFilter;


@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self initCommon];
    
    [self configureCamera];
    
    [self configureFilter];
    
    [self configureImageView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(BOOL) prefersStatusBarHidden
{
    return YES;
}
#pragma mark - Cycle view
-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [_stillCamera startCameraCapture];
}
-(void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [_stillCamera stopCameraCapture];
}
#pragma mark - Init
-(void) initCommon
{
    
}
-(void) configureCamera
{
    // Init Still camera
    _stillCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPresetHigh cameraPosition:AVCaptureDevicePositionBack];
    _stillCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
}
-(void) configureFilter
{
    // Gray filter
    _grayscaleFilter = [[GPUImageGrayscaleFilter alloc] init];
}
-(void) configureImageView
{
    // Top
    [_stillCamera addTarget:_grayscaleFilter];
    [_grayscaleFilter addTarget:_topCameraImageView];
}
@end
