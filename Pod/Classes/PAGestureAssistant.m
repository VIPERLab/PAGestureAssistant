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
    // just to be safe, shouldn't have to
    if (self.gestureAssistant) {
        
        //NSLog(@"[%@] view will disappear", NSStringFromClass([self class]));
        [self.gestureAssistant pa_dismiss];
    }
    
    [self pa_viewWillDisappear:animated];
    
}

- (void)pa_willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    
    [self pa_willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    
    if (self.gestureAssistant && self.gestureAssistant.mode != PAGestureAssistantOptionUndefined) {
        
        //NSLog(@"[%@] screen rotated. resetting timer...", NSStringFromClass([self class]));
        [self.gestureAssistant pa_dismissThenResume];
    }
}

#pragma mark - Stop -

- (void)stopGestureAssistant
{
    [self.gestureAssistant pa_dismiss];
}

- (void)stopGestureAssistantWithCompletion:(nonnull PAGestureCompletion)completion
{
    [self.gestureAssistant pa_dismiss:completion];
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
            
        case PAGestureAssistantTapLongPress:
            option = PAGestureAssistantOptionLongPress;
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
            
        case PAGestureAssistantTapLongPress:
            option = PAGestureAssistantOptionLongPress;
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
        
        UIColor *textColor, *shadowColor;
        
        if ([[PAGestureAssistant appearance] textColor]) {
            textColor = [[PAGestureAssistant appearance] textColor];
        }
        else if ([[PAGestureAssistant appearance] tapColor]) {
            textColor = [[PAGestureAssistant appearance] tapColor];
        }
        else {
            textColor = kPAGestureAssistantDefaultGestureViewColor;
        }
        
        if ([[PAGestureAssistant appearance] backgroundColor]) {
            shadowColor = [[PAGestureAssistant appearance] backgroundColor];
        }
        else {
            shadowColor = kPAGestureAssistantDefaultBackgroundColor;
        }
        
        UIFont  *font = [UIFont systemFontOfSize:kPAGestureAssistantDefaultFontSize];
        
        NSShadow *shadow        = [NSShadow new];
        shadow.shadowOffset     = CGSizeMake(0, 2);
        shadow.shadowColor      = shadowColor;
        shadow.shadowBlurRadius = 12;
        
        NSDictionary *attributes = @{NSForegroundColorAttributeName: textColor,
                                     NSFontAttributeName: font,
                                     NSShadowAttributeName: shadow};
        
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

@property (assign, nonatomic) NSTimeInterval            lastTouchInterval;
@property (assign, nonatomic) dispatch_once_t           setupOnceToken;
@property (assign, nonatomic) PAGestureAssistantOptions mode;
@property (assign, nonatomic) NSTimeInterval            idleTimerDelay;
@property (copy)              PAGestureCompletion       completion;

@property (assign, nonatomic) BOOL                      isAnimating;
@property (assign, nonatomic) BOOL                      isFadingOut;
@property (assign, nonatomic) BOOL                      isFadingIn;

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
    
    self.descriptionLabel               = [[UILabel alloc] init];
    self.descriptionLabel.font          = [UIFont systemFontOfSize:18];
    self.descriptionLabel.textAlignment = NSTextAlignmentCenter;
    self.descriptionLabel.numberOfLines = 0;
    self.descriptionLabel.alpha         = 0;
    
    // debug
    // self.descriptionLabel.backgroundColor = [UIColor yellowColor];
}


- (void)pa_prepareViews
{
    // remove views from window
    for (PAGestureView *view in self.views) {
        [view removeFromSuperview];
    }
    
    // setup coordinates
    
    NSArray *start = @[];
    NSArray *stop  = @[];
    
    NSInteger viewCount      = 0;
    CGFloat screenWidth      = self.window.width;
    CGFloat screenHeight     = self.window.height;
    CGFloat screenTopMargin  = MAX (30, self.viewController.navigationController.navigationBar.bottom);
    CGFloat horizontalCenter = screenWidth/2.f;
    
    switch (self.mode) {
            
        case PAGestureAssistantOptionSwipeDown:
            viewCount = 1;
            start = @[NSStringFromCGPoint(CGPointMake(horizontalCenter, round(screenHeight * 0.2)))];
            stop  = @[NSStringFromCGPoint(CGPointMake(horizontalCenter, round(screenHeight * 0.66)))];
            break;
            
        case PAGestureAssistantOptionSwipeUp:
            viewCount = 1;
            start = @[NSStringFromCGPoint(CGPointMake(horizontalCenter, round(screenHeight * 0.66)))];
            stop  = @[NSStringFromCGPoint(CGPointMake(horizontalCenter, round(screenHeight * 0.15)))];
            break;
            
        case PAGestureAssistantOptionSwipeLeft:
            viewCount = 1;
            start = @[NSStringFromCGPoint(CGPointMake(screenWidth * 0.8, round(screenHeight/2.f)))];
            stop  = @[NSStringFromCGPoint(CGPointMake(screenWidth * 0.2, round(screenHeight/2.f)))];
            break;
            
        case PAGestureAssistantOptionSwipeRight:
            viewCount = 1;
            start = @[NSStringFromCGPoint(CGPointMake(screenWidth * 0.2, round(screenHeight/2.f)))];
            stop  = @[NSStringFromCGPoint(CGPointMake(screenWidth * 0.8, round(screenHeight/2.f)))];
            break;
            
        case PAGestureAssistantOptionCustomSwipe:
            viewCount = 1;
            start = [self.startPositions copy];
            stop  = [self.endPositions   copy];
            break;
            
        case PAGestureAssistantOptionTap:
        case PAGestureAssistantOptionDoubleTap:
        case PAGestureAssistantOptionLongPress:
            viewCount = 1;
            start = [self.startPositions copy];
            stop  = [self.startPositions copy];
            break;
            
        case PAGestureAssistantOptionUndefined:
            //NSLog(@"[%@] Can't have undefined type!", NSStringFromClass([self class]));
            return;
    }
    
    
    // set tap color
    UIColor *tapColor = [[[self class] appearance] tapColor] ? [[[self class] appearance] tapColor] : kPAGestureAssistantDefaultGestureViewColor;
    [[PAGestureView appearance] setBackgroundColor:[tapColor colorWithAlphaComponent:0.7f]];
    [[PAGestureView appearance] setTintColor:tapColor];
    
    
    // make views
    NSMutableArray *views = [NSMutableArray array];
    
    for (int i = 0; i < viewCount; i++) {
        
        PAGestureView *view = [[PAGestureView alloc] init];
        view.image = [[self class] appearance].tapImage;
        [views addObject:view];
    }
    
    self.startPositions = start;
    self.endPositions   = stop;
    self.views          = views;
    
    
    // Description Label
    
    CGRect animationRect = CGRectMake(MAXFLOAT, MAXFLOAT, 0, 0);
    
    // calculate animation rect to position label
    for (int i =0; i < start.count; i++) {
        
        CGPoint p0 = CGPointFromString(start[i]);
        CGPoint p1 = CGPointFromString(stop[i]);
        
        animationRect.origin.x      = 0; //MIN(animationRect.origin.x,    MIN(p0.x, p1.x));
        animationRect.origin.y      = MIN(animationRect.origin.y,    MIN(p0.y, p1.y));
        animationRect.size.height   = MAX(animationRect.size.height, MAX(p0.y, p1.y) - animationRect.origin.y);
        animationRect.size.width    = screenWidth; //MAX(animationRect.size.width,  MAX(p0.x, p1.x) - animationRect.origin.x);
    }
    
    CGFloat labelY      = 0;
    CGFloat labelMargin = 30;
    CGFloat labelWidth  = screenWidth * 0.7;
    CGSize  textSize    = [self.descriptionLabel.attributedText boundingRectWithSize:CGSizeMake(labelWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin context:nil].size;
    CGFloat labelHeight = MAX(60, textSize.height + 6); // adding a bit of leeway
    
    // position label
    // CGFloat spaceAbove = CGRectGetMinY(animationRect) - labelMargin;
    CGFloat spaceBelow = screenHeight - CGRectGetMaxY(animationRect) - kPAGestureAssistantDefaultViewSize - labelMargin;
    
    if (spaceBelow >= labelHeight) {
        
        labelY = CGRectGetMaxY(animationRect) + kPAGestureAssistantDefaultViewSize + labelMargin;
    }
    else {
        
        labelY = MAX(screenTopMargin, CGRectGetMinY(animationRect) - labelMargin - labelHeight);
    }
    
    self.descriptionLabel.alpha = 0;
    self.descriptionLabel.frame = CGRectMake(round((screenWidth - labelWidth)/2.f),
                                             round(labelY),
                                             round(labelWidth),
                                             round(labelHeight));
    
    // add subviews
    [self.window addSubview:self.descriptionLabel];
    
}

#pragma mark - User Interaction (PAGestureDelegate)

- (void)pa_userHasTouchedView:(UIView *)view event:(UIEvent *)event
{
    // prevents multiple firings for same touch event
    if (event.allTouches.allObjects.firstObject.timestamp == self.lastTouchInterval) {
        return;
    }
    
    self.lastTouchInterval = event.allTouches.allObjects.firstObject.timestamp;
    
    if (self.isFadingOut || self.isFadingIn || [self.backgroundView.backgroundColor isEqual:[UIColor clearColor]]) {
        
        if (self.completion) {
            return;
        }
    }
    
    if (self.completion != nil) {
        
        self.isFadingOut = YES;
        //NSLog(@"[%@] user touch. completing task...", NSStringFromClass([self class]));
        [self pa_dismiss:^(BOOL finished) {
            
            dispatch_async(dispatch_get_main_queue(),^{
                if (self.completion) {
                    
                    PAGestureCompletion block = self.completion;
                    self.completion = nil;
                    block(YES);
                }
                
                self.isFadingOut = NO;
            });
        }];
    }
    else if (self.idleTimerDelay > 0) {
        
        //NSLog(@"[%@] user touch. resetting timer...", NSStringFromClass([self class]));
        [self pa_dismissThenResume];
    }
    
    else {
        
        //NSLog(@"[%@] user touch. dismissing...", NSStringFromClass([self class]));
        [self pa_dismiss];
    }
}

- (BOOL)pa_allowContentTouches
{
    if (self.completion) {
        return NO;
    }
    
    return YES;
}

#pragma mark - Idle Timer

- (void)pa_timerStart
{
    
    [self.idleTimer invalidate];
    self.idleTimer = nil;
    
    self.idleTimer = [NSTimer scheduledTimerWithTimeInterval:self.idleTimerDelay
                                                      target:self
                                                    selector:@selector(pa_timerTick:)
                                                    userInfo:nil
                                                     repeats:NO];
}

- (void)pa_timerTick:(NSTimer *)timer
{
    if ([self.idleTimer isEqual:timer]) {
        
        // set background
        [self pa_prepareBackground];
        
        // prepare subviews
        [self pa_prepareViews];
        
        // animate!
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
    // abort if view is already presenting
    if (self.viewController.presentedViewController) {
        
        [self pa_timerStart];
        return;
    }
    
    if (self.viewController.navigationController) {
        
        if (![self.viewController isEqual:self.viewController.navigationController.topViewController]) {
        
            [self pa_dismiss];
        }
    }
    
    //NSLog(@"[%@] commiting animation", NSStringFromClass([self class]));
    
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
    
    self.isFadingIn = YES;
    
    self.isAnimating = NO;
    [self.window.layer removeAllAnimations];
    self.isAnimating = YES;
    
    switch (self.mode){
            
        case PAGestureAssistantOptionDoubleTap:
            [self pa_animateDoubleTapGesture:delay];
            break;
            
        case PAGestureAssistantOptionTap:
            [self pa_animateSingleTapGesture:delay timeScale:0.7];
            break;
            
        case PAGestureAssistantOptionLongPress:
            [self pa_animateSingleTapGesture:delay timeScale:4.4];
            break;
            
        case PAGestureAssistantOptionSwipeUp:
        case PAGestureAssistantOptionSwipeDown:
        case PAGestureAssistantOptionSwipeLeft:
        case PAGestureAssistantOptionSwipeRight:
        case PAGestureAssistantOptionCustomSwipe:
            [self pa_animateSwipeGesture:delay];
            break;
            
        case PAGestureAssistantOptionUndefined:
            //NSLog(@"[%@] can't animate undefined state", NSStringFromClass([self class]));
            return;
    }
    
    // fade in background
    [UIView animateWithDuration:kPAGestureAssistantDefaultViewPulseDuration*2
                          delay:delay
                        options:[self pa_defaultAnimationOptions]
                     animations:^{
                         
                         self.backgroundView.backgroundColor = [[[self class] appearance] backgroundColor] ? [[[self class] appearance] backgroundColor] : kPAGestureAssistantDefaultBackgroundColor;
                        
                     } completion:^(BOOL finished) {
                         
                         self.isFadingIn = NO;
                         
                         self.viewController.view.tintAdjustmentMode = UIViewTintAdjustmentModeDimmed;
                         self.viewController.navigationController.view.tintAdjustmentMode = UIViewTintAdjustmentModeDimmed;
                         
                         // fade in text
                         [UIView animateWithDuration:kPAGestureAssistantDefaultViewPulseDuration*2 animations:^{
                             self.descriptionLabel.alpha = 1;
                         }];
                         
                     }];
}

- (void)pa_animateSingleTapGesture:(NSTimeInterval)delay timeScale:(CGFloat)timeScale
{
    NSTimeInterval tapDnDuration = kPAGestureAssistantDefaultViewPulseDuration * 0.67 * timeScale;
    NSTimeInterval tapUpDuration = kPAGestureAssistantDefaultViewPulseDuration;
    
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
    
    NSTimeInterval tapDnDuration = kPAGestureAssistantDefaultViewPulseDuration/3.f;
    NSTimeInterval tapUpDuration = kPAGestureAssistantDefaultViewPulseDuration/2.f;
    
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
            [UIView animateWithDuration:kPAGestureAssistantDefaultViewPulseDuration/2.f delay:0 options:[self pa_defaultAnimationOptions] animations:^{
                
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
        
        //NSLog(@"[%@] mode can't be undefined", NSStringFromClass([self class]));
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
            case PAGestureAssistantOptionLongPress:
                self.startPositions = @[NSStringFromCGPoint(startPoint)];
                self.endPositions   = [NSArray array];
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
                //NSLog(@"[%@] can't have a undefined type", NSStringFromClass([self class]));
                return;
        }
        
        _mode           = mode;
        _idleTimerDelay = MAX(0.1f, delay);
        _targetView     = targetView;
        _completion     = completion;
        _descriptionLabel.attributedText = attributedText ? attributedText : [[NSAttributedString alloc] initWithString:@""];
        
        // start timer
        [self pa_timerStart];
    }];
}

- (void)pa_prepareBackground
{
    self.backgroundView.backgroundColor = [UIColor clearColor];
    [self.window addSubview:self.backgroundView];
}

- (void)pa_dismiss:(nullable PAGestureCompletion)completion
{
//    if (self.mode == PAGestureAssistantOptionUndefined) {
//        
//        if (completion) {
//            completion(YES);
//        }
//        return;
//    }
    
    //NSLog(@"[%@] dismiss begin...", NSStringFromClass([self class]));
    
    self.isFadingOut = YES;
    
    // set animating state off
    self.isAnimating = NO;
    
    // clear target view
    //self.targetView = nil;
    
    // invalidate timer
    [self.idleTimer invalidate];
    self.idleTimer = nil;
    
    self.mode = PAGestureAssistantOptionUndefined;
    
    // and force animations completion
    [self.window.layer removeAllAnimations];
    
    // fade out views
    [UIView animateWithDuration:kPAGestureAssistantDefaultViewPulseDuration/3.f
                          delay:0
                        options:[self pa_defaultAnimationOptions]
                     animations:^{
        
        self.descriptionLabel.alpha = 0;
        self.backgroundView.backgroundColor = [UIColor clearColor];
        
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
        
        self.viewController.view.tintAdjustmentMode                      = UIViewTintAdjustmentModeAutomatic;
        self.viewController.navigationController.view.tintAdjustmentMode = UIViewTintAdjustmentModeAutomatic;
        
        self.isFadingOut = NO;
        
        [self.backgroundView   removeFromSuperview];
        [self.descriptionLabel removeFromSuperview];
        
        if (completion) {
            completion(YES);
        }
        
        //NSLog(@"[%@] dismiss end.", NSStringFromClass([self class]));
    }];
}

- (void)pa_dismiss
{
    [self pa_dismiss:nil];
}

- (void)pa_dismissThenResume
{
    PAGestureAssistantOptions mode = self.mode;
    
    [self pa_dismiss:^(BOOL finished) {
        
        if (mode != PAGestureAssistantOptionUndefined)
        {
            self.mode = mode;
            self.isAnimating = YES;
            
            // start timer
            [self pa_timerStart];
        }
    }];
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
