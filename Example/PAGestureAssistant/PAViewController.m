//
//  PAViewController.m
//  PAGestureAssistant
//
//  Created by Pedro Almeida on 03/12/2016.
//  Copyright (c) 2016 Pedro Almeida. All rights reserved.
//

#import "PAViewController.h"
#import "PAGestureAssistant.h"

#define RGB(r, g, b)     [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1]
#define RGBA(r, g, b, a) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:(a)]

@interface PAViewController ()
@property (weak, nonatomic) IBOutlet UIButton           *button1;
@property (weak, nonatomic) IBOutlet UIButton           *button2;
@property (weak, nonatomic) IBOutlet UIButton           *button3;
@property (weak, nonatomic) IBOutlet UIButton           *optionsButton;
@property (weak, nonatomic) IBOutlet UISlider           *slider;
@property (weak, nonatomic) IBOutlet UILabel            *sliderLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;

@property (assign, nonatomic)        NSUInteger         delay;

@end

@implementation PAViewController


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // init slider
    [self changeDelay:self.slider];
    
    // init color theme
    [self changeTheme:self.segmentedControl];
    
}


- (IBAction)showOptions:(id)sender
{
    [self stopGestureAssistant];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Demo Options" message:@"" preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *singleTap = [UIAlertAction actionWithTitle:@"Tap" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [self showGestureAssistantForTap:PAGestureAssistantTapSingle
                                    view:self.button1
                                    text:@"Tap me"
                       afterIdleInterval:self.delay];
    }];
    
    UIAlertAction *longPress = [UIAlertAction actionWithTitle:@"Long Press" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [self showGestureAssistantForTap:PAGestureAssistantTapLongPress
                                    view:self.button3
                                    text:@"Long press me"
                       afterIdleInterval:self.delay];
    }];
    
    UIAlertAction *doubleTap = [UIAlertAction actionWithTitle:@"Custom Text Style" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        NSAttributedString *attr = [[NSAttributedString alloc] initWithString:@"Create custom text styles"
                                                                   attributes:@{NSFontAttributeName:[UIFont fontWithName:@"Georgia-Italic" size:18],
                                                                                NSBackgroundColorAttributeName: [UIColor yellowColor]}];
        
        [self showGestureAssistantForTap:PAGestureAssistantTapDouble
                                    view:self.button2
                          attributedText:attr
                       afterIdleInterval:self.delay
                              completion:nil];
    }];
    
    UIAlertAction *swipe = [UIAlertAction actionWithTitle:@"Swipe" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        PAGestureAssistantSwipeDirectons options = arc4random_uniform(4);
        NSString *title;
        
        switch (options) {
            case PAGestureAssistantSwipeDirectonUp:     title = @"Swipe up";    break;
            case PAGestureAssistantSwipeDirectonDown:   title = @"Swipe down";  break;
            case PAGestureAssistantSwipeDirectonLeft:   title = @"Swipe left";  break;
            case PAGestureAssistantSwipeDirectonRight:  title = @"Swipe right"; break;
        }
        
        [self showGestureAssistantForSwipeDirection:options
                                               text:title
                                  afterIdleInterval:self.delay];
        
    }];
    
    UIAlertAction *swipe2 = [UIAlertAction actionWithTitle:@"Custom Swipe" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [self showGestureAssistantForSwipeWithStartPoint:CGPointMake(300, 60) endPoint:CGPointMake(60, 300)
                                                    text:@"You can create custom swipes"
                                       afterIdleInterval:self.delay];
    }];
    
    UIAlertAction *tutorial = [UIAlertAction actionWithTitle:@"Tutorial Mode" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        /* Chain multiple calls to achieve a tutorial efect */
        [self showGestureAssistantForSwipeWithStartPoint:CGPointMake(70, 70) endPoint:self.view.center text:@"You can create custom swipes" afterIdleInterval:0 completion:^(BOOL finished) {
            
            [self showGestureAssistantForTap:PAGestureAssistantTapLongPress view:self.button3 text:@"Long press" afterIdleInterval:0 completion:^(BOOL finished) {
                
                [self showGestureAssistantForSwipeDirection:PAGestureAssistantSwipeDirectonUp text:@"Swipe up" afterIdleInterval:0 completion:^(BOOL finished) {
                    
                    NSLog(@"[%@] Chain completed", NSStringFromClass([self class]));
                    
                }];
            }];
        }];
    }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    
    [alertController addAction:singleTap];
    [alertController addAction:longPress];
    [alertController addAction:doubleTap];
    [alertController addAction:swipe];
    [alertController addAction:swipe2];
    [alertController addAction:tutorial];
    [alertController addAction:cancel];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction)changeTheme:(UISegmentedControl *)sender
{
    switch (sender.selectedSegmentIndex) {
        case 0: // light
            self.view.backgroundColor = RGB(255, 255, 255);
            self.view.tintColor       = RGB(  0, 122, 255);

            /* Sets a custom overlay color */
            [[PAGestureAssistant appearance] setBackgroundColor:RGBA(255, 255, 255, 0.75f)];
            /* Sets a custom text color */
            [[PAGestureAssistant appearance] setTextColor:RGB(0, 122, 255)];
            /* Sets the gesture view color */
            [[PAGestureAssistant appearance] setTapColor:RGB(0, 122, 255)];
            /* Sets a custom image for the gesture view. Overrides the `tapColor`.
             Image credits: https://dribbble.com/shots/1904249-Handy-Gestures */
            [[PAGestureAssistant appearance] setTapImage:[UIImage imageNamed:@"hand"]];
            
            break;
        
        case 1:
            self.view.backgroundColor = RGB( 66,  66,  66);
            self.view.tintColor       = RGB(100, 255, 111);
            
            [[PAGestureAssistant appearance] setBackgroundColor:RGBA(33, 33, 33, 0.7)];
            [[PAGestureAssistant appearance] setTextColor:RGB(255, 255, 255)];
            [[PAGestureAssistant appearance] setTapColor:RGB(100, 255, 111)];
            [[PAGestureAssistant appearance] setTapImage:nil];
            break;
            
        case 2:
            self.view.backgroundColor = RGB( 98, 160, 255);
            self.view.tintColor       = RGB(255, 255, 255);
            
            [[PAGestureAssistant appearance] setBackgroundColor:RGBA(33, 33, 33, 0.7)];
            [[PAGestureAssistant appearance] setTextColor:RGB(255, 255, 255)];
            [[PAGestureAssistant appearance] setTapColor:RGB(255, 255, 255)];
            [[PAGestureAssistant appearance] setTapImage:[UIImage imageNamed:@"hand"]];
            break;
    }
    
    // needed to enforce the color change, normally wouldn't be needed
    [self stopGestureAssistant];
    
    [self showGestureAssistantForTap:PAGestureAssistantTapSingle
                                view:self.optionsButton
                                text:@"Tap to begin"
                   afterIdleInterval:self.delay];
}

- (IBAction)changeDelay:(UISlider *)sender
{
    self.delay = round(sender.value);
    self.sliderLabel.text = [NSString stringWithFormat:@"%d second delay", (int)self.delay];
}

- (IBAction)buttonTap:(UIButton *)sender
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Yo" message:sender.titleLabel.text preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *dismiss = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleCancel handler:nil];
    
    [alertController addAction:dismiss];
    
    [self presentViewController:alertController animated:YES completion:nil];
}


@end