//
//  PAGestureView.h
//  PAGestureAssistant
//
//  Created by Pedro Almeida on 1/30/16.
//  Copyright © 2016 Pedro Almeida. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kPAGestureAssistantDefaultViewSize           44.f
#define kPAGestureAssistantDefaultViewPulseDuration  0.4f
#define kPAGestureAssistantDefaultGestureAlphaDn     0.6f
#define kPAGestureAssistantDefaultGestureAlphaUp     0.8f

@interface PAGestureView : UIImageView

@property (assign, nonatomic, readonly) BOOL isPulsing;
- (void)pulse:(BOOL)pulse;

@end
