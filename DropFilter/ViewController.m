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
{
    CGFloat alphaAngel;
    
}
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

// Label
@property (strong, nonatomic) UILabel *grayscaleLbl;
@property (strong, nonatomic) UILabel *amatorkarLbl;

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
    
    [self initLabels];
    
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
    alphaAngel = atan(self.view.bounds.size.height / self.view.bounds.size.width);
}
-(void) initLabels
{
    if (!_grayscaleLbl)
    {
        _grayscaleLbl = [[UILabel alloc] init];
        _grayscaleLbl.text = @"Oldboy";
        _grayscaleLbl.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:60];
        _grayscaleLbl.textColor = [UIColor whiteColor];
        _grayscaleLbl.backgroundColor = [UIColor clearColor];
        _grayscaleLbl.textAlignment = NSTextAlignmentCenter;
        
        [_grayscaleLbl sizeToFit];
    }
    if (!_amatorkarLbl)
    {
        _amatorkarLbl = [[UILabel alloc] init];
        _amatorkarLbl.text = @"Retro";
        _amatorkarLbl.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:60];
        _amatorkarLbl.textColor = [UIColor whiteColor];
        _amatorkarLbl.backgroundColor = [UIColor clearColor];
        _amatorkarLbl.textAlignment = NSTextAlignmentCenter;
        
        [_amatorkarLbl sizeToFit];
    }
    
    _grayscaleLbl.alpha = 0;
    _amatorkarLbl.alpha = 0;
    
    [self.view addSubview:_grayscaleLbl];
    [self.view addSubview:_amatorkarLbl];
}
-(void) setLabelsWithCenter:(CGPoint) center
{
    //NSLog(@"center = %@",NSStringFromCGPoint(center));
    
    _grayscaleLbl.center = center;
    _amatorkarLbl.center = center;
    
    // Rotate
    CATransform3D t1 = CATransform3DIdentity;
    t1 = CATransform3DTranslate(t1, 40, 0, 0);
    t1 = CATransform3DRotate(t1, alphaAngel, 0, 0, 1);
    
    CATransform3D t2 = CATransform3DIdentity;
    t2 = CATransform3DTranslate(t2, -40, 0, 0);
    t2 = CATransform3DRotate(t2, alphaAngel, 0, 0, 1);
    
    _amatorkarLbl.layer.transform = t1;
    _grayscaleLbl.layer.transform = t2;
    
    if (center.x > self.view.bounds.size.width / 2)
    {
        _grayscaleLbl.alpha = 1;
        
        CGFloat GA = _maskLayer.transform.m41 - self.view.bounds.size.width;
        _amatorkarLbl.alpha = 1 - (GA / self.view.bounds.size.width);
        
    }
    else
    {
        _amatorkarLbl.alpha = 1;
        
        CGFloat GA = _maskLayer.transform.m41 - self.view.bounds.size.width;
        GA = fabs(GA);
        _grayscaleLbl.alpha = 1 - (GA / self.view.bounds.size.width);
    }
}
-(void) initGesture
{
    _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    _panGesture.maximumNumberOfTouches = 1;
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
            // Translate maskLayer
            // We should disable Implecit Animation when assign directly to property of layer
            CGFloat percent = location.x / self.view.bounds.size.width;
            
            [self setPositionWithoutImplicitAnimationAtTransfrom:CATransform3DMakeTranslation (self.view.bounds.size.width * 2 * percent, 0, 0)];
            
            // Translate lable
            CGPoint center = [self centerPointerDependTransform:_maskLayer.transform];
            
            [self setLabelsWithCenter:center];
            
            break;
        }
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateEnded:
        {
            CATransform3D transfrom = _maskLayer.transform;
            
            // m41 is x corrdinatation
            if (transfrom.m41 > self.view.bounds.size.width)
            {
                // Animate masklayer to right edge
                [self animationMaskLayerToTransform:CATransform3DMakeTranslation(self.view.bounds.size.width * 2, 0, 0)];
            }
            else
            {
                // Animate masklayer to left edge
                [self animationMaskLayerToTransform:CATransform3DMakeTranslation( 0, 0, 0)];
            }
            
            [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                _amatorkarLbl.alpha = 0;
                _grayscaleLbl.alpha = 0;
            } completion:nil];
            break;
        }
        default:
            break;
    }
}
-(CGPoint) centerPointerDependTransform:(CATransform3D) transform
{
    // Translate lable
    if (transform.m41 > self.view.bounds.size.width)
    {
        CGFloat width = self.view.bounds.size.width;
        
        CGFloat GA = transform.m41 - width;
        CGFloat AC = width - GA;
        CGFloat AB = AC / cos(alphaAngel);
        
        CGFloat AO = AB / 2.0f;
        CGFloat y = sin(alphaAngel) * AO;
        CGFloat x = GA + cos(alphaAngel) * AO;
    
        return CGPointMake(x, y);
    }
    else
    {
        CGFloat height = self.view.bounds.size.height;
        
        CGFloat DB =  transform.m41;
        CGFloat belta = M_PI / 2 - alphaAngel;
        
        CGFloat AB = DB / sin(belta);
        
        CGFloat AO = AB / 2.0f;
        CGFloat x = sin(belta) * AO;
        CGFloat y = (height - cos(belta) * AB) + cos(belta) * AO;
        
        NSLog(@"DB = %.2f",DB);
        
        return CGPointMake(x, y);
    }
    return CGPointZero;
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
