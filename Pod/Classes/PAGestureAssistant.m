//
//  PAGestureAssistant.m
//  PAGestureAssistant
//
//  Created by Pedro Almeida on 1/30/16.
//  Copyright © 2016 Pedro Almeida. All rights reserved.
//

#import "PAGestureAssistant.h"
#import "PAGestureView.h"
#import "PAGestureBackgroundView.h"

#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import <FrameAccessor/FrameAccessor.h>

#define kPAGestureAssistantDefaultGestureViewColor  [UIColor whiteColor]
#define kPAGestureAssistantDefaultBackgroundColor   [UIColor colorWithWhite:0.2f alpha:0.8f]
#define kPAGestureAssistantDefaultFontSize          19

static char const * const kPAAssistantViewController = "viewController";
static char const * const kPAGestureAssistant        = "gestureAssistant";

#pragma mark - UIViewController (PAGestureAssistant) -

@interface UIViewController (PAGestureRecognizer)

@property (nonatomic, readonly, nullable) PAGestureAssistant *gestureAssistant;

@end

@implementation UIViewController (PAGestureAssistant)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        
        NSArray *selectors = @[NSStringFromSelector(@selector(viewWillAppear:)),
                               NSStringFromSelector(@selector(viewDidAppear:)),
                               NSStringFromSelector(@selector(viewWillDisappear:)),
                               NSStringFromSelector(@selector(willTransitionToTraitCollection:withTransitionCoordinator:))];
        
        for (int i = 0; i < selectors.count; i++) {
            
            SEL originalSelector = NSSelectorFromString(selectors[i]);
            SEL swizzledSelector = NSSelectorFromString([NSString stringWithFormat:@"pa_%@", selectors[i]]);
            
            Method originalMethod = class_getInstanceMethod(class, originalSelector);
            Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
            
            BOOL didAddMethod =
            class_addMethod(class,
                            originalSelector,
                            method_getImplementation(swizzledMethod),
                            method_getTypeEncoding(swizzledMethod));
            
            if (didAddMethod) {
                class_replaceMethod(class,
                                    swizzledSelector,
                                    method_getImplementation(originalMethod),
                                    method_getTypeEncoding(originalMethod));
            } else {
                method_exchangeImplementations(originalMethod, swizzledMethod);
            }
        }
    });
}

#pragma mark - Setup

- (void)pa_viewWillAppear:(BOOL)animated
{
    [self pa_viewWillAppear:animated];
    
    // dismiss on hide
    if (self.presentingViewController.gestureAssistant) {
        
        [self.presentingViewController.gestureAssistant pa_dismiss];
    }
}

- (void)pa_viewDidAppear:(BOOL)animated
{
    // if this is the first time
    if (!self.gestureAssistant) {
        
        PAGestureAssistant *gestureAssistant = [[PAGestureAssistant alloc] init];
        [self setGestureAssistant:gestureAssistant];
        
        // set the association
        objc_setAssociatedObject(self.gestureAssistant, kPAAssistantViewController, self, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    // if not first time clear the view and reset the timer
    else {
        
        [self.gestureAssistant pa_dismissThenResume];
    }
    
    [self pa_viewDidAppear:animated];
}

- (void)pa_viewWillDisappear:(BOOL)animated
{
    [self pa_viewWillDisappear:animated];
    
    // just to be safe, shouldn't have to
    if (self.gestureAssistant) {
        
        [self.gestureAssistant pa_dismiss];
    }
}

- (void)pa_willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    
    [self pa_willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    
    if (self.gestureAssistant && self.gestureAssistant.mode != PAGestureAssistantOptionUndefined) {
        
        NSLog(@"[%@] screen rotated. resetting timer...", NSStringFromClass([self class]));
        [self.gestureAssistant pa_dismissThenResume];
    }
}

#pragma mark - Stop -

- (void)stopGestureAssistant
{
    [self.gestureAssistant pa_dismiss];
}

#pragma mark - Show -

- (void)showGestureAssistantForTap:(PAGestureAssistantTap)tapOptions view:(nonnull UIView *)targetView attributedText:(nullable NSAttributedString *)attributedText afterIdleInterval:(NSTimeInterval)delay completion:(nullable PAGestureCompletion)completion
{
    PAGestureAssistantOptions option;
    
    switch (tapOptions)
    {
        case PAGestureAssistantTapSingle:
            option = PAGestureAssistantOptionTap;
            break;
            
        case PAGestureAssistantTapDouble:
            option = PAGestureAssistantOptionDoubleTap;
            break;
    }
    
    [self.gestureAssistant pa_show:option targetView:targetView startPoint:CGPointZero endPoint:CGPointZero attributedText:attributedText afterDelay:delay completion:completion];
}

- (void)showGestureAssistantForTap:(PAGestureAssistantTap)tapOptions point:(CGPoint)tapPoint attributedText:(nullable NSAttributedString *)attributedText afterIdleInterval:(NSTimeInterval)delay completion:(nullable PAGestureCompletion)completion
{
    PAGestureAssistantOptions option;
    
    switch (tapOptions)
    {
        case PAGestureAssistantTapSingle:
            option = PAGestureAssistantOptionTap;
            break;
            
        case PAGestureAssistantTapDouble:
            option = PAGestureAssistantOptionDoubleTap;
            break;
    }
    
    [self.gestureAssistant pa_show:option targetView:nil startPoint:tapPoint endPoint:CGPointZero attributedText:attributedText afterDelay:delay completion:completion];
}

#pragma mark Convenience: Regular Text

- (void)showGestureAssistantForSwipeWithStartPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint text:(nullable NSString *)text afterIdleInterval:(NSTimeInterval)delay
{
    NSAttributedString *attributedText = [self pa_makeAttributedText:text];
    [self showGestureAssistantForSwipeWithStartPoint:startPoint endPoint:endPoint attributedText:attributedText afterIdleInterval:delay];
}

- (void)showGestureAssistantForSwipeDirection:(PAGestureAssistantSwipeDirectons)swipeDirection text:(nullable NSString *)text afterIdleInterval:(NSTimeInterval)delay
{
    NSAttributedString *attributedText = [self pa_makeAttributedText:text];
    [self showGestureAssistantForSwipeDirection:swipeDirection attributedText:attributedText afterIdleInterval:delay];
}

- (void)showGestureAssistantForTap:(PAGestureAssistantTap)tapOptions view:(nonnull UIView *)targetView text:(nullable NSString *)text afterIdleInterval:(NSTimeInterval)delay
{
    NSAttributedString *attributedText = [self pa_makeAttributedText:text];
    [self showGestureAssistantForTap:tapOptions view:targetView attributedText:attributedText afterIdleInterval:delay completion:nil];
}

- (void)showGestureAssistantForTap:(PAGestureAssistantTap)tapOptions point:(CGPoint)tapPoint text:(nullable NSString *)text afterIdleInterval:(NSTimeInterval)delay
{
    NSAttributedString *attributedText = [self pa_makeAttributedText:text];
    [self showGestureAssistantForTap:tapOptions point:tapPoint attributedText:attributedText afterIdleInterval:delay completion:nil];
}

#pragma mark Convenience: Regular Text w/ Completion

- (void)showGestureAssistantForSwipeWithStartPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint text:(nullable NSString *)text afterIdleInterval:(NSTimeInterval)delay completion:(nonnull PAGestureCompletion)completion
{
    NSAttributedString *attributedText = [self pa_makeAttributedText:text];
    [self showGestureAssistantForSwipeWithStartPoint:startPoint endPoint:endPoint attributedText:attributedText afterIdleInterval:delay completion:completion];
}

- (void)showGestureAssistantForSwipeDirection:(PAGestureAssistantSwipeDirectons)swipeDirection text:(nullable NSString *)text afterIdleInterval:(NSTimeInterval)delay completion:(nonnull PAGestureCompletion)completion
{
    NSAttributedString *attributedText = [self pa_makeAttributedText:text];
    [self showGestureAssistantForSwipeDirection:swipeDirection attributedText:attributedText afterIdleInterval:delay completion:completion];
}

- (void)showGestureAssistantForTap:(PAGestureAssistantTap)tapOptions view:(nonnull UIView *)targetView text:(nullable NSString *)text afterIdleInterval:(NSTimeInterval)delay completion:(nonnull PAGestureCompletion)completion
{
    NSAttributedString *attributedText = [self pa_makeAttributedText:text];
    [self showGestureAssistantForTap:tapOptions view:targetView attributedText:attributedText afterIdleInterval:delay completion:completion];
}

- (void)showGestureAssistantForTap:(PAGestureAssistantTap)tapOptions point:(CGPoint)tapPoint text:(nullable NSString *)text afterIdleInterval:(NSTimeInterval)delay completion:(nonnull PAGestureCompletion)completion
{
    NSAttributedString *attributedText = [self pa_makeAttributedText:text];
    [self showGestureAssistantForTap:tapOptions point:tapPoint attributedText:attributedText afterIdleInterval:delay completion:completion];
}


#pragma mark - Swipe Methods


- (void)showGestureAssistantForSwipeDirection:(PAGestureAssistantSwipeDirectons)swipeDirection attributedText:(nullable NSAttributedString *)attributedText afterIdleInterval:(NSTimeInterval)delay completion:(nullable PAGestureCompletion)completion
{
    PAGestureAssistantOptions option;
    
    switch (swipeDirection)
    {
        case PAGestureAssistantSwipeDirectonDown:
            option = PAGestureAssistantOptionSwipeDown;
            break;
            
        case PAGestureAssistantSwipeDirectonUp:
            option = PAGestureAssistantOptionSwipeUp;
            break;
            
        case PAGestureAssistantSwipeDirectonLeft:
            option = PAGestureAssistantOptionSwipeLeft;
            break;
            
        case PAGestureAssistantSwipeDirectonRight:
            option = PAGestureAssistantOptionSwipeRight;
            break;
    }
    
    [self.gestureAssistant pa_show:option targetView:nil startPoint:CGPointZero endPoint:CGPointZero attributedText:attributedText afterDelay:delay completion:completion];
}

- (void)showGestureAssistantForSwipeWithStartPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint attributedText:(nullable NSAttributedString *)attributedText afterIdleInterval:(NSTimeInterval)delay completion:(nullable PAGestureCompletion)completion
{
    [self.gestureAssistant pa_show:PAGestureAssistantOptionCustomSwipe targetView:nil startPoint:startPoint endPoint:endPoint attributedText:attributedText afterDelay:delay completion:completion];
}

#pragma mark Convenience

- (void)showGestureAssistantForSwipeDirection:(PAGestureAssistantSwipeDirectons)swipeDirection attributedText:(nullable NSAttributedString *)attributedText afterIdleInterval:(NSTimeInterval)delay
{
    [self showGestureAssistantForSwipeDirection:swipeDirection attributedText:attributedText afterIdleInterval:delay completion:nil];
}

- (void)showGestureAssistantForSwipeWithStartPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint attributedText:(nullable NSAttributedString *)attributedText afterIdleInterval:(NSTimeInterval)delay
{
    [self showGestureAssistantForSwipeWithStartPoint:startPoint endPoint:endPoint attributedText:attributedText afterIdleInterval:delay completion:nil];
}


#pragma mark - Helpers

- (NSAttributedString *)pa_makeAttributedText:(NSString *)text
{
    if (text) {
        
        UIColor *color;
        
        if ([[PAGestureAssistant appearance] textColor]) {
            color = [[PAGestureAssistant appearance] textColor];
        }
        else if ([[PAGestureAssistant appearance] tapColor]) {
            color = [[PAGestureAssistant appearance] tapColor];
        }
        else {
            color = kPAGestureAssistantDefaultGestureViewColor;
        }
        
        UIFont  *font  = [UIFont systemFontOfSize:kPAGestureAssistantDefaultFontSize];
        
        NSDictionary *attributes = @{NSForegroundColorAttributeName:color, NSFontAttributeName:font};
        
        return [[NSMutableAttributedString alloc] initWithString:text attributes:attributes];
    }
    
    return [[NSAttributedString alloc] initWithString:@""];
}

#pragma mark - Setters & Getters

- (PAGestureAssistant *)gestureAssistant
{
    return objc_getAssociatedObject(self, kPAGestureAssistant);
}

- (void)setGestureAssistant:(PAGestureAssistant *)gestureAssistant
{
    objc_setAssociatedObject(self, kPAGestureAssistant, gestureAssistant, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end


#pragma mark - PAGestureAppearance -

@implementation PAGestureAppearance

+ (instancetype)sharedAppearance
{
    static PAGestureAppearance *sharedAppearance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedAppearance = [[self alloc] init];
    });
    return sharedAppearance;
}

@end

#pragma mark - PAGestureAssistant -
@interface PAGestureAssistant ()

@property (strong, nonatomic) NSArray <PAGestureView*>  *views;
@property (strong, nonatomic) NSArray <NSString*>       *startPositions;
@property (strong, nonatomic) NSArray <NSString*>       *endPositions;
@property (strong, nonatomic) NSTimer                   *idleTimer;
@property (strong, nonatomic) UIViewController          *viewController;
@property (strong, nonatomic) PAGestureBackgroundView   *backgroundView;
@property (strong, nonatomic) UILabel                   *descriptionLabel;
@property (nonatomic, readonly) UIWindow                *window;

@property (assign, nonatomic) dispatch_once_t           setupOnceToken;
@property (assign, nonatomic) PAGestureAssistantOptions mode;
@property (assign, nonatomic) NSTimeInterval            idleTimerDelay;
@property (copy)              PAGestureCompletion       completion;

@property (assign, nonatomic) BOOL                      isAnimating;
@property (assign, nonatomic) BOOL                      isDismissing;
//@property (assign, nonatomic) BOOL                      autoRepeat;

@end

@implementation PAGestureAssistant

#pragma mark - Setup

- (instancetype)init
{
    if (self = [super init])
    {
        [self pa_setup];
    }
    return self;
}

- (void)pa_setup
{
    self.idleTimerDelay                 = 10;
    self.views                          = [NSArray array];
    self.startPositions                 = [NSArray array];
    self.endPositions                   = [NSArray array];
    
    self.backgroundView                 = [[PAGestureBackgroundView alloc] initWithDelegate:self];
    self.backgroundView.alpha           = 0;
    
    self.descriptionLabel               = [UILabel new];
    self.descriptionLabel.font          = [UIFont systemFontOfSize:18];
    self.descriptionLabel.textAlignment = NSTextAlignmentCenter;
    self.descriptionLabel.numberOfLines = 0;
    self.descriptionLabel.alpha         = 0;
}


- (void)pa_prepareViews
{
    // recalculates sizes
    self.mode = self.mode;
    
    self.descriptionLabel.alpha = 0;
    
    // add subviews
    [self.window addSubview:self.backgroundView];
    [self.window addSubview:self.descriptionLabel];
    
}

#pragma mark - User Interaction (PAGestureDelegate)

- (void)pa_userHasTouchedView:(UIView *)view event:(UIEvent *)event
{
    if (self.isDismissing || self.backgroundView.alpha < 1) {
        
        return;
    }
    
    if (self.completion != nil) {
        
        self.isDismissing = YES;
        NSLog(@"[%@] user touch. completing task...", NSStringFromClass([self class]));
        [self pa_dismiss:^(BOOL finished) {
            
            dispatch_async(dispatch_get_main_queue(),^{
                if (self.completion) {
                    
                    PAGestureCompletion block = self.completion;
                    self.completion = nil;
                    block(YES);
                }
                
                self.isDismissing = NO;
            });
        }];
    }
    else if (self.idleTimerDelay > 0) {
        
        NSLog(@"[%@] user touch. resetting timer...", NSStringFromClass([self class]));
        [self pa_dismissThenResume];
    }
    
    else {
        
        NSLog(@"[%@] user touch. dismissing...", NSStringFromClass([self class]));
        [self pa_dismiss];
    }
}

- (BOOL)pa_allowContentTouches
{
    if (self.isDismissing) {
        return NO;
    }
    else if (self.backgroundView.alpha == 1) {
        return (self.completion == nil);
    }
    
    return YES;
}

#pragma mark - Idle Timer

- (void)pa_timerStart
{
    
    [self.idleTimer invalidate];
    self.idleTimer = nil;
    
    self.idleTimer = [NSTimer scheduledTimerWithTimeInterval:MAX(0.1f, self.idleTimerDelay)
                                                      target:self
                                                    selector:@selector(pa_timerTick:)
                                                    userInfo:nil
                                                     repeats:NO];
}

- (void)pa_timerTick:(NSTimer *)timer
{
    if ([self.idleTimer isEqual:timer]) {
        
        [self pa_commitAnimationWithDelay:1];
        
    }
    else {
        
        [timer invalidate];
        timer = nil;
    }
    
}

#pragma mark - Animation

- (void)pa_commitAnimationWithDelay:(CGFloat)delay
{
    // check if view is presenting something
    if (self.viewController.presentedViewController) {
        
        [self pa_timerStart];
        return;
    }
    
    // kill timer
    [self.idleTimer invalidate];
    self.idleTimer = nil;
    
    // position views
    for (int i=0; i < self.views.count; i++) {
        
        PAGestureView *view = self.views[i];
        CGPoint p0 = CGPointFromString(self.startPositions[i]);
        view.center = p0;
        [self.window addSubview:view];
    }
    
    self.isAnimating = NO;
    [self.window.layer removeAllAnimations];
    self.isAnimating = YES;
    
    switch (self.mode){
            
        case PAGestureAssistantOptionDoubleTap:
            [self pa_animateDoubleTapGesture:delay];
            break;
            
        case PAGestureAssistantOptionTap:
            [self pa_animateSingleTapGesture:delay];
            break;
            
        case PAGestureAssistantOptionSwipeUp:
        case PAGestureAssistantOptionSwipeDown:
        case PAGestureAssistantOptionSwipeLeft:
        case PAGestureAssistantOptionSwipeRight:
        case PAGestureAssistantOptionCustomSwipe:
            [self pa_animateSwipeGesture:delay];
            break;
            
        case PAGestureAssistantOptionUndefined:
            NSLog(@"[%@] can't animate undefined state", NSStringFromClass([self class]));
            break;
    }
    
    self.backgroundView.alpha = 0;
    self.backgroundView.backgroundColor = kPAGestureAssistantDefaultBackgroundColor;
    
    if ([[[self class] appearance] backgroundColor]) {
        
        self.backgroundView.backgroundColor = [[[self class] appearance] backgroundColor];
    }
    
    // fade in background
    [UIView animateWithDuration:kPAGestureAssistantDefaultViewPulseDuration*2
                          delay:delay
                        options:[self pa_defaultAnimationOptions]
                     animations:^{
        
        self.backgroundView.alpha = 1;
        
    } completion:^(BOOL finished) {
        
        self.viewController.view.tintAdjustmentMode = UIViewTintAdjustmentModeDimmed;
        self.viewController.navigationController.view.tintAdjustmentMode = UIViewTintAdjustmentModeDimmed;
        
        // fade in text
        [UIView animateWithDuration:kPAGestureAssistantDefaultViewPulseDuration*2 animations:^{
            self.descriptionLabel.alpha = 1;
        }];
        
    }];
}

- (void)pa_animateSingleTapGesture:(NSTimeInterval)delay
{
    NSTimeInterval tapDnDuration = kPAGestureAssistantDefaultViewPulseDuration * 0.67;
    NSTimeInterval tapUpDuration = kPAGestureAssistantDefaultViewPulseDuration ;
    
    // fade in gesture views
    [UIView animateWithDuration:kPAGestureAssistantDefaultViewPulseDuration*2 delay:delay options:[self pa_defaultAnimationOptions] animations:^{
        
        for (PAGestureView *view in self.views) {
            
            view.alpha = 1;
            view.transform = CGAffineTransformMakeScale(1.2f, 1.2f);
        }
        
    } completion:^(BOOL finished) {
        
        // first tap
        [UIView animateWithDuration:tapDnDuration delay:kPAGestureAssistantDefaultViewPulseDuration*2 options:[self pa_defaultAnimationOptions] animations:^{
            
            for (PAGestureView *view in self.views) {
                
                view.transform = CGAffineTransformMakeScale(1, 1);
                view.alpha = 0.75f;
            }
            
        } completion:^(BOOL finished) {
            
            // animate up
            [UIView animateWithDuration:tapUpDuration delay:0 options:[self pa_defaultAnimationOptions] animations:^{
                
                for (PAGestureView *view in self.views) {
                    
                    view.transform = CGAffineTransformMakeScale(1.2, 1.2);
                    view.alpha     = 1.f;
                }
                
            } completion:^(BOOL finished) {
                
                if (self.isAnimating && !self.idleTimer) {
                    
                    [self pa_commitAnimationWithDelay:0];
                }
            }];
            
        }];
    }];
}

- (void)pa_animateDoubleTapGesture:(NSTimeInterval)delay
{
    
    NSTimeInterval tapDnDuration = kPAGestureAssistantDefaultViewPulseDuration/3;
    NSTimeInterval tapUpDuration = kPAGestureAssistantDefaultViewPulseDuration/2;
    
    // fade in gesture views
    [UIView animateWithDuration:kPAGestureAssistantDefaultViewPulseDuration*2 delay:delay options:[self pa_defaultAnimationOptions] animations:^{
        
        for (PAGestureView *view in self.views) {
            
            view.alpha = 1;
            view.transform = CGAffineTransformMakeScale(1.2f, 1.2f);
        }
        
    } completion:^(BOOL finished) {
        
        // first tap
        [UIView animateWithDuration:tapDnDuration delay:kPAGestureAssistantDefaultViewPulseDuration*2 options:[self pa_defaultAnimationOptions] animations:^{
            
            for (PAGestureView *view in self.views) {
                
                view.transform = CGAffineTransformMakeScale(1, 1);
                view.alpha = 0.75f;
            }
            
        } completion:^(BOOL finished) {
            
            // animate up
            [UIView animateWithDuration:tapUpDuration delay:0 options:[self pa_defaultAnimationOptions] animations:^{
                
                for (PAGestureView *view in self.views) {
                    
                    view.transform = CGAffineTransformMakeScale(1.2, 1.2);
                    view.alpha     = 1.f;
                }
                
            } completion:^(BOOL finished) {
                
                // second tap
                [UIView animateWithDuration:tapDnDuration delay:0 options:[self pa_defaultAnimationOptions] animations:^{
                    
                    for (PAGestureView *view in self.views) {
                        
                        view.transform = CGAffineTransformMakeScale(1, 1);
                        view.alpha = 0.75f;
                    }
                    
                } completion:^(BOOL finished) {
                    
                    // animate up
                    [UIView animateWithDuration:tapUpDuration*2 delay:0 options:[self pa_defaultAnimationOptions] animations:^{
                        
                        for (PAGestureView *view in self.views) {
                            
                            view.transform = CGAffineTransformMakeScale(1.2, 1.2);
                            view.alpha     = 1;
                        }
                        
                    } completion:^(BOOL finished) {
                        
                        if (self.isAnimating && !self.idleTimer) {
                            
                            [self pa_commitAnimationWithDelay:0];
                        }
                        
                    }];
                    
                }];
                
            }];
            
        }];
    }];
    
}

- (void)pa_animateSwipeGesture:(NSTimeInterval)delay
{
    for (PAGestureView *view in self.views) {
        
        view.transform = CGAffineTransformMakeScale(0.1, 0.1);
        [view pulse:YES];
    }
    
    // fade in gesture views
    [UIView animateWithDuration:kPAGestureAssistantDefaultViewPulseDuration*2 delay:delay usingSpringWithDamping:0.6 initialSpringVelocity:0.6 options:[self pa_defaultAnimationOptions] animations:^{
        
        for (PAGestureView *view in self.views) {
            
            view.alpha     = 1;
            view.transform = CGAffineTransformMakeScale(1, 1);
        }
        
    } completion:^(BOOL finished) {
        
        // animate gesture views
        [UIView animateWithDuration:kPAGestureAssistantDefaultViewPulseDuration*1.5 delay:kPAGestureAssistantDefaultViewPulseDuration*3 options:[self pa_defaultAnimationOptions] animations:^{
            
            for (int i=0; i < self.views.count; i++) {
                
                PAGestureView *view = self.views[i];
                CGPoint p1 = CGPointFromString(self.endPositions[i]);
                
                view.center = p1;
                view.alpha  = 0.5f;
                
            }
            
        } completion:^(BOOL finished) {
            
            // fade out gesture views
            [UIView animateWithDuration:kPAGestureAssistantDefaultViewPulseDuration/2 delay:0 options:[self pa_defaultAnimationOptions] animations:^{
                
                for (PAGestureView *view in self.views) {
                    
                    view.alpha = 0;
                }
                
            } completion:^(BOOL finished) {
                
                // check for repeat
                if (self.isAnimating && !self.idleTimer) {
                    
                    [self pa_commitAnimationWithDelay:0];
                }
                
            }];
        }];
    }];
    
}

#pragma mark - Animation Control

- (void)pa_show:(PAGestureAssistantOptions)mode targetView:(nullable UIView *)targetView startPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint attributedText:(nullable NSAttributedString *)attributedText afterDelay:(NSTimeInterval)delay completion:(PAGestureCompletion)completion
{
    if (mode == PAGestureAssistantOptionUndefined) {
        
        NSLog(@"[%@] mode can't be undefined", NSStringFromClass([self class]));
        return;
    }
    
    if (targetView) {
        startPoint = [self centerPointForView:targetView];
    }
    
    [self pa_dismiss:^(BOOL finished) {
        
        switch (mode)
        {
            case PAGestureAssistantOptionTap:
            case PAGestureAssistantOptionDoubleTap:
                self.startPositions = @[NSStringFromCGPoint(startPoint)];
                break;
                
            case PAGestureAssistantOptionCustomSwipe:
                self.startPositions = @[NSStringFromCGPoint(startPoint)];
                self.endPositions   = @[NSStringFromCGPoint(endPoint)];
                break;
                
            case PAGestureAssistantOptionSwipeDown:
            case PAGestureAssistantOptionSwipeLeft:
            case PAGestureAssistantOptionSwipeRight:
            case PAGestureAssistantOptionSwipeUp:
                self.startPositions = [NSArray array];
                self.endPositions   = [NSArray array];
                break;
                
            case PAGestureAssistantOptionUndefined:
                NSLog(@"[%@] can't have a undefined type", NSStringFromClass([self class]));
                return;
        }
        
        //_isAnimating    = YES;
        _mode           = mode;
        _idleTimerDelay = delay;
        _targetView     = targetView;
        _completion     = completion;
        _descriptionLabel.attributedText = attributedText ? attributedText : [[NSAttributedString alloc] initWithString:@""];
        
        // prepare subviews
        [self pa_prepareViews];
        
        // start timer
        [self pa_timerStart];
        
    }];
}

- (void)pa_dismiss:(nullable PAGestureCompletion)completion
{
    if (self.mode == PAGestureAssistantOptionUndefined) {
        
        if (completion) {
            completion(YES);
        }
        return;
    }
    
    self.isDismissing = YES;
    
    // set animating state off
    self.isAnimating = NO;
    
    // clear target view
    //self.targetView = nil;
    
    // invalidate timer
    [self.idleTimer invalidate];
    self.idleTimer = nil;
    
    // and force animations completion
    [self.window.layer removeAllAnimations];
    
    // fade out views
    [UIView animateWithDuration:kPAGestureAssistantDefaultViewPulseDuration/3 delay:0 options:[self pa_defaultAnimationOptions] animations:^{
        
        self.descriptionLabel.alpha = 0;
        self.backgroundView.alpha = 0;
        
        for (PAGestureView *view in self.views) {
            
            view.alpha = 0;
        }
        
        // and remove from window
    } completion:^(BOOL finished) {
        
        for (PAGestureView *view in self.views) {
            
            [view pulse:NO];
            [view.layer removeAllAnimations];
            [view removeFromSuperview];
        }
        
        self.viewController.view.tintAdjustmentMode = UIViewTintAdjustmentModeAutomatic;
        self.viewController.navigationController.view.tintAdjustmentMode = UIViewTintAdjustmentModeAutomatic;
        
        self.backgroundView.backgroundColor = [UIColor clearColor];
        self.isDismissing = NO;
        
        [self.backgroundView removeFromSuperview];
        [self.descriptionLabel removeFromSuperview];
        
        if (completion) {
            completion(YES);
        }
        
    }];
}

- (void)pa_dismiss
{
    [self pa_dismiss:nil];
}

- (void)pa_dismissThenResume
{
    //__weak UIView *targetViewCopy = self.targetView;
    
    [self pa_dismiss:^(BOOL finished) {
        
        if (self.mode != PAGestureAssistantOptionUndefined)
        {
            //self.targetView = targetViewCopy;
            
            self.isAnimating = YES;
            
            // prepare subviews
            [self pa_prepareViews];
            
            // start timer
            [self pa_timerStart];
        }
    }];
}

#pragma mark - Setters

- (void)setMode:(PAGestureAssistantOptions)mode
{
    _mode = mode;
    
    // just to be safe
    for (PAGestureView *view in self.views) {
        [view removeFromSuperview];
    }
    
    NSArray *start = @[];
    NSArray *stop  = @[];
    
    NSInteger viewCount      = 0;
    CGFloat screenWidth      = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight     = [UIScreen mainScreen].bounds.size.height;
    CGFloat horizontalCenter = screenWidth/2;
    
    CGRect animationRect = CGRectMake(MAXFLOAT, MAXFLOAT, 0, 0);
    
    switch (self.mode) {
            
        case PAGestureAssistantOptionSwipeDown:
            viewCount = 1;
            start = @[NSStringFromCGPoint(CGPointMake(horizontalCenter, round(screenHeight * 0.2)))];
            stop  = @[NSStringFromCGPoint(CGPointMake(horizontalCenter, round(screenHeight * 0.7)))];
            break;
            
        case PAGestureAssistantOptionSwipeUp:
            viewCount = 1;
            start = @[NSStringFromCGPoint(CGPointMake(horizontalCenter, round(screenHeight * 0.65)))];
            stop  = @[NSStringFromCGPoint(CGPointMake(horizontalCenter, round(screenHeight * 0.15)))];
            break;
            
        case PAGestureAssistantOptionSwipeLeft:
            viewCount = 1;
            start = @[NSStringFromCGPoint(CGPointMake(screenWidth * 0.8, round(screenHeight/2)))];
            stop  = @[NSStringFromCGPoint(CGPointMake(screenWidth * 0.2, round(screenHeight/2)))];
            break;
            
        case PAGestureAssistantOptionSwipeRight:
            viewCount = 1;
            start = @[NSStringFromCGPoint(CGPointMake(screenWidth * 0.2, round(screenHeight/2)))];
            stop  = @[NSStringFromCGPoint(CGPointMake(screenWidth * 0.8, round(screenHeight/2)))];
            break;
            
        case PAGestureAssistantOptionCustomSwipe:
            viewCount = 1;
            start = [self.startPositions copy];
            stop  = [self.endPositions   copy];
            break;
            
        case PAGestureAssistantOptionTap:
        case PAGestureAssistantOptionDoubleTap:
            viewCount = 1;
            start = [self.startPositions copy];
            stop  = [self.startPositions copy];
            break;
            
        case PAGestureAssistantOptionUndefined:
            NSLog(@"[%@] Can't have undefined type!", NSStringFromClass([self class]));
            return;
    }
    
    // check animation rect to position label
    for (int i =0; i < start.count; i++) {
        
        CGPoint p0 = CGPointFromString(start[i]);
        CGPoint p1 = CGPointFromString(stop[i]);
        
        animationRect.origin.x      = MIN(animationRect.origin.x,    MIN(p0.x, p1.x));
        animationRect.origin.y      = MIN(animationRect.origin.y,    MIN(p0.y, p1.y));
        animationRect.size.width    = MAX(animationRect.size.width,  MAX(p0.x, p1.x) - animationRect.origin.x);
        animationRect.size.height   = MAX(animationRect.size.height, MAX(p0.y, p1.y) - animationRect.origin.y);
    }
    
    CGFloat labelY = round(MIN(screenHeight * 0.75, animationRect.origin.y + animationRect.size.height + kPAGestureAssistantDefaultViewSize));
    self.descriptionLabel.frame = CGRectMake(round(screenWidth * 0.15), labelY, round(screenWidth * 0.7), screenHeight - labelY);
    
    // set views color
    UIColor *viewColor = [[[self class] appearance] tapColor] ? [[[self class] appearance] tapColor] : kPAGestureAssistantDefaultGestureViewColor;
    [[PAGestureView appearance] setBackgroundColor:[viewColor colorWithAlphaComponent:0.7f]];
    
    // make views
    NSMutableArray *views = [NSMutableArray array];
    for (int i = 0; i < viewCount; i++)
    {
        PAGestureView *view = [[PAGestureView alloc] init];
        view.image = [[self class] appearance].tapImage;
        [views addObject:view];
    }
    
    self.startPositions = start;
    self.endPositions   = stop;
    self.views          = views;
}

#pragma mark - Getters

- (NSArray<NSString*>*)startPositions
{
    if (_targetView)
    {
        return @[NSStringFromCGPoint([self centerPointForView:_targetView])];
    }
    else return _startPositions;
}

- (UIViewController *)viewController
{
    return objc_getAssociatedObject(self, kPAAssistantViewController);
}

- (UIWindow *)window
{
    return self.viewController.view.window;
}

#pragma mark - Appearance

+ (PAGestureAppearance *)appearance
{
    return [PAGestureAppearance sharedAppearance];
}

#pragma mark - Helpers

- (CGPoint)centerPointForView:(UIView *)view
{
    CGPoint point = view.superview ? [view.superview convertPoint:view.center toView:nil] : view.center;
    return point;
}

- (UIViewAnimationOptions)pa_defaultAnimationOptions
{
    return  UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction;
}

- (void)dealloc
{
    _targetView = nil;
}

@end