//
//  PAGestureBackgroundView.m
//  PAGestureAssistant
//
//  Created by Pedro Almeida on 1/30/16.
//  Copyright © 2016 Pedro Almeida. All rights reserved.
//

#import "PAGestureBackgroundView.h"


@implementation PAGestureBackgroundView

- (instancetype)initWithDelegate:(id<PAGestureDelegate>)delegate
{
    if (self = [super init]) {
        
        _delegate = delegate;
        self.userInteractionEnabled = YES;
    }
    return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [super willMoveToSuperview:newSuperview];
    [self removeConstraints:self.constraints];
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
    
    if (!self.superview) return;
    [self setupConstraints];
}

- (void)setupConstraints
{
    self.translatesAutoresizingMaskIntoConstraints = NO;
    
    UIView *view = self;
    
    NSDictionary *views = NSDictionaryOfVariableBindings(view);
    NSArray *h = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|" options:NSLayoutFormatAlignAllTop metrics:nil views:views];
    NSArray *v = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|" options:NSLayoutFormatAlignAllTop metrics:nil views:views];
    
    [self.superview addConstraints:h];
    [self.superview addConstraints:v];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    BOOL inside = [super pointInside:point withEvent:event];
    
    if (inside) {
        // setting async call because if the system doesn't get a quick
        // enough return it assumes NO
        dispatch_async(dispatch_get_main_queue(),^{
            [self.delegate pa_userHasTouchedView:self event:event];
        });
    }
    
    if ([self.delegate pa_allowContentTouches]) {
        return NO;
    }
    
    return inside;
}

- (void)dealloc
{
    _delegate = nil;
}

@end
