//
//  PAGestureAssistant.m
//  PAGestureAssistant
//
//  Created by Pedro Almeida on 1/30/16.
//  Copyright © 2016 Pedro Almeida. All rights reserved.
//

#import "PAGestureView.h"

@implementation PAGestureView

- (instancetype)initWithFrame:(CGRect)frame
{
    // override frame
    frame = CGRectMake(0, 0, kPAGestureAssistantDefaultViewSize, kPAGestureAssistantDefaultViewSize);
    
    if (self = [super initWithFrame:frame]) {
        
        self.layer.anchorPoint      = CGPointMake(0.5f, 0.5f);
        self.userInteractionEnabled = NO;
        self.transform              = CGAffineTransformMakeScale(0.1, 0.1);
        self.alpha                  = 0;
        self.image                  = nil;
        self.contentMode            = UIViewContentModeScaleAspectFit;
    }
    return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [super willMoveToSuperview:newSuperview];
    
    [self.layer removeAllAnimations];
    self.transform = CGAffineTransformIdentity;
    self.alpha = 0;
    
}

- (void)setImage:(UIImage *)image
{
    [super setImage:image];
    
    if (!image) {
        self.layer.masksToBounds = YES;
        self.layer.cornerRadius  = self.bounds.size.height/2;
    }
    else {
        self.layer.masksToBounds = NO;
        self.layer.cornerRadius  = 0;
        self.backgroundColor     = [UIColor clearColor];
    }
}

- (void)pulse:(BOOL)pulse
{
    if (self.image) return;
    
    static NSString *animationKey = @"transform.scale";
    
    _isPulsing = pulse;
    
    if (pulse) {
        
        CABasicAnimation *theAnimation;
        
        theAnimation              = [CABasicAnimation animationWithKeyPath:animationKey];
        theAnimation.duration     = kPAGestureAssistantDefaultViewPulseDuration;
        theAnimation.repeatCount  = MAXFLOAT;
        theAnimation.autoreverses = YES;
        theAnimation.fromValue    = @(1);
        theAnimation.toValue      = @(1.17);
        
        [self.layer addAnimation:theAnimation forKey:animationKey];
    }
    
    else {
        
        [self.layer removeAllAnimations];
        [UIView animateWithDuration:0.1f animations:^{
            self.transform = CGAffineTransformIdentity;
        }];
    }
}


@end
