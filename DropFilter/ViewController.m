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
@property (weak, nonatomic) IBOutlet GPUImageView *bottomCameraView;

// Still Camera
@property (strong, nonatomic) GPUImageStillCamera *stillCamera;

// Filter
@property (strong, nonatomic) GPUImageGrayscaleFilter *grayscaleFilter;
@property (strong, nonatomic) GPUImageAmatorkaFilter *amatorkaFilter;

// Mask
@property (strong, nonatomic) CAShapeLayer *maskLayer;

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
    
    [self initMask];
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
    
    // Amatorka filter
    _amatorkaFilter = [[GPUImageAmatorkaFilter alloc] init];
}
-(void) configureImageView
{
    // Top
    [_stillCamera addTarget:_grayscaleFilter];
    [_grayscaleFilter addTarget:_topCameraImageView];
    
    // Botom
    [_stillCamera addTarget:_amatorkaFilter];
    [_amatorkaFilter addTarget:_bottomCameraView];
}
-(void) initMask
{
    if (!_maskLayer)
    {
        _maskLayer = [CAShapeLayer layer];
        _maskLayer.frame = self.view.bounds;
        _maskLayer.backgroundColor = [UIColor clearColor].CGColor;
        
        // Bezier path
        UIBezierPath *triangle = [UIBezierPath bezierPath];
        [triangle moveToPoint:CGPointZero];
        [triangle addLineToPoint:CGPointMake(self.view.bounds.size.width, self.view.bounds.size.height)];
        [triangle addLineToPoint:CGPointMake(0, self.view.bounds.size.height)];
        [triangle addLineToPoint:CGPointZero];
        
        //
        _maskLayer.path = triangle.CGPath;
        _maskLayer.fillColor = [UIColor whiteColor].CGColor;
        
        // Add
        _topCameraImageView.layer.mask = _maskLayer;
        _topCameraImageView.layer.masksToBounds = YES;
    }
}
@end
