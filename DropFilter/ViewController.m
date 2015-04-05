//
//  ViewController.m
//  DropFilter
//
//  Created by Nghia Tran on 4/3/15.
//  Copyright (c) 2015 Fe. All rights reserved.
//

#import "ViewController.h"
#import <GPUImage.h>
#import "FeBasicAnimationBlock.h"

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

// Gesture
@property (strong, nonatomic) UIPanGestureRecognizer *panGesture;

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
    
    [self initGesture];
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
-(void) initGesture
{
    _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    [self.view addGestureRecognizer:_panGesture];
    
    self.topCameraImageView.userInteractionEnabled = YES;
    self.bottomCameraView.userInteractionEnabled = YES;
}
-(void) handlePanGesture:(UIPanGestureRecognizer *) sender
{
    CGPoint location = [sender locationInView:self.view];
    
    switch (sender.state)
    {
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateChanged:
        {
            [self setPositionWithoutImplicitAnimationAtTransfrom:CATransform3DMakeTranslation(location.x * 2, 0, 0)];
            
            break;
        }
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateEnded:
        {
            CATransform3D transfrom = _maskLayer.transform;
            if (transfrom.m41 > self.view.bounds.size.width)
            {
                [self animationMaskLayerToTransform:CATransform3DMakeTranslation(self.view.bounds.size.width * 2, 0, 0)];
            }
            else
            {
                [self animationMaskLayerToTransform:CATransform3DMakeTranslation( 0, 0, 0)];
            }
            break;
        }
        default:
            break;
    }
}

-(void) animationMaskLayerToTransform:(CATransform3D) finalTransform
{
    CABasicAnimation *transalteAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
    transalteAnimation.toValue = (id)[NSValue valueWithCATransform3D:finalTransform];
    transalteAnimation.duration = 0.3f;
    transalteAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    transalteAnimation.removedOnCompletion = NO;
    transalteAnimation.fillMode = kCAFillModeForwards;
    
    // Delegate
    FeBasicAnimationBlock *blockDelegate = [FeBasicAnimationBlock new];
    transalteAnimation.delegate = blockDelegate;
    
    __weak typeof(self) weakSelf = self;
    blockDelegate.blockDidStart = ^{
        typeof(self) strongSelf = weakSelf;
        
        // Disable gesture
        strongSelf.panGesture.enabled = NO;
    };
    blockDelegate.blockDidStop = ^{
        typeof(self) strongSelf = weakSelf;
        
        // Enable
        strongSelf.panGesture.enabled = YES;
        
        // remove
        [strongSelf.maskLayer removeAllAnimations];
        
        // Set final
        [strongSelf setPositionWithoutImplicitAnimationAtTransfrom:finalTransform];
    };
    
    [_maskLayer addAnimation:transalteAnimation forKey:@"animation"];
}
-(void) setPositionWithoutImplicitAnimationAtTransfrom:(CATransform3D ) transform
{
    [CATransaction begin];
    
    // Disable
    [CATransaction setDisableActions:YES];
    
    // Point
    _maskLayer.transform = transform;
    
    [CATransaction commit];
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
        CGFloat width = self.view.bounds.size.width;
        CGFloat height = self.view.bounds.size.height;
        
        _maskLayer = [CAShapeLayer layer];
        _maskLayer.frame = CGRectMake(0, 0, width * 2, height);
        _maskLayer.backgroundColor = [UIColor clearColor].CGColor;
        
        // Bezier path
        UIBezierPath *triangle = [UIBezierPath bezierPath];
        [triangle moveToPoint:CGPointZero];
        [triangle addLineToPoint:CGPointMake(width, 0)];
        [triangle addLineToPoint:CGPointMake(width * 2, height)];
        [triangle addLineToPoint:CGPointMake(0, height)];
        [triangle addLineToPoint:CGPointZero];
        
        // Add to mask layer
        _maskLayer.path = triangle.CGPath;
        _maskLayer.fillColor = [UIColor whiteColor].CGColor;
        
        // Translate to center
        _maskLayer.anchorPoint = CGPointZero;
        _maskLayer.position = CGPointMake( - width * 2, 0);
        
        // Add
        _topCameraImageView.layer.mask = _maskLayer;
        _topCameraImageView.layer.masksToBounds = YES;
    }
}
@end
