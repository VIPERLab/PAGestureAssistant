//
//  PAGestureAssistant.h
//  PAGestureAssistant
//
//  Created by Pedro Almeida on 1/30/16.
//  Copyright © 2016 Pedro Almeida. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "PAGestureDelegate.h"

/** PAGestureAssistantSwipeDirectonUp, PAGestureAssistantSwipeDirectonDown, PAGestureAssistantSwipeDirectonLeft, PAGestureAssistantSwipeDirectonRight */
typedef enum : NSUInteger {
    /** A vertical swipe gesture from bottom to top centered on the screen. */
    PAGestureAssistantSwipeDirectonUp,
    /** A vertical swipe gesture from top to bottom centered on the screen. */
    PAGestureAssistantSwipeDirectonDown,
    /** A horizontal swipe gesture from left to right centered on the screen. */
    PAGestureAssistantSwipeDirectonLeft,
    /** A horizontal swipe gesture from right to left centered on the screen. */
    PAGestureAssistantSwipeDirectonRight
} PAGestureAssistantSwipeDirectons;

/** PAGestureAssistantTapSingle, PAGestureAssistantTapDouble */
typedef enum : NSUInteger {
    /** A single tap animation. */
    PAGestureAssistantTapSingle,
    /** A double tap animation. */
    PAGestureAssistantTapDouble,
} PAGestureAssistantTap;

typedef enum : NSUInteger {
    PAGestureAssistantOptionUndefined,
    PAGestureAssistantOptionTap,
    PAGestureAssistantOptionDoubleTap,
    PAGestureAssistantOptionSwipeDown,
    PAGestureAssistantOptionSwipeUp,
    PAGestureAssistantOptionSwipeLeft,
    PAGestureAssistantOptionSwipeRight,
    PAGestureAssistantOptionCustomSwipe,
} PAGestureAssistantOptions;

typedef void(^PAGestureCompletion)(BOOL finished);

#pragma mark - Appearance

@interface PAGestureAppearance : NSObject

/** Overrides the default background overlay color. Default color is translucent black. */
@property (nonatomic, strong, nullable) UIColor *backgroundColor;
/** Overrides the default text color. Default color is white. */
@property (nonatomic, strong, nullable) UIColor *textColor;
/** Overrides the default gesture view color. Default color is white. */
@property (nonatomic, strong, nullable) UIColor *tapColor;
/** Sets an image for the gesture view. Size is 44pt. */
@property (nonatomic, strong, nullable) UIImage *tapImage;

NS_ASSUME_NONNULL_BEGIN
+ (instancetype)sharedAppearance;
NS_ASSUME_NONNULL_END

@end

#pragma mark - Gesture Assistant

@interface PAGestureAssistant : NSObject <PAGestureDelegate>

@property (nonatomic, readonly) BOOL isAnimating;
@property (nonatomic, readonly) PAGestureAssistantOptions mode;
@property (nonatomic, weak, nullable) UIView *targetView;

NS_ASSUME_NONNULL_BEGIN
/** The Appearance delegate. */
+ (PAGestureAppearance *)appearance;
NS_ASSUME_NONNULL_END

/**
 Private method. Sets the gesture animation.
 @discussion Do not call directly!
 */
- (void)pa_show:(PAGestureAssistantOptions)mode targetView:(nullable UIView *)targetView startPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint attributedText:(nullable NSAttributedString *)attributedText afterDelay:(NSTimeInterval)delay completion:(nullable PAGestureCompletion)completion;
/**
 Private method. Aborts the current animation and resets the timer.
 @discussion Do not call directly!
 */
- (void)pa_dismissThenResume;
/**
 Private method. Stops the animation and kills the timer.
 @discussion Do not call directly!
 */
- (void)pa_dismiss;

@end


#pragma mark - View Controller

/**
 A drop-in UIViewController superclass category for showing interaction tips to the user.
 @discussion It will work automatically, by calling any of the show methods in `viewDidAppear`.
 */
@interface UIViewController (PAGestureAssistant)

/**
 Dismisses any currently active animation and kills the timer.
 */
- (void)stopGestureAssistant;

#pragma mark Regular Text

/**
 Schedules a custom swipe gesture after the determined time interval.
 @discussion After any user interaction the timer will restart. If you don't want this behavior use the same method with completion.
 @param startPoint The starting point of the swipe.
 @param endPoint The ending point of the swipe.
 @param text The text that will appear alongside the animation.
 @param afterIdleInterval The amount of time without any user interaction after which the animation is triggered.
 @see -showGestureAssistantForSwipeWithStartPoint:endPoint:text:afterIdleInterval:completion:
 */
- (void)showGestureAssistantForSwipeWithStartPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint text:(nullable NSString *)text afterIdleInterval:(NSTimeInterval)delay;
/**
 Schedules a predefined swipe gesture after the determined time interval.
 @discussion After any user interaction the timer will restart. If you don't want this behavior use the same method with completion.
 @param startPoint The starting point of the swipe.
 @param swipeDirection PAGestureAssistantSwipeDirectonUp, PAGestureAssistantSwipeDirectonDown, PAGestureAssistantSwipeDirectonLeft, PAGestureAssistantSwipeDirectonRight.
 @param text The text that will appear alongside the animation.
 @param afterIdleInterval The amount of time without any user interaction after which the animation is triggered.
 @see -showGestureAssistantForSwipeDirection:text:afterIdleInterval:completion:
 */
- (void)showGestureAssistantForSwipeDirection:(PAGestureAssistantSwipeDirectons)swipeDirection text:(nullable NSString *)text afterIdleInterval:(NSTimeInterval)delay;
/**
 Schedules a tap gesture at the view's center after the determined time interval.
 @discussion Will always show at the view center, even if the view's position changes (e.g. Screen rotation).
 After any user interaction the timer will restart. If you don't want this behavior use the same method with completion.
 @param targetView The target view where you want the animation to appear.
 @param text The text that will appear alongside the animation.
 @param afterIdleInterval The amount of time without any user interaction after which the animation is triggered.
 @see -showGestureAssistantForTap:view:text:afterIdleInterval:completion:
 */
- (void)showGestureAssistantForTap:(PAGestureAssistantTap)tapOptions view:(nonnull UIView *)targetView text:(nullable NSString *)text afterIdleInterval:(NSTimeInterval)delay;
/**
 Schedules a tap gesture at a fixed point after the determined time interval.
 @discussion After any user interaction the timer will restart. If you don't want this behavior use the same method with completion.
 @param point The coordinate where you want the animation to appear.
 @param text The text that will appear alongside the animation.
 @param afterIdleInterval The amount of time without any user interaction after which the animation is triggered.
 @see -showGestureAssistantForTap:point:text:afterIdleInterval:completion:
 */
- (void)showGestureAssistantForTap:(PAGestureAssistantTap)tapOptions point:(CGPoint)tapPoint text:(nullable NSString *)text afterIdleInterval:(NSTimeInterval)delay;

#pragma mark Completion

/**
 Schedules a custom swipe gesture after the determined time interval.
 @discussion One time only. After any user interaction the timer will stop.
 @param startPoint The starting point of the swipe.
 @param endPoint The ending point of the swipe.
 @param text The text that will appear alongside the animation.
 @param afterIdleInterval The amount of time without any user interaction after which the animation is triggered.
 @param completion A block that runs after the animation has been dismissed
 @see -showGestureAssistantForSwipeWithStartPoint:endPoint:attributedText:afterIdleInterval:completion:
 */
- (void)showGestureAssistantForSwipeWithStartPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint text:(nullable NSString *)text afterIdleInterval:(NSTimeInterval)delay completion:(nonnull PAGestureCompletion)completion;
/**
 Schedules a predefined swipe gesture after the determined time interval.
 @discussion One time only. After any user interaction the timer will stop.
 @param startPoint The starting point of the swipe.
 @param swipeDirection PAGestureAssistantSwipeDirectonUp, PAGestureAssistantSwipeDirectonDown, PAGestureAssistantSwipeDirectonLeft, PAGestureAssistantSwipeDirectonRight.
 @param text The text that will appear alongside the animation.
 @param afterIdleInterval The amount of time without any user interaction after which the animation is triggered.
 @param completion A block that runs after the animation has been dismissed
 @see -showGestureAssistantForSwipeDirection:attributedText:afterIdleInterval:completion:
 */
- (void)showGestureAssistantForSwipeDirection:(PAGestureAssistantSwipeDirectons)swipeDirection text:(nullable NSString *)text afterIdleInterval:(NSTimeInterval)delay completion:(nonnull PAGestureCompletion)completion;
/**
 Schedules a tap gesture at the view's center after the determined time interval.
 @discussion Will always show at the view center, even if the view's position changes (e.g. Screen rotation). After any user interaction the timer will stop.
 @param targetView The target view where you want the animation to appear.
 @param text The text that will appear alongside the animation.
 @param afterIdleInterval The amount of time without any user interaction after which the animation is triggered.
 @param completion A block that runs after the animation has been dismissed
 @see -showGestureAssistantForTap:view:attributedText:afterIdleInterval:completion:
 */
- (void)showGestureAssistantForTap:(PAGestureAssistantTap)tapOptions view:(nonnull UIView *)targetView text:(nullable NSString *)text afterIdleInterval:(NSTimeInterval)delay completion:(nonnull PAGestureCompletion)completion;
/**
 Schedules a tap gesture at a fixed point after the determined time interval.
 @discussion One time only. After any user interaction the timer will stop.
 @param point The coordinate where you want the animation to appear.
 @param text The text that will appear alongside the animation.
 @param afterIdleInterval The amount of time without any user interaction after which the animation is triggered.
 @param completion A block that runs after the animation has been dismissed
 @see -showGestureAssistantForTap:point:attributedText:afterIdleInterval:completion:
 */
- (void)showGestureAssistantForTap:(PAGestureAssistantTap)tapOptions point:(CGPoint)tapPoint text:(nullable NSString *)text afterIdleInterval:(NSTimeInterval)delay completion:(nonnull PAGestureCompletion)completion;

#pragma mark - Repeatables -

#pragma mark Attributed Text
/**
 Schedules a custom swipe gesture after the determined time interval.
 @discussion After any user interaction the timer will restart. If you don't want this behavior use the same method with completion.
 @param startPoint The starting point of the swipe.
 @param endPoint The ending point of the swipe.
 @param attributedText The styled text that will appear alongside the animation.
 @param afterIdleInterval The amount of time without any user interaction after which the animation is triggered.
 @param completion A block that runs after the animation has been dismissed
 @see -showGestureAssistantForSwipeWithStartPoint:endPointattributedTextafterIdleInterval:completion:
 */
- (void)showGestureAssistantForSwipeWithStartPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint attributedText:(nullable NSAttributedString *)attributedText afterIdleInterval:(NSTimeInterval)delay;
/**
 Schedules a predefined swipe gesture after the determined time interval.
 @discussion After any user interaction the timer will restart. If you don't want this behavior use the same method with completion.
 @param startPoint The starting point of the swipe.
 @param swipeDirection PAGestureAssistantSwipeDirectonUp, PAGestureAssistantSwipeDirectonDown, PAGestureAssistantSwipeDirectonLeft, PAGestureAssistantSwipeDirectonRight.
 @param attributedText The styled text that will appear alongside the animation.
 @param afterIdleInterval The amount of time without any user interaction after which the animation is triggered.
 @see -showGestureAssistantForSwipeDirection:attributedText:afterIdleInterval:completion:
 */
- (void)showGestureAssistantForSwipeDirection:(PAGestureAssistantSwipeDirectons)swipeDirection attributedText:(nullable NSAttributedString *)attributedText afterIdleInterval:(NSTimeInterval)delay;

#pragma mark - Completion Block -

/**
 Schedules a custom swipe gesture after the determined time interval.
 @discussion One time only. After any user interaction the timer will stop.
 @param startPoint The starting point of the swipe.
 @param endPoint The ending point of the swipe.
 @param attributedText The styled text that will appear alongside the animation.
 @param afterIdleInterval The amount of time without any user interaction after which the animation is triggered.
 @param completion A block that runs after the animation has been dismissed
 */
- (void)showGestureAssistantForSwipeWithStartPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint attributedText:(nullable NSAttributedString *)attributedText afterIdleInterval:(NSTimeInterval)delay completion:(nullable PAGestureCompletion)completion;
/**
 Schedules a predefined swipe gesture after the determined time interval.
 @discussion One time only. After any user interaction the timer will stop.
 @param startPoint The starting point of the swipe.
 @param swipeDirection PAGestureAssistantSwipeDirectonUp, PAGestureAssistantSwipeDirectonDown, PAGestureAssistantSwipeDirectonLeft, PAGestureAssistantSwipeDirectonRight.
 @param attributedText The styled text that will appear alongside the animation.
 @param afterIdleInterval The amount of time without any user interaction after which the animation is triggered.
 @param completion A block that runs after the animation has been dismissed
 @see -showGestureAssistantForSwipeDirection:attributedText:afterIdleInterval:completion:
 */
- (void)showGestureAssistantForSwipeDirection:(PAGestureAssistantSwipeDirectons)swipeDirection attributedText:(nullable NSAttributedString *)attributedText afterIdleInterval:(NSTimeInterval)delay completion:(nullable PAGestureCompletion)completion;
/**
 Schedules a tap gesture at the view's center after the determined time interval.
 @discussion Will always show at the view center, even if the view's position changes (eg. Screen rotation). After any user interaction the timer will stop.
 @param targetView The target view where you want the animation to appear.
 @param attributedText The styled text that will appear alongside the animation.
 @param afterIdleInterval The amount of time without any user interaction after which the animation is triggered.
 @param completion A block that runs after the animation has been dismissed
 @see -showGestureAssistantForTap:view:attributedText:afterIdleInterval:completion:
 */
- (void)showGestureAssistantForTap:(PAGestureAssistantTap)tapOptions view:(nonnull UIView *)targetView attributedText:(nullable NSAttributedString *)attributedText afterIdleInterval:(NSTimeInterval)delay completion:(nullable PAGestureCompletion)completion;
/**
 Schedules a tap gesture at a fixed point after the determined time interval.
 @discussion One time only. After any user interaction the timer will stop.
 @param point The coordinate where you want the animation to appear.
 @param attributedText The styled text that will appear alongside the animation.
 @param afterIdleInterval The amount of time without any user interaction after which the animation is triggered.
 @param completion A block that runs after the animation has been dismissed
 @see -showGestureAssistantForTap:point:attributedText:afterIdleInterval:completion:
 */
- (void)showGestureAssistantForTap:(PAGestureAssistantTap)tapOptions point:(CGPoint)tapPoint attributedText:(nullable NSAttributedString *)attributedText afterIdleInterval:(NSTimeInterval)delay completion:(nullable PAGestureCompletion)completion;



@end
