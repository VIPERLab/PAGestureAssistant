//
//  PAGestureDelegate.h
//  PAGestureAssistant
//
//  Created by Pedro Almeida on 1/30/16.
//  Copyright © 2016 Pedro Almeida. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol PAGestureDelegate <NSObject>

@required
- (void)pa_userHasTouchedView:(UIView *)view event:(UIEvent *)event;
- (BOOL)pa_allowContentTouches;

@end