//
//  PAModalViewController.m
//  PAGestureAssistant
//
//  Created by Pedro Almeida on 6/25/16.
//  Copyright © 2016 Pedro Almeida. All rights reserved.
//

#import "PAModalViewController.h"
#import "PAGestureAssistant.h"

@interface PAModalViewController ()

@property (weak, nonatomic) IBOutlet UIButton *dismissButton;

@end

@implementation PAModalViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    [self showGestureAssistantForTap:PAGestureAssistantTapSingle view:self.dismissButton text:@"Let's go back" afterIdleInterval:5];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)dismiss:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
