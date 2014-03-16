//
//  MainViewController.m
//  CWDepthViewDemo
//
//  Created by Cezary Wojcik on 3/15/14.
//  Copyright (c) 2014 Cezary Wojcik. All rights reserved.
//

#import "MainViewController.h"
#import "DemoViewController.h"
#import "CWDepthView.h"

@interface MainViewController ()

@end

@implementation MainViewController

@synthesize depthView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

# pragma mark - depth view

- (void)setupDepthView
{
    // initialize depth view
    self.depthView = [CWDepthView new];
    
    // make view to present
    DemoViewController *demoViewController = [[DemoViewController alloc] initWithNibName:@"DemoViewController" bundle:nil];
    
    // present view
    [self.depthView presentView:demoViewController.view];
    
    // hook up dismiss action
    [demoViewController.dismissButton addTarget:self action:@selector(dismissDepthView) forControlEvents:UIControlEventTouchUpInside];
}

- (void)dismissDepthView
{
    [self.depthView dismissDepthViewWithCompletion:nil];
}

# pragma mark - button actions

- (IBAction)createDepthViewButtonPressed:(UIButton *)sender
{
    [self setupDepthView];
}

@end
