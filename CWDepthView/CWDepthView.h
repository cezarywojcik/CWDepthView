//
//  CWDepthView.h
//  CWDepthViewDemo
//
//  Created by Cezary Wojcik on 3/15/14.
//  Copyright (c) 2014 Cezary Wojcik. All rights reserved.
//

#import <Foundation/Foundation.h>

#define DEPTH_VIEW_QUICK_ANIMATION_TIME 0.10f
#define DEPTH_VIEW_ANIMATION_TIME 0.25f
#define DEPTH_VIEW_SCALE 0.80
#define DEPTH_VIEW_FADE_VIEW_ALPHA 0.45f
#define DEPTH_VIEW_BLUR_RADIUS 20.0f

@interface CWDepthView : NSObject

@property (strong, nonatomic) UIWindow *depthViewWindow;
@property (strong, nonatomic) UIView *view;

- (void)startDepthViewWithCompletion:(void (^)(void)) completion;
- (void)dismissDepthViewWithCompletion:(void (^)(void)) completion;

- (void)presentView:(UIView *)viewToPresent;

@end
