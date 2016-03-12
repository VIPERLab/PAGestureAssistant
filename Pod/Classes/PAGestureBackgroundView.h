//
//  PAGestureBackgroundView.h
//  PAGestureAssistant
//
//  Created by Pedro Almeida on 1/30/16.
//  Copyright © 2016 Pedro Almeida. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PAGestureDelegate.h"

@interface PAGestureBackgroundView : UIView

@property (weak, nonatomic, readonly) id<PAGestureDelegate> delegate;

- (instancetype)initWithDelegate:(id<PAGestureDelegate>)delegate;

@end
