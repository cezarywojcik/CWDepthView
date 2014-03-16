//
//  CWDepthView.m
//  CWDepthViewDemo
//
//  Created by Cezary Wojcik on 3/15/14.
//  Copyright (c) 2014 Cezary Wojcik. All rights reserved.
//

#import "CWDepthView.h"
#import <QuartzCore/QuartzCore.h>

@import Accelerate;

# pragma mark - UIImage ImageBlur implementation

@implementation UIImage (ImageBlur)
// This method is taken from Apple's UIImageEffects category provided in WWDC 2013 sample code
- (UIImage *)applyBlurWithRadius:(CGFloat)blurRadius tintColor:(UIColor *)tintColor saturationDeltaFactor:(CGFloat)saturationDeltaFactor maskImage:(UIImage *)maskImage
{
    // Check pre-conditions.
    if (self.size.width < 1 || self.size.height < 1) {
        NSLog (@"*** error: invalid size: (%.2f x %.2f). Both dimensions must be >= 1: %@", self.size.width, self.size.height, self);
        return nil;
    }
    if (!self.CGImage) {
        NSLog (@"*** error: image must be backed by a CGImage: %@", self);
        return nil;
    }
    if (maskImage && !maskImage.CGImage) {
        NSLog (@"*** error: maskImage must be backed by a CGImage: %@", maskImage);
        return nil;
    }
    
    CGRect imageRect = { CGPointZero, self.size };
    UIImage *effectImage = self;
    
    BOOL hasBlur = blurRadius > __FLT_EPSILON__;
    BOOL hasSaturationChange = fabs(saturationDeltaFactor - 1.) > __FLT_EPSILON__;
    if (hasBlur || hasSaturationChange) {
        UIGraphicsBeginImageContextWithOptions(self.size, NO, [[UIScreen mainScreen] scale]);
        CGContextRef effectInContext = UIGraphicsGetCurrentContext();
        CGContextScaleCTM(effectInContext, 1.0, -1.0);
        CGContextTranslateCTM(effectInContext, 0, -self.size.height);
        CGContextDrawImage(effectInContext, imageRect, self.CGImage);
        
        vImage_Buffer effectInBuffer;
        effectInBuffer.data     = CGBitmapContextGetData(effectInContext);
        effectInBuffer.width    = CGBitmapContextGetWidth(effectInContext);
        effectInBuffer.height   = CGBitmapContextGetHeight(effectInContext);
        effectInBuffer.rowBytes = CGBitmapContextGetBytesPerRow(effectInContext);
        
        UIGraphicsBeginImageContextWithOptions(self.size, NO, [[UIScreen mainScreen] scale]);
        CGContextRef effectOutContext = UIGraphicsGetCurrentContext();
        vImage_Buffer effectOutBuffer;
        effectOutBuffer.data     = CGBitmapContextGetData(effectOutContext);
        effectOutBuffer.width    = CGBitmapContextGetWidth(effectOutContext);
        effectOutBuffer.height   = CGBitmapContextGetHeight(effectOutContext);
        effectOutBuffer.rowBytes = CGBitmapContextGetBytesPerRow(effectOutContext);
        
        if (hasBlur) {
            // A description of how to compute the box kernel width from the Gaussian
            // radius (aka standard deviation) appears in the SVG spec:
            // http://www.w3.org/TR/SVG/filters.html#feGaussianBlurElement
            //
            // For larger values of 's' (s >= 2.0), an approximation can be used: Three
            // successive box-blurs build a piece-wise quadratic convolution kernel, which
            // approximates the Gaussian kernel to within roughly 3%.
            //
            // let d = floor(s * 3*sqrt(2*pi)/4 + 0.5)
            //
            // ... if d is odd, use three box-blurs of size 'd', centered on the output pixel.
            //
            CGFloat inputRadius = blurRadius * [[UIScreen mainScreen] scale];
            NSUInteger radius = floor(inputRadius * 3. * sqrt(2 * M_PI) / 4 + 0.5);
            if (radius % 2 != 1) {
                radius += 1; // force radius to be odd so that the three box-blur methodology works.
            }
            
            vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, NULL, 0, 0, (uint32_t) radius, (uint32_t) radius, 0, kvImageEdgeExtend);
            vImageBoxConvolve_ARGB8888(&effectOutBuffer, &effectInBuffer, NULL, 0, 0, (uint32_t) radius, (uint32_t) radius, 0, kvImageEdgeExtend);
            vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, NULL, 0, 0, (uint32_t) radius, (uint32_t) radius, 0, kvImageEdgeExtend);
        }
        BOOL effectImageBuffersAreSwapped = NO;
        if (hasSaturationChange) {
            CGFloat s = saturationDeltaFactor;
            CGFloat floatingPointSaturationMatrix[] = {
                0.0722 + 0.9278 * s,  0.0722 - 0.0722 * s,  0.0722 - 0.0722 * s,  0,
                0.7152 - 0.7152 * s,  0.7152 + 0.2848 * s,  0.7152 - 0.7152 * s,  0,
                0.2126 - 0.2126 * s,  0.2126 - 0.2126 * s,  0.2126 + 0.7873 * s,  0,
                0,                    0,                    0,  1,
            };
            const int32_t divisor = 256;
            NSUInteger matrixSize = sizeof(floatingPointSaturationMatrix)/sizeof(floatingPointSaturationMatrix[0]);
            int16_t saturationMatrix[matrixSize];
            for (NSUInteger i = 0; i < matrixSize; ++i) {
                saturationMatrix[i] = (int16_t)roundf(floatingPointSaturationMatrix[i] * divisor);
            }
            if (hasBlur) {
                vImageMatrixMultiply_ARGB8888(&effectOutBuffer, &effectInBuffer, saturationMatrix, divisor, NULL, NULL, kvImageNoFlags);
                effectImageBuffersAreSwapped = YES;
            }
            else {
                vImageMatrixMultiply_ARGB8888(&effectInBuffer, &effectOutBuffer, saturationMatrix, divisor, NULL, NULL, kvImageNoFlags);
            }
        }
        if (!effectImageBuffersAreSwapped)
            effectImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        if (effectImageBuffersAreSwapped)
            effectImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    // Set up output context.
    UIGraphicsBeginImageContextWithOptions(self.size, NO, [[UIScreen mainScreen] scale]);
    CGContextRef outputContext = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(outputContext, 1.0, -1.0);
    CGContextTranslateCTM(outputContext, 0, -self.size.height);
    
    // Draw base image.
    CGContextDrawImage(outputContext, imageRect, self.CGImage);
    
    // Draw effect image.
    if (hasBlur) {
        CGContextSaveGState(outputContext);
        if (maskImage) {
            CGContextClipToMask(outputContext, imageRect, maskImage.CGImage);
        }
        CGContextDrawImage(outputContext, imageRect, effectImage.CGImage);
        CGContextRestoreGState(outputContext);
    }
    
    // Add in color tint.
    if (tintColor) {
        CGContextSaveGState(outputContext);
        CGContextSetFillColorWithColor(outputContext, tintColor.CGColor);
        CGContextFillRect(outputContext, imageRect);
        CGContextRestoreGState(outputContext);
    }
    
    // Output image is ready.
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return outputImage;
}
@end

# pragma mark - CWDepthView implemention

@interface CWDepthView ()

@property (strong, nonatomic) UIView *screenshotView;
@property (strong, nonatomic) UIView *blurredScreenshotView;
@property (strong, nonatomic) UIView *fadeView;
@property (strong, nonatomic) UIView *presentedView;

@end

@implementation CWDepthView

@synthesize depthViewWindow, view;

@synthesize screenshotView, blurredScreenshotView;

- (CWDepthView *) init
{
    self = [super init];
    if (self) {
        // setup
    }
    return self;
}

# pragma mark - image methods

- (UIImage *)getScreenImageFromView:(UIView *)viewForScreenshot
{
    // frame without status bar
    CGRect frame;
    if (UIDeviceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
        frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    } else {
        frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
    }
    // begin image context
    UIGraphicsBeginImageContext(frame.size);
    // get current context
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    // draw current view
    [viewForScreenshot.layer renderInContext:UIGraphicsGetCurrentContext()];
    // clip context to frame
    CGContextClipToRect(currentContext, frame);
    // get resulting cropped screenshot
    UIImage *screenshot = UIGraphicsGetImageFromCurrentImageContext();
    // end image context
    UIGraphicsEndImageContext();
    return screenshot;
}

- (UIImage *)getBlurredImage:(UIImage *)imageToBlur {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        return [imageToBlur applyBlurWithRadius:10.0f tintColor:[UIColor clearColor] saturationDeltaFactor:1.0 maskImage:nil];
    }
    return imageToBlur;
}

# pragma mark - setup methods

- (void)createScreenshotView
{
    UIImage *screenshot = [self getScreenImageFromView:[UIApplication sharedApplication].delegate.window.rootViewController.view];
    UIImage *blurredScreenshot = [screenshot applyBlurWithRadius:DEPTH_VIEW_BLUR_RADIUS tintColor:[UIColor clearColor] saturationDeltaFactor:1.0f maskImage:nil];
    self.screenshotView = [[UIImageView alloc] initWithImage:screenshot];
    self.screenshotView.alpha = 0.0f;
    self.blurredScreenshotView = [[UIImageView alloc] initWithImage:blurredScreenshot];
    self.blurredScreenshotView.alpha = 0.0f;
}

- (void)createDepthViewWindow
{
    self.depthViewWindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.depthViewWindow.backgroundColor = [UIColor blackColor];
    self.depthViewWindow.userInteractionEnabled = YES;
    self.depthViewWindow.hidden = NO;
    self.depthViewWindow.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.depthViewWindow.windowLevel = UIWindowLevelStatusBar;
    self.depthViewWindow.rootViewController = [UIViewController new];
    self.depthViewWindow.rootViewController.view.bounds = [[UIScreen mainScreen] bounds];
    [self.depthViewWindow makeKeyAndVisible];
    self.view = self.depthViewWindow.rootViewController.view;
}

- (void)createFadeView
{
    self.fadeView = [UIView new];
    self.fadeView.frame = [[UIScreen mainScreen] bounds];
    self.fadeView.backgroundColor = [UIColor blackColor];
    self.fadeView.alpha = 0.0f;
}

- (void)startDepthViewWithCompletion:(void (^)(void)) completion
{
    // setup
    [self createScreenshotView];
    [self createDepthViewWindow];
    [self createFadeView];
    
    // add screenshot view
    [self.view addSubview:self.screenshotView];
    [self.view addSubview:self.blurredScreenshotView];
    
    // add fade view
    [self.view addSubview:self.fadeView];
    
    // animate status bar out quickly
    [UIView animateWithDuration:DEPTH_VIEW_QUICK_ANIMATION_TIME animations:^{
        self.screenshotView.alpha = 1.0f;
        self.fadeView.alpha = DEPTH_VIEW_FADE_VIEW_ALPHA;
    }];
    
    // animate screenshot view
    [UIView animateWithDuration:DEPTH_VIEW_ANIMATION_TIME animations:^{
        self.screenshotView.transform = CGAffineTransformMakeScale(DEPTH_VIEW_SCALE, DEPTH_VIEW_SCALE);
        self.screenshotView.alpha = 0.0f;
        self.blurredScreenshotView.transform = CGAffineTransformMakeScale(DEPTH_VIEW_SCALE, DEPTH_VIEW_SCALE);
        self.blurredScreenshotView.alpha = 1.0f;
    } completion:^(BOOL finished) {
        [completion invoke];
    }];
}

- (void)dismissDepthViewWithCompletion:(void (^)(void)) completion
{
    [UIView animateWithDuration:DEPTH_VIEW_ANIMATION_TIME animations:^{
        // animate presented view out
        self.presentedView.transform = CGAffineTransformMakeScale(2/DEPTH_VIEW_SCALE, 2/DEPTH_VIEW_SCALE);
        self.presentedView.alpha = 0.0f;
        
        // animate blurred out
        self.blurredScreenshotView.alpha = 0.0f;
        self.blurredScreenshotView.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
        
        // animate screenshot in
        self.screenshotView.alpha = 1.0f;
        self.screenshotView.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
        
        // remove fade
        self.fadeView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        // animate screenshot out quickly
        [UIView animateWithDuration:DEPTH_VIEW_QUICK_ANIMATION_TIME animations:^{
            self.screenshotView.alpha = 0.0f;
            self.depthViewWindow.hidden = YES;
        } completion:^(BOOL finished) {
            [completion invoke];
        }];
    }];
}

- (void)presentView:(UIView *)viewToPresent
{
    [self startDepthViewWithCompletion:nil];
    
    // animate view to present in
    [self.view addSubview:viewToPresent];
    self.presentedView = viewToPresent;
    self.presentedView.alpha = 0.0f;
    self.presentedView.transform = CGAffineTransformMakeScale(2/DEPTH_VIEW_SCALE, 2/DEPTH_VIEW_SCALE);
    [UIView animateWithDuration:DEPTH_VIEW_ANIMATION_TIME animations:^{
        self.presentedView.alpha = 1.0f;
        self.presentedView.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
    }];
}

@end
